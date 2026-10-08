#!/usr/bin/env bash
# Create the Google Play UPLOAD key for AI Explorer (Yasvar Labs) — run on YOUR machine,
# never on a shared/cloud machine. See docs/release/SIGNING.md.
#
#   tools/create_upload_key.sh [output-dir]      (default: ~/ai-explorer-signing)
#
# Creates:
#   <dir>/upload-keystore.jks       the keystore (back it up!)
#   android/key.properties          local signing config (gitignored)
# Prints the values to store as GitHub Actions secrets and the certificate
# SHA-256 fingerprint (for Play Console / RevenueCat, not secret).
set -euo pipefail

command -v keytool >/dev/null || { echo "keytool not found: install a JDK (17+)"; exit 1; }

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
# Absolute path without requiring it to exist (GNU realpath -m; macOS lacks -m).
abspath() { realpath -m "$1" 2>/dev/null || python3 -c 'import os,sys; print(os.path.abspath(sys.argv[1]))' "$1"; }
out_dir="$(abspath "${1:-$HOME/ai-explorer-signing}")"
keystore="$out_dir/upload-keystore.jks"
alias_name="upload"

case "$out_dir" in
  "$repo_root"*) echo "Refusing to create the keystore inside the repository ($out_dir)."; exit 1 ;;
esac
[ -e "$keystore" ] && { echo "$keystore already exists — not overwriting an upload key."; exit 1; }
[ -e "$repo_root/android/key.properties" ] && { echo "android/key.properties already exists — not overwriting."; exit 1; }

mkdir -p "$out_dir"
chmod 700 "$out_dir"

read -rsp "Choose a keystore password (min 12 chars): " store_pw; echo
[ ${#store_pw} -ge 12 ] || { echo "Password too short."; exit 1; }
read -rsp "Repeat it: " store_pw2; echo
[ "$store_pw" = "$store_pw2" ] || { echo "Passwords differ."; exit 1; }
read -rp "Organisation for the certificate [Yasvar Labs]: " owner
owner="${owner:-Yasvar Labs}"

# PKCS12 keystores use one password for store and key.
keytool -genkeypair -v \
  -keystore "$keystore" -storetype PKCS12 \
  -alias "$alias_name" -keyalg RSA -keysize 4096 -validity 10000 \
  -storepass "$store_pw" -keypass "$store_pw" \
  -dname "CN=$owner, O=$owner, C=IN" >/dev/null
chmod 600 "$keystore"

cat > "$repo_root/android/key.properties" <<PROPS
storeFile=$keystore
storePassword=$store_pw
keyAlias=$alias_name
keyPassword=$store_pw
PROPS
chmod 600 "$repo_root/android/key.properties"

fingerprint=$(keytool -list -v -keystore "$keystore" -alias "$alias_name" -storepass "$store_pw" \
  | awk -F': ' '/SHA256:/ {print $2; exit}')

cat <<MSG

Upload key created.
  Keystore:        $keystore
  Local config:    android/key.properties (gitignored)
  SHA-256 (public): $fingerprint

1) BACK UP NOW: copy $keystore and the password to a password manager.
   If lost, Play can reset the upload key, but it takes days.

2) GitHub → repo Settings → Secrets and variables → Actions → New secret:
     ANDROID_UPLOAD_KEYSTORE_BASE64   output of:  base64 -w0 "$keystore"   (macOS: base64 -i "$keystore")
     ANDROID_UPLOAD_STORE_PASSWORD    the password you chose
     ANDROID_UPLOAD_KEY_PASSWORD      the same password
     ANDROID_UPLOAD_KEY_ALIAS         $alias_name

3) Build a store bundle locally:
     REQUIRE_UPLOAD_KEY=true flutter build appbundle --release \\
       --dart-define=REVENUECAT_ANDROID_KEY=goog_xxx
MSG
