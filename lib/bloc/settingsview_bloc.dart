import 'dart:ui';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:bloc/bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supalist/bloc/settingsview_states.dart';
import 'package:supalist/bloc/theme_bloc.dart';
import 'package:supalist/data/database.dart';

class SettingsViewCubit extends Cubit<SettingsViewState> {
  final ThemeCubit themeCubit;
  final SharedPreferences prefs;

  SettingsViewCubit(this.themeCubit) : prefs = themeCubit.prefs, super(SettingsViewLoading()) {
    loadSettings();
  }

  Future<void> loadSettings() async {
    final isSystemTheme = prefs.getBool('systemTheme') ?? true;
    final isDarkMode = prefs.getBool('darkMode') ?? false;

    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    final version = packageInfo.version;

    emit(SettingsViewLoaded(systemTheme: isSystemTheme, darkMode: isDarkMode, version: version));
  }

  Future<void> toggleSystemTheme(bool value, Brightness platformBrightness) async {
    final state = (this.state as SettingsViewLoaded).copy(
      systemTheme: value,
    );
    
    await prefs.setBool('systemTheme', value);

    themeCubit.toggleSystemTheme(value, platformBrightness);
    emit(state);
  }

  Future<void> toggleDarkMode(bool value, Brightness platformBrightness) async {
    final state = (this.state as SettingsViewLoaded).copy(
      darkMode: value,
    );
    
    await prefs.setBool('darkMode', value);

    themeCubit.toggleDarkMode(value, platformBrightness);
    emit(state);
  }

  Future<void> login() async {
    await prefs.setBool('offline', false);

    emit(SettingsViewLogin());
  }

  void showLogoutDialog() {
    final newState = SettingsViewLogoutDialog.from(state as SettingsViewLoaded);

    emit(SettingsViewShowLogoutDialog());

    emit(newState);
  }

  Future<void> confirmLogout() async {
    await prefs.setBool('offline', false);
    await DatabaseHelper.instance.logout();

    emit(SettingsViewLogout());
  }

  void dismissLogout() {
    final newState = SettingsViewLoaded.from(state as SettingsViewLogoutDialog);

    emit(newState);
  }
}