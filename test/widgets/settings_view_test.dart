import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supalist/ui/views/settingsview.dart';
import 'package:supalist/bloc/settingsview_states.dart';
import 'package:supalist/bloc/settingsview_bloc.dart';
import 'package:supalist/bloc/theme_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeSettingsCubit extends Cubit<SettingsViewState> implements SettingsViewCubit {
  @override
  final ThemeCubit themeCubit;

  @override
  final SharedPreferences prefs;

  FakeSettingsCubit(this.themeCubit, this.prefs)
      : super(SettingsViewLoaded(systemTheme: true, darkMode: false, version: '1.0.0'));

  @override
  Future<void> loadSettings() async {}

  @override
  Future<void> toggleDarkMode(bool value, platformBrightness) async {
    final state = this.state as SettingsViewLoaded;
    await prefs.setBool('darkMode', value);
    emit(state.copy(darkMode: value));
  }

  @override
  Future<void> toggleSystemTheme(bool value, platformBrightness) async {
    final state = this.state as SettingsViewLoaded;
    await prefs.setBool('systemTheme', value);
    emit(state.copy(systemTheme: value));
  }
}

void main() {
  testWidgets('SettingsView displays version and toggles switches', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'systemTheme': true, 'darkMode': false});
    final prefs = await SharedPreferences.getInstance();
    final themeCubit = ThemeCubit(prefs);
    final cubit = FakeSettingsCubit(themeCubit, prefs);

    await tester.pumpWidget(MaterialApp(
      home: BlocProvider<SettingsViewCubit>.value(
        value: cubit,
        child: SettingsView(),
      ),
    ));

    await tester.pumpAndSettle();

    expect(find.text('1.0.0'), findsOneWidget);

    // Find the system theme switch and ensure it's present
    final systemSwitch = find.byType(SwitchListTile).first;
    expect(systemSwitch, findsOneWidget);
  });
}
