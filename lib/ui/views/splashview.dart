import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supalist/bloc/masterview_bloc.dart';
import 'package:supalist/data/supabase.dart';
import 'package:supalist/ui/views/authview.dart';
import 'package:supalist/ui/views/masterview.dart';

class SplashView extends StatelessWidget {
  final SharedPreferences prefs;
  
  const SplashView({
    super.key,
    required this.prefs,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: !activeSession && prefs.getBool('offline') == false
          ? AuthView(prefs: prefs,)
          : BlocProvider(
              create: (context) => MasterViewCubit(), 
              child: MasterView()
            ),
      ),
    );
  }
}