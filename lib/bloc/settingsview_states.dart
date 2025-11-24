abstract class SettingsViewState {}

class SettingsViewLoading extends SettingsViewState {}

class SettingsViewLoaded extends SettingsViewState {
  final bool systemTheme;
  final bool darkMode;
  final String version;

  SettingsViewLoaded({required this.systemTheme, required this.darkMode, required this.version});

  SettingsViewLoaded copy({bool? systemTheme, bool? darkMode, String? version}) {
    return SettingsViewLoaded(systemTheme: systemTheme ?? this.systemTheme, darkMode: darkMode ?? this.darkMode, version: version ?? this.version);
  }
}