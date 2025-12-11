abstract class SettingsViewState {}

abstract class SettingsViewListener extends SettingsViewState {}

class SettingsViewShowPrivacyPolicy extends SettingsViewListener {}

class SettingsViewShowLogoutDialog extends SettingsViewListener {}

class SettingsViewLogin extends SettingsViewListener {}

class SettingsViewLogout extends SettingsViewListener {}

class SettingsViewLoading extends SettingsViewState {}

class SettingsViewLoaded extends SettingsViewState {
  final bool systemTheme;
  final bool darkMode;
  final String version;

  SettingsViewLoaded({required this.systemTheme, required this.darkMode, required this.version});

  SettingsViewLoaded copy({bool? systemTheme, bool? darkMode, String? version}) {
    return SettingsViewLoaded(systemTheme: systemTheme ?? this.systemTheme, darkMode: darkMode ?? this.darkMode, version: version ?? this.version);
  }

  factory SettingsViewLoaded.from(dynamic state) {
    return SettingsViewLoaded(
      systemTheme: state.systemTheme,
      darkMode: state.darkMode,
      version: state.version
    );
  }
}

class SettingsViewLogoutDialog extends SettingsViewLoaded {
  SettingsViewLogoutDialog({required super.version, required super.systemTheme, required super.darkMode});

  factory SettingsViewLogoutDialog.from(SettingsViewLoaded state) {
    return SettingsViewLogoutDialog(
      version: state.version,
      systemTheme: state.systemTheme,
      darkMode: state.darkMode
    );
  }
}

class SettingsViewPrivacyPolicy extends SettingsViewLoaded {
  SettingsViewPrivacyPolicy({required super.version, required super.systemTheme, required super.darkMode});

  factory SettingsViewPrivacyPolicy.from(SettingsViewLoaded state) {
    return SettingsViewPrivacyPolicy(
      version: state.version,
      systemTheme: state.systemTheme,
      darkMode: state.darkMode
    );
  }
}