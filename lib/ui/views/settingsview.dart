import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supalist/bloc/settingsview_bloc.dart';
import 'package:supalist/bloc/settingsview_states.dart';
import 'package:supalist/resources/values.dart';
import 'package:webview_flutter/webview_flutter.dart';

class SettingsView extends StatelessWidget {
  late final SettingsViewCubit cubit;
  late final BuildContext context;

  Future<void> showPrivacyPolicy() async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
            appBar: AppBar(
              title: Text('Privacy Policy'),
            ),
            body: WebViewWidget(
                gestureRecognizers: Set()
                  ..add(Factory<VerticalDragGestureRecognizer>(
                  () => VerticalDragGestureRecognizer())),
                controller: WebViewController()
                  ..loadRequest(Uri.parse("https://tmc.tiedl.rocks/supalist/dsgvo"))
                  ..setJavaScriptMode(JavaScriptMode.unrestricted),
              ),
          );
        },
      ),
    );
  }

  Future<void> showBuyMeACoffee() async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
            appBar: AppBar(
              title: Text('Buy Me A Coffee'),
            ),
            body: WebViewWidget(
                gestureRecognizers: Set()
                  ..add(Factory<VerticalDragGestureRecognizer>(
                  () => VerticalDragGestureRecognizer())),
                controller: WebViewController()
                  ..loadRequest(Uri.parse("https://buymeacoffee.com/tiedl"))
                  ..setJavaScriptMode(JavaScriptMode.unrestricted),
              ),
          );
        },
      ),
    );
  }

  Future<void> showPaypal() async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
            appBar: AppBar(
              title: Text('Paypal'),
            ),
            body: WebViewWidget(
                gestureRecognizers: Set()
                  ..add(Factory<VerticalDragGestureRecognizer>(
                  () => VerticalDragGestureRecognizer())),
                controller: WebViewController()
                  ..loadRequest(Uri.parse("https://paypal.me/tiedl25"))
                  ..setJavaScriptMode(JavaScriptMode.unrestricted),
              ),
          );
        },
      ),
    );
  }

  Widget themeSegment(state) {
    return Container(
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        border: Border.all(
          style: BorderStyle.none,
        ),
        borderRadius: BorderRadius.circular(Values.borderRadius)),
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
      )
    );
  }

  Widget infoSegment(String version) {
    return Container(
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        border: Border.all(
          style: BorderStyle.none,
        ),
        borderRadius: BorderRadius.circular(Values.borderRadius)),
      child: Column(
        children: [
          ListTile(
            title: Text("Version"),
            subtitle: Text(version),
          ),
          const Divider(
            thickness: 0.2,
            indent: 15,
            endIndent: 15,
          ),
          ListTile(
            title: Text("Privacy Policy"),
            trailing: Icon(Icons.open_in_browser),
            onTap: () => showPrivacyPolicy(),
          ),
        ],
      ),
    );
  }

  Widget donationSegment() {
    return Container(
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          border: Border.all(
            style: BorderStyle.none,
          ),
          borderRadius: BorderRadius.circular(Values.borderRadius)),
      child: Column(
        children: [
          ListTile(
            title: Text('Buy me a coffee'),
            trailing: Icon(Icons.coffee),
            onTap: () => showBuyMeACoffee(),
          ),
          const Divider(
            thickness: 0.2,
            indent: 15,
            endIndent: 15,
          ),
          ListTile(
            title: Text('Let Elon bring me money'),
            trailing: Icon(Icons.paypal),
            onTap: () => showPaypal(),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    this.context = context;
    cubit = context.read<SettingsViewCubit>();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: BlocBuilder<SettingsViewCubit, SettingsViewState>(
          builder: (context, state) {
            if (state is SettingsViewLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            state as SettingsViewLoaded;

            return SingleChildScrollView(
              child: Column(
                children: [
                  themeSegment(state),
                  infoSegment(state.version),
                  donationSegment(),
                ],
              ),
            );
          },
        ),
    );
  }
}
