import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supalist/resources/strings.dart';
import 'package:supabase_auth_ui/supabase_auth_ui.dart';
import 'package:supalist/ui/widgets/ui_model.dart';

class AuthView extends StatelessWidget {
  late final context;

  final SharedPreferences prefs;

  AuthView({super.key, required this.prefs});

  SupaEmailAuth get emailAuth => SupaEmailAuth(
    passwordValidator: (value) {
                      if (value == null || value.isEmpty || value.length < 4) {
                        return SupaEmailAuthLocalization().passwordLengthError;
                      }
                      return null;
                    },
    redirectTo: kIsWeb ? null : "supalist://de.tmc.supalist",
    onSignInComplete: (res) async => await Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false),
    onSignUpComplete: (res) => showOverlayMessage(
        context: context, 
        message: Strings.checkEmail,
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    onError: (error) => showOverlayMessage(
        context: context, 
        message: (error as AuthApiException).message,
        backgroundColor: Theme.of(context).colorScheme.primary,
      )    
  );

  TextButton get offlineButton => TextButton(
    style: TextButton.styleFrom(
      foregroundColor: Theme.of(context).textTheme.labelMedium!.color,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      minimumSize: const Size(double.infinity, 30),
    ),
    onPressed: () {
      prefs.setBool('offline', true);
      Navigator.pushNamedAndRemoveUntil(
          context, '/', (route) => false
      );
    },
    child: Text(
      Strings.continueWithoutAccount,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 18,
      )
    )
  );

  @override
  Widget build(BuildContext context) {
    this.context = context;

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24.0, 96.0, 24.0, 24.0),
        children: [
          Column(
            children: [
              Text(
                Strings.signIn,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 24.0),
              emailAuth,
              const SizedBox(height: 24.0),
              offlineButton,
            ],
          ),
        ],
      ),
    );
  }
}
