/// Child-facing UI text in every supported language.
///
/// Each language is a full [AppStrings] with every field required, so a
/// missing translation is a compile error. Hindi and Telugu are DRAFT
/// translations: have a native speaker review them before release.
/// Parent-facing screens (PIN gate, dashboard) are English only for now.
library;

class BadgeText {
  final String name;
  final String description;
  const BadgeText(this.name, this.description);
}

class AppStrings {
  final String greeting;
  final String tagline;
  final String letsGo;
  final String parentSettings;
  final String chooseWorld;
  final Map<String, String> worldNames;
  final String premium;
  final String comingSoon;
  final String worldLocked;
  final String ok;
  final String forGrownUps;
  final String episodeLocked;
  final String backToWorlds;
  final String nextAdventure;
  final String nextNeedsPremium;
  final String tapToContinue;
  final String saySomething;
  final String greatJob;
  final String Function(int n) earnedBadges;
  final Map<String, BadgeText> badges;
  final String loadError;

  const AppStrings({
    required this.greeting,
    required this.tagline,
    required this.letsGo,
    required this.parentSettings,
    required this.chooseWorld,
    required this.worldNames,
    required this.premium,
    required this.comingSoon,
    required this.worldLocked,
    required this.ok,
    required this.forGrownUps,
    required this.episodeLocked,
    required this.backToWorlds,
    required this.nextAdventure,
    required this.nextNeedsPremium,
    required this.tapToContinue,
    required this.saySomething,
    required this.greatJob,
    required this.earnedBadges,
    required this.badges,
    required this.loadError,
  });

  /// Strings for [lang], falling back to English for unknown codes.
  static AppStrings of(String lang) => all[lang] ?? en;

  static const all = <String, AppStrings>{'en': en, 'hi': hi, 'te': te};

  /// Name shown on the language picker, written in its own script.
  static const nativeNames = <String, String>{
    'en': 'English',
    'hi': 'हिन्दी',
    'te': 'తెలుగు',
  };

  static const en = AppStrings(
    greeting: "Hi! I'm Aiko 👋",
    tagline: "I'll teach you all about AI — let's explore together!",
    letsGo: "Let's Go! 🚀",
    parentSettings: 'Parent / Settings',
    chooseWorld: 'Choose a World',
    worldNames: {
      'pattern_forest': 'Pattern Forest',
      'music_lab': 'Music Lab',
      'gadget_city': 'Gadget City',
    },
    premium: '🔒 Premium',
    comingSoon: '🌱 Coming soon',
    worldLocked: 'This world is part of Premium. Ask a grown-up to unlock it!',
    ok: 'OK',
    forGrownUps: "I'm a grown-up",
    episodeLocked: 'This adventure needs Premium.\nAsk a grown-up!',
    backToWorlds: 'Back to Worlds 🗺️',
    nextAdventure: 'Next Adventure ▶️',
    nextNeedsPremium: '🔒 The next adventure needs Premium',
    tapToContinue: 'Tap anywhere to continue →',
    saySomething: '🎤 Say something…',
    greatJob: 'Great job!',
    earnedBadges: _enBadges,
    badges: {
      'pattern_spotter': BadgeText('Pattern Spotter', 'You found the pattern!'),
      'ai_friend': BadgeText('AI Friend', 'You worked with Aiko!'),
      'data_collector': BadgeText('Data Collector', 'You collected data!'),
      'beat_finder': BadgeText('Beat Finder', 'You found the beat!'),
    },
    loadError: 'Oops! Something went wrong.',
  );

