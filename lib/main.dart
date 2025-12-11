import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supalist/app_config.dart';
import 'package:supalist/bloc/detailview_bloc.dart';
import 'package:supalist/bloc/masterview_bloc.dart';
import 'package:supalist/bloc/settingsview_bloc.dart';
import 'package:supalist/bloc/theme_bloc.dart';
import 'package:supalist/ui/views/authview.dart';
import 'package:supalist/ui/views/detailview.dart';
import 'package:supalist/ui/views/masterview.dart';
import 'package:supalist/ui/theme/dark_theme.dart';
import 'package:supalist/ui/theme/light_theme.dart';
import 'package:supalist/ui/views/settingsview.dart';
import 'package:supalist/ui/views/splashview.dart';

void updateCheck() {
  if (!kDebugMode) {
    InAppUpdate.checkForUpdate().then((updateInfo) {
      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
          if (updateInfo.immediateUpdateAllowed) {
              // Perform immediate update
              InAppUpdate.performImmediateUpdate().then((appUpdateResult) {
                  if (appUpdateResult == AppUpdateResult.success) {
                    //App Update successful
                  }
              });
          } else if (updateInfo.flexibleUpdateAllowed) {
            //Perform flexible update
            InAppUpdate.startFlexibleUpdate().then((appUpdateResult) {
                  if (appUpdateResult == AppUpdateResult.success) {
                    //App Update successful
                    InAppUpdate.completeFlexibleUpdate();
                  }
              });
          }
      }
    });
  }
  
}

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  if (prefs.getBool('offline') == null) {
    prefs.setBool('offline', false);
  }

  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );

  updateCheck();

  runApp(MyApp(prefs: prefs));
}

class MyApp extends StatelessWidget {
  final SharedPreferences prefs;

  MyApp({required this.prefs});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ThemeCubit(prefs),
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp(
            title: 'Supalist',
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: themeMode,
            initialRoute: "/",
            routes: {
              '/': (context) => SplashView(prefs: prefs),
              '/auth': (context) => AuthView(prefs: prefs),
              '/home': (context) => BlocProvider(
                create: (context) => MasterViewCubit(),
                child: MasterView(),
              ),
              '/settings': (context) => BlocProvider(
                create: (context) =>
                    SettingsViewCubit(context.read<ThemeCubit>()),
                child: SettingsView(),
              ),
              // DetailView route is handled with onGenerateRoute to pass arguments
            },
            onGenerateRoute: (settings) {
              if (settings.name == '/detail') {
                final args = settings.arguments as dynamic;
                final supalist = args;
                return MaterialPageRoute(
                  builder: (context) {
                    return BlocProvider(
                      create: (context) => DetailViewCubit(supalist),
                      child: DetailView(),
                    );
                  },
                );
              }
              return null;
            },
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
