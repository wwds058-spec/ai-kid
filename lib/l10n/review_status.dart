/// Native-speaker review status of every non-English text the child meets:
/// UI strings (strings.dart), audio scripts (docs/audio_script_{lang}.csv),
/// episode titles, speech keywords (intent_router.dart) and safety phrases
/// (safety_layer.dart). See docs/TRANSLATION_REVIEW.md.
///
/// `RELEASE=1 flutter test` fails while any language is unreviewed.
/// Set a language to reviewed only after a native speaker (and, for safety
/// phrases and `safety_tell_grownup`, a child-safety reviewer) signs off.
library;

class TranslationReview {
  final bool reviewed;
  final String? reviewer;
  final String? date;
  const TranslationReview({this.reviewed = false, this.reviewer, this.date});
}

const kTranslationReview = <String, TranslationReview>{
  'hi': TranslationReview(),
  'te': TranslationReview(),
};