  static const hi = AppStrings(
    greeting: 'नमस्ते! मैं आइको हूँ 👋',
    tagline: 'मैं तुम्हें AI के बारे में सब कुछ सिखाऊँगी — चलो साथ में खोज करें!',
    letsGo: 'चलो चलें! 🚀',
    parentSettings: 'माता-पिता / सेटिंग्स',
    chooseWorld: 'एक दुनिया चुनो',
    worldNames: {
      'pattern_forest': 'पैटर्न वन',
      'music_lab': 'संगीत लैब',
      'gadget_city': 'गैजेट नगर',
    },
    premium: '🔒 प्रीमियम',
    comingSoon: '🌱 जल्द आ रहा है',
    worldLocked: 'यह दुनिया प्रीमियम का हिस्सा है। इसे खोलने के लिए किसी बड़े से पूछो!',
    ok: 'ठीक है',
    forGrownUps: 'बड़ों के लिए',
    episodeLocked: 'इस रोमांच के लिए प्रीमियम चाहिए।\nकिसी बड़े से पूछो!',
    backToWorlds: 'दुनियाओं पर वापस 🗺️',
    nextAdventure: 'अगला रोमांच ▶️',
    nextNeedsPremium: '🔒 अगले रोमांच के लिए प्रीमियम चाहिए',
    tapToContinue: 'आगे बढ़ने के लिए कहीं भी छुओ →',
    saySomething: '🎤 कुछ बोलो…',
    greatJob: 'शाबाश!',
    earnedBadges: _hiBadges,
    badges: {
      'pattern_spotter': BadgeText('पैटर्न खोजी', 'तुमने पैटर्न ढूँढ लिया!'),
      'ai_friend': BadgeText('AI दोस्त', 'तुमने आइको के साथ काम किया!'),
      'data_collector': BadgeText('डेटा संग्राहक', 'तुमने डेटा इकट्ठा किया!'),
      'beat_finder': BadgeText('ताल खोजी', 'तुमने ताल ढूँढ ली!'),
    },
    loadError: 'उफ़! कुछ गड़बड़ हो गई।',
  );

  static const te = AppStrings(
    greeting: 'నమస్తే! నేను ఐకోని 👋',
    tagline: 'నేను నీకు AI గురించి అన్నీ నేర్పిస్తాను — రా, కలిసి అన్వేషిద్దాం!',
    letsGo: 'వెళ్దాం! 🚀',
    parentSettings: 'తల్లిదండ్రులు / సెట్టింగ్‌లు',
    chooseWorld: 'ఒక ప్రపంచాన్ని ఎంచుకో',
    worldNames: {
      'pattern_forest': 'ప్యాటర్న్ అడవి',
      'music_lab': 'సంగీత ల్యాబ్',
      'gadget_city': 'గాడ్జెట్ నగరం',
    },
    premium: '🔒 ప్రీమియం',
    comingSoon: '🌱 త్వరలో వస్తోంది',
    worldLocked: 'ఈ ప్రపంచం ప్రీమియంలో భాగం. దీన్ని తెరవడానికి పెద్దవాళ్లను అడుగు!',
    ok: 'సరే',
    forGrownUps: 'పెద్దవాళ్ల కోసం',
    episodeLocked: 'ఈ సాహసానికి ప్రీమియం కావాలి.\nపెద్దవాళ్లను అడుగు!',
    backToWorlds: 'ప్రపంచాలకు తిరిగి 🗺️',
    nextAdventure: 'తదుపరి సాహసం ▶️',
    nextNeedsPremium: '🔒 తదుపరి సాహసానికి ప్రీమియం కావాలి',
    tapToContinue: 'ముందుకు వెళ్లడానికి ఎక్కడైనా తాకు →',
    saySomething: '🎤 ఏదైనా చెప్పు…',
    greatJob: 'శభాష్!',
    earnedBadges: _teBadges,
    badges: {
      'pattern_spotter':
          BadgeText('ప్యాటర్న్ స్పాటర్', 'నువ్వు ప్యాటర్న్‌ను కనిపెట్టావు!'),
      'ai_friend': BadgeText('AI స్నేహితుడు', 'నువ్వు ఐకోతో కలిసి పనిచేశావు!'),
      'data_collector': BadgeText('డేటా కలెక్టర్', 'నువ్వు డేటాను సేకరించావు!'),
      'beat_finder': BadgeText('బీట్ ఫైండర్', 'నువ్వు తాళం కనిపెట్టావు!'),
    },
    loadError: 'అయ్యో! ఏదో తప్పు జరిగింది.',
  );
}

String _enBadges(int n) => 'You earned $n badge${n == 1 ? '' : 's'}!';
String _hiBadges(int n) => n == 1 ? 'तुमने 1 बैज जीता!' : 'तुमने $n बैज जीते!';
String _teBadges(int n) =>
    n == 1 ? 'నువ్వు 1 బ్యాడ్జ్ గెలిచావు!' : 'నువ్వు $n బ్యాడ్జ్‌లు గెలిచావు!';
