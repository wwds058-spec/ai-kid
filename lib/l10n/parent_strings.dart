/// Parent-facing text (PIN gate, grown-up check, dashboard).
///
/// English only for now. To localise: add `hi`/`te` instances (every field is
/// required, so a missing string is a compile error) and list them in [all];
/// [parentStringsProvider] then follows the chosen language with no screen
/// changes. Kept separate from the child's AppStrings so parent wording can
/// be reviewed and shipped on its own schedule.
library;

class ParentStrings {
  // Dashboard
  final String dashboardTitle;
  final String progress;
  final String episodesCompleted;
  final String badgesEarned;
  final String safetyEvents;
  final String subscription;
  final String status;
  final String statusFree;
  final String statusPremium;
  final String statusGrace;
  final String statusCancelled;
  final String statusBillingIssue;
  final String Function(String date) expires;
  final String Function(String date) premiumUntil;
  final String storeNotConfigured;
  final String settings;
  final String language;
  final String voice;
  final String voiceHelp;
  final String dailyLimit;
  final String Function(int minutes) minutes;
  final String aiInteraction;
  final String aiInteractionHelp;
  final String upgrade;
  final String renew;
  final String restore;
  final String purchaseUnlocked;
  final String purchaseCancelled;
  final String purchaseNotEntitled;
  final String purchaseUnavailable;
  final String purchaseFailed;
  final String restoreFound;
  final String restoreNothing;
  final String restoreUnavailable;
  final String privacyPolicy;
  // PIN gate
  final String parentArea;
  final String createPin;
  final String confirmPin;
  final String enterPin;
  final String pinsDidNotMatch;
  final String Function(int left) wrongPin;
  final String tooManyAttempts;
  final String Function(int minutes) tryAgainIn;
  // Grown-up check (before creating a PIN)
  final String grownUpCheckTitle;
  final String grownUpCheckPrompt;
  final String grownUpCheckWrong;
  final List<String> digitWords;

  const ParentStrings({
    required this.dashboardTitle,
    required this.progress,
    required this.episodesCompleted,
    required this.badgesEarned,
    required this.safetyEvents,
    required this.subscription,
    required this.status,
    required this.statusFree,
    required this.statusPremium,
    required this.statusGrace,
    required this.statusCancelled,
    required this.statusBillingIssue,
    required this.expires,
    required this.premiumUntil,
    required this.storeNotConfigured,
    required this.settings,
    required this.language,
    required this.voice,
    required this.voiceHelp,
    required this.dailyLimit,
    required this.minutes,
    required this.aiInteraction,
    required this.aiInteractionHelp,
    required this.upgrade,
    required this.renew,
    required this.restore,
    required this.purchaseUnlocked,
    required this.purchaseCancelled,
    required this.purchaseNotEntitled,
    required this.purchaseUnavailable,
    required this.purchaseFailed,
    required this.restoreFound,
    required this.restoreNothing,
    required this.restoreUnavailable,
    required this.privacyPolicy,
    required this.parentArea,
    required this.createPin,
    required this.confirmPin,
    required this.enterPin,
    required this.pinsDidNotMatch,
    required this.wrongPin,
    required this.tooManyAttempts,
    required this.tryAgainIn,
    required this.grownUpCheckTitle,
    required this.grownUpCheckPrompt,
    required this.grownUpCheckWrong,
    required this.digitWords,
  });

  static const all = <String, ParentStrings>{'en': en};

  /// Strings for [lang]; English until a translation is added to [all].
  static ParentStrings of(String lang) => all[lang] ?? en;

  static const en = ParentStrings(
    dashboardTitle: 'Parent Dashboard',
    progress: 'Progress',
    episodesCompleted: 'Episodes completed',
    badgesEarned: 'Total badges earned',
    safetyEvents: 'Safety prompts shown',
    subscription: 'Subscription',
    status: 'Status',
    statusFree: '🔓 Free',
    statusPremium: '✅ Premium',
    statusGrace: '⚠️ Premium (offline, not yet re-checked)',
    statusCancelled: '⏳ Premium (cancelled)',
    statusBillingIssue: '⚠️ Premium (payment problem)',
    expires: _expires,
    premiumUntil: _premiumUntil,
    storeNotConfigured: 'Purchases are not available in this build.',
    settings: 'Settings',
    language: 'Language',
    voice: 'Voice answers',
    voiceHelp: 'When off, the microphone is never used and Aiko continues '
        'without waiting for an answer.',
    dailyLimit: 'Daily play limit',
    minutes: _minutes,
    aiInteraction: 'AI interaction',
    aiInteractionHelp: 'Allow interactive AI features.',
    upgrade: 'Upgrade to Premium',
    renew: 'Renew Premium',
    restore: 'Restore Purchases',
    purchaseUnlocked: '✅ Premium unlocked!',
    purchaseCancelled: 'Purchase cancelled.',
    purchaseNotEntitled:
        'The store accepted the payment but Premium did not activate. '
        'Try "Restore Purchases".',
    purchaseUnavailable:
        "Purchases aren't available right now. Check your connection.",
    purchaseFailed: 'Purchase failed. Please try again.',
    restoreFound: '✅ Premium restored!',
    restoreNothing: 'No purchases found.',
    restoreUnavailable: "Couldn't reach Google Play. Check your connection.",
    privacyPolicy: 'Privacy policy',
    parentArea: 'Parent Area',
    createPin: 'Create a 4-digit PIN',
    confirmPin: 'Confirm your PIN',
    enterPin: 'Enter parent PIN',
    pinsDidNotMatch: 'PINs did not match. Try again.',
    wrongPin: _wrongPin,
    tooManyAttempts: 'Too many wrong attempts.',
    tryAgainIn: _tryAgainIn,
    grownUpCheckTitle: 'Grown-ups only',
    grownUpCheckPrompt: 'Enter these numbers using the keypad:',
    grownUpCheckWrong: 'Not quite. Here are new numbers.',
    digitWords: [
      'zero', 'one', 'two', 'three', 'four',
      'five', 'six', 'seven', 'eight', 'nine',
    ],
  );
}

String _expires(String d) => 'Renews or expires on $d';
String _premiumUntil(String d) => 'Premium until $d';
String _minutes(int m) => '$m minutes';
String _wrongPin(int n) => 'Wrong PIN. $n attempt${n == 1 ? '' : 's'} left.';
String _tryAgainIn(int m) => 'Try again in $m minute${m == 1 ? '' : 's'}.';
