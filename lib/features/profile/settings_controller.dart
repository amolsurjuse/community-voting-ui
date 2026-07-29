import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@immutable
class SettingsState {
  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.seenOnboarding = false,
    this.notificationsEnabled = true,
    this.language = 'English',
  });

  final ThemeMode themeMode;
  final bool seenOnboarding;
  final bool notificationsEnabled;
  final String language;

  SettingsState copyWith({
    ThemeMode? themeMode,
    bool? seenOnboarding,
    bool? notificationsEnabled,
    String? language,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      seenOnboarding: seenOnboarding ?? this.seenOnboarding,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      language: language ?? this.language,
    );
  }
}

class SettingsController extends Notifier<SettingsState> {
  @override
  SettingsState build() => const SettingsState();

  void setThemeMode(ThemeMode mode) =>
      state = state.copyWith(themeMode: mode);

  void completeOnboarding() => state = state.copyWith(seenOnboarding: true);

  void setNotifications(bool enabled) =>
      state = state.copyWith(notificationsEnabled: enabled);

  void setLanguage(String language) =>
      state = state.copyWith(language: language);
}

final settingsControllerProvider =
    NotifierProvider<SettingsController, SettingsState>(SettingsController.new);
