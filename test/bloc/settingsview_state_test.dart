import 'package:flutter_test/flutter_test.dart';
import 'package:supalist/bloc/settingsview_states.dart';

void main() {
  test('SettingsViewLoaded copy preserves values', () {
    final s = SettingsViewLoaded(systemTheme: true, darkMode: false, version: '1.2.3');
    final s2 = s.copy(systemTheme: false, darkMode: true, version: '2.0.0');

    expect(s2.systemTheme, false);
    expect(s2.darkMode, true);
    expect(s2.version, '2.0.0');
  });
}
