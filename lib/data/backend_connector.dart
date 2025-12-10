import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:powersync/powersync.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supalist/app_config.dart';
import 'package:logging/logging.dart';
import 'package:supalist/models/schema.dart';

final log = Logger('powersync-supabase');

/// Postgres Response codes that we cannot recover from by retrying.
final List<RegExp> fatalResponseCodes = [
  // Class 22 — Data Exception
  // Examples include data type mismatch.
  RegExp(r'^22...$'),
  // Class 23 — Integrity Constraint Violation.
  // Examples include NOT NULL, FOREIGN KEY and UNIQUE violations.
  RegExp(r'^23...$'),
  // INSUFFICIENT PRIVILEGE - typically a row-level security violation
  RegExp(r'^42501$'),
];

class BackendConnector extends PowerSyncBackendConnector {
  PowerSyncDatabase db;

  Future<void>? _refreshFuture;

  BackendConnector(this.db);
  @override
  Future<PowerSyncCredentials?> fetchCredentials() async {
    await _refreshFuture;

    var session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: AppConfig.testEmail,
        password: AppConfig.testPassword,
      );
      if (response.session == null) {
        return null;
      }

      session = response.session;
    }

    // Use the access token to authenticate against PowerSync
    final token = session!.accessToken;

    final userId = session.user.id;
    final expiresAt = session.expiresAt == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 3600);

    return PowerSyncCredentials(
      endpoint: AppConfig.powersyncUrl,
      // Use a development token (see Authentication Setup https://docs.powersync.com/installation/authentication-setup/development-tokens) to get up and running quickly
      token: token,
      userId: userId,
      expiresAt: expiresAt,
    );
  }

  @override
  void invalidateCredentials() {
    // Trigger a session refresh if auth fails on PowerSync.
    // Generally, sessions should be refreshed automatically by Supabase.
    // However, in some cases it can be a while before the session refresh is
    // retried. We attempt to trigger the refresh as soon as we get an auth
    // failure on PowerSync.
    //
    // This could happen if the device was offline for a while and the session
    // expired, and nothing else attempt to use the session it in the meantime.
    //
    // Timeout the refresh call to avoid waiting for long retries,
    // and ignore any errors. Errors will surface as expired tokens.
    _refreshFuture = Supabase.instance.client.auth
        .refreshSession()
        .timeout(const Duration(seconds: 5))
        .then((response) => null, onError: (error) => null);
  }

  getSupabaseClient(PowerSyncDatabase database) async {    
    // --- FIX: Create a Supabase client with the required token for the upload ---
    // The default Supabase.instance.client is anonymous if no user is signed in.
    final supabase = SupabaseClient(
      // Use your AppConfig URL and anonKey, but override the headers with the token
      AppConfig.supabaseUrl, 
      AppConfig.supabaseAnonKey
      );

    return supabase;
  }

  @override
  Future<void> uploadData(PowerSyncDatabase database) async {
    final transaction = await database.getNextCrudTransaction();
    if (transaction == null) {
      return;
    }

    final supabase = Supabase.instance.client;
    CrudEntry? lastOp;

    try {
      // The data that needs to be changed in the remote db
      for (var op in transaction.crud) {
        lastOp = op;

        final table = op.table;
        final id = op.id;
        final data = op.opData ?? {};

        switch (op.op) {
          case UpdateType.put:
            await supabase
                .from(table)
                .insert({...data, 'id': id});
            break;
          case UpdateType.patch:
            await supabase
              .from(table)
              .update(data)
              .eq('id', id);
            break;
          case UpdateType.delete:
            await supabase
              .from(table)
              .delete()
              .eq('id', id);
            break;
        }
      }

      // Completes the transaction and moves onto the next one
      await transaction.complete();
    } on PostgrestException catch (e) {
      if (e.code != null &&
          fatalResponseCodes.any((re) => re.hasMatch(e.code!))) {
        /// Instead of blocking the queue with these errors,
        /// discard the (rest of the) transaction.
        ///
        /// Note that these errors typically indicate a bug in the application.
        /// If protecting against data loss is important, save the failing records
        /// elsewhere instead of discarding, and/or notify the user.
        log.severe('Data upload error - discarding $lastOp', e);
        await transaction.complete();
      } else {
        // Error may be retryable - e.g. network error or temporary server error.
        // Throwing an error here causes this call to be retried after a delay.
        rethrow;
      }
    }
  }
}

String? getUserId() {
  return Supabase.instance.client.auth.currentSession?.user.id;
}

bool isLoggedIn() {
  return Supabase.instance.client.auth.currentSession?.accessToken != null;
}

Future<void> logout(PowerSyncDatabase db) async {
  await Supabase.instance.client.auth.signOut();
  await db.disconnectAndClear();
}
