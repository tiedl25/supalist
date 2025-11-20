import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supalist/bloc/settingsview_bloc.dart';
import 'package:supalist/bloc/settingsview_states.dart';

class SettingsView extends StatelessWidget {
  late final SettingsViewCubit cubit;

  @override
  Widget build(BuildContext context) {
    cubit = context.read<SettingsViewCubit>();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Container(
        margin: const EdgeInsets.all(10),
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border.all(
              style: BorderStyle.none,
            ),
            borderRadius: BorderRadius.circular(20)),
        child: BlocBuilder<SettingsViewCubit, SettingsViewState>(
          builder: (context, state) {
            if (state is SettingsViewLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            state as SettingsViewLoaded;

            return SingleChildScrollView(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text("Use system theme"),
                    value: state.systemTheme,
                    onChanged: (bool value) async => cubit.toggleSystemTheme(value, MediaQuery.of(context).platformBrightness)),
                  const Divider(
                    thickness: 0.2,
                    indent: 15,
                    endIndent: 15,
                  ),
                  SwitchListTile(
                      title: const Text("Dark Mode"),
                      value: state.darkMode,
                      tileColor: state.systemTheme
                        ? Theme.of(context).colorScheme.surface
                        : null,
                      onChanged: state.systemTheme
                        ? null
                        : (bool value) async => cubit.toggleDarkMode(value, MediaQuery.of(context).platformBrightness)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
