import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../core/storage/models/child_profile.dart';
import '../curriculum/episode_catalog.dart';
import '../curriculum/episode_controller.dart';
import 'strings.dart';

/// The child's language ('en' | 'hi' | 'te'), saved in their ChildProfile.
/// Drives episode audio, speech recognition locale and child-facing text.
class LanguageNotifier extends Notifier<String> {
  @override
  String build() {
    final lang = ref.read(hiveStorageServiceProvider).getProfile()?.language;
    return kLanguages.contains(lang) ? lang! : 'en';
  }

  Future<void> set(String lang) async {
    if (!kLanguages.contains(lang)) {
      throw ArgumentError.value(lang, 'lang', 'unsupported language');
    }
    final storage = ref.read(hiveStorageServiceProvider);
    final profile = storage.getProfile() ??
        ChildProfile(
          id: const Uuid().v4(),
          nickname: 'Explorer',
          createdAt: DateTime.now(),
        );
    await storage.saveProfile(profile.copyWith(language: lang));
    state = lang;
  }
}

final languageProvider =
    NotifierProvider<LanguageNotifier, String>(LanguageNotifier.new);

final stringsProvider =
    Provider<AppStrings>((ref) => AppStrings.of(ref.watch(languageProvider)));
