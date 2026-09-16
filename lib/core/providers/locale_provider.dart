import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../localization/app_localizations.dart';
import '../storage/secure_storage_service.dart';

class LocaleNotifier extends StateNotifier<String> {
  final SecureStorageService _storage;

  LocaleNotifier(this._storage) : super('en') {
    _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    final lang = await _storage.getSelectedLanguage();
    // Only apply if it's a supported language, otherwise keep default 'en'
    if (lang == 'hi' || lang == 'en') {
      state = lang;
    }
  }

  Future<void> setLanguage(String langCode) async {
    if (state == langCode) return;
    state = langCode;
    await _storage.setSelectedLanguage(langCode);
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, String>((ref) {
  final storage = SecureStorageService();
  return LocaleNotifier(storage);
});

final appLocalizationsProvider = Provider<AppLocalizations>((ref) {
  final langCode = ref.watch(localeProvider);
  return AppLocalizations(langCode);
});
