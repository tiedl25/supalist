abstract class SettingsViewState {}

class SettingsViewLoading extends SettingsViewState {}

class SettingsViewLoaded extends SettingsViewState {
  final bool systemTheme;
  final bool darkMode;

  SettingsViewLoaded({required this.systemTheme, required this.darkMode});

  SettingsViewLoaded copy({bool? systemTheme, bool? darkMode}) {
    return SettingsViewLoaded(systemTheme: systemTheme ?? this.systemTheme, darkMode: darkMode ?? this.darkMode);
  }
}