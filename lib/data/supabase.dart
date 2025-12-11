import 'package:supabase_flutter/supabase_flutter.dart';

String? get userId => Supabase.instance.client.auth.currentSession?.user.id;

bool get loggedIn => Supabase.instance.client.auth.currentSession?.accessToken != null;

bool get activeSession => Supabase.instance.client.auth.currentSession != null;
