# Premium billing: Google Play test plan

**Status: NOT release-ready.** The entitlement logic is covered by automated
tests against a fake store (`test/purchase_service_test.dart`,
`test/parent_dashboard_test.dart`), but nothing has run against Google Play
or RevenueCat. Every box below must be ticked on real devices first.

## How it works

| Piece | File |
|---|---|
| RevenueCat SDK adapter (only code that touches the SDK) | `lib/core/purchases/store_client.dart` |
| Entitlement rules, purchase/restore/sync | `lib/core/purchases/purchase_service.dart` |
| Live state, launch + resume sync | `lib/core/purchases/subscription_provider.dart` |

- Entitlement id: **`premium`**. Product: an annual subscription attached to the
  RevenueCat *current* offering's **annual** package.
- API key at build time: `--dart-define=REVENUECAT_ANDROID_KEY=goog_…`.
  Without it the app runs with purchases unavailable.
- Sync: on launch (in the background, never blocking start), on every return to
  the foreground, and whenever RevenueCat pushes a customer-info update.
- Store says inactive → locked at once. Store unreachable → cached entitlement,
  valid until 3 days after its expiry date.
- Purchases are only offered in the PIN-protected parent dashboard.

## One-time setup

1. Play Console: create the app, upload a signed AAB to **Internal testing**,
   add license testers (Settings → License testing) and internal testers.
2. Create the annual subscription product + base plan in Play Console.
3. RevenueCat: Android app with the Play service-account credentials;
   product → entitlement `premium`; offering marked *current* with an
   **annual** package containing the product.
4. Install from the internal-testing opt-in link (not sideloaded) on a device
   signed in with a license-tester account.

License testers get accelerated renewals (annual renews about every 30 min,
up to 6 times) and test payment methods ("always approves", "always
declines", "slow card").

## Test cases (each on Android 12 and 16 at least)

- [ ] **Purchase:** free → Upgrade → approve → "Premium unlocked", Music Lab opens, ml_ep01 plays
- [ ] **Cancel sheet:** back out of the Play sheet → "Purchase cancelled", still free
- [ ] **Declined card:** → "Purchase failed", still free
- [ ] **Slow card / pending:** app stays usable; unlocks once approved
- [ ] **Restore:** clear app data or reinstall → Restore → "Premium restored"
- [ ] **Restore, nothing bought:** other tester account → "No purchases found"
- [ ] **Renewal:** wait for accelerated renewal → stays Premium, new expiry shown
- [ ] **Cancel in Play** (Subscriptions → Cancel) → return to app → "Premium (cancelled)", still unlocked until expiry → after expiry + resume → locked
- [ ] **Refund/revoke** from Play Console order management → resume → locked
- [ ] **Billing grace / account hold:** "always declines" at renewal → "payment problem" shown during grace → locked after hold
- [ ] **Offline:** airplane mode with Premium → still unlocked; past expiry + 3 days offline → locked
- [ ] **Offline launch, never bought:** free, no crash, Upgrade says unavailable
- [ ] **Build without key:** dashboard says purchases not available; no crash
- [ ] **Child path:** tapping a locked world never shows a Play sheet; only "ask a grown-up"
- [ ] **RevenueCat dashboard:** each event above appears for the tester's customer

Only when all pass may the purchase flow be called release-ready.
