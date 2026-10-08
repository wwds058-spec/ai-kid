# Release signing

AI Explorer uses **Google Play App Signing**: Google keeps the *app signing
key* and re-signs what users download. We only hold the **upload key**, which
proves to Play that an upload came from us. If the upload key is lost or
leaked, Play Console can reset it (Setup → App signing → Request upload key
reset); the app signing key is never at risk.

**Never commit** the keystore, its password or `android/key.properties`.
`.gitignore` blocks them and `test/release_signing_test.dart` fails if one is
ever tracked.

## 1. Create the upload key (once, on your own computer)

```bash
tools/create_upload_key.sh            # default: ~/ai-explorer-signing/
```

It refuses to write inside the repository or overwrite an existing key, then:

- creates `~/ai-explorer-signing/upload-keystore.jks` (RSA 4096, 27-year validity)
- writes `android/key.properties` (gitignored) pointing at it
- prints the GitHub secrets to add and the certificate SHA-256

**Back up** the `.jks` file and its password in a password manager straight away.

## 2. Local store build

```bash
REQUIRE_UPLOAD_KEY=true flutter build appbundle --release \
  --dart-define=REVENUECAT_ANDROID_KEY=goog_xxx
# → build/app/outputs/bundle/release/app-release.aab
```

`REQUIRE_UPLOAD_KEY=true` makes Gradle fail if the key isn't configured, so a
store build can never silently fall back to debug signing. Without it (plain
`flutter run --release`) builds use debug keys and Play will reject them.

## 3. CI store build (GitHub Actions)

Repository → Settings → Secrets and variables → Actions:

| Secret | Value |
|---|---|
| `ANDROID_UPLOAD_KEYSTORE_BASE64` | `base64 -w0 upload-keystore.jks` (macOS: `base64 -i upload-keystore.jks`) |
| `ANDROID_UPLOAD_STORE_PASSWORD` | keystore password |
| `ANDROID_UPLOAD_KEY_PASSWORD` | same password (PKCS12) |
| `ANDROID_UPLOAD_KEY_ALIAS` | `upload` |
| `REVENUECAT_ANDROID_KEY` | RevenueCat public Android SDK key (`goog_…`) |

With these set, every CI run on this repo builds `ai-explorer-store-aab`,
verifies its signature and prints the upload certificate SHA-256. Secrets are
not available to pull requests from forks, so those builds skip this step.

On every run, with or without secrets, CI also:

- proves a store build **fails** without an upload key, and
- builds a bundle with a throwaway key and checks it is signed by exactly that
  key (not the debug key).

## 4. First upload to Play Console

1. Create the app under the **Yasvar Labs** developer account, package `com.yasvarlabs.aiexplorer` (permanent after the first upload).
2. Setup → App signing: accept **Play App Signing** (Google-generated app signing key).
3. Testing → Internal testing → upload the signed `.aab`. Play records the upload certificate.
4. Copy both SHA-256 fingerprints (app signing and upload) from Setup → App signing;
   add them wherever the app is identified by certificate (none today; e.g. future
   Google sign-in or app links).

## Values in Gradle

`android/app/build.gradle.kts` reads, in order: `android/key.properties`
(`storeFile`, `storePassword`, `keyAlias`, `keyPassword`), then the
environment variables `ANDROID_UPLOAD_STORE_FILE`, `ANDROID_UPLOAD_STORE_PASSWORD`,
`ANDROID_UPLOAD_KEY_ALIAS` and `ANDROID_UPLOAD_KEY_PASSWORD`. Use an absolute
`storeFile` path.
