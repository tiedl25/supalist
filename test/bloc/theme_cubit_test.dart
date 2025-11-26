import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supalist/bloc/theme_bloc.dart';

void main() {
  // Ensure Flutter bindings are initialized for SystemChrome calls.
  TestWidgetsFlutterBinding.ensureInitialized();

  test('ThemeCubit initial state and toggles', () async {
    SharedPreferences.setMockInitialValues({'systemTheme': true, 'darkMode': false});
    final prefs = await SharedPreferences.getInstance();

    final cubit = ThemeCubit(prefs);
    // initial based on systemTheme true
    expect(cubit.state, ThemeMode.system);

    // Turn off system theme -> should read darkMode (false) and become light
    await cubit.toggleSystemTheme(false, Brightness.light);
    expect(prefs.getBool('systemTheme'), false);
    expect(cubit.state, ThemeMode.light);

    // Toggle dark mode on
    await cubit.toggleDarkMode(true, Brightness.dark);
    expect(prefs.getBool('darkMode'), true);
    expect(cubit.state, ThemeMode.dark);
  });
}
