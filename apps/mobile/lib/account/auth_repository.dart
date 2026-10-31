import 'package:supabase_flutter/supabase_flutter.dart' as sb;

class AppUser {
  const AppUser({required this.id, this.email});
  final String id;
  final String? email;
}

enum AuthEvent { signedIn, signedOut, other }

class AuthFailure implements Exception {
  AuthFailure(this.code);

  /// invalid_code, rate_limited, network, unavailable, unknown.
  final String code;
  @override
  String toString() => 'AuthFailure($code)';
}

/// Sign-in boundary. Only people who buy or restore Premium sign in; guests never need to.
/// Email + one-time code (no password, no deep link). Tests use a fake.
abstract class AuthRepository {
  bool get configured;
  AppUser? get currentUser;
  String? get accessToken;
  Stream<AuthEvent> get events;

  /// Emails a 6-digit code; creates the account on first use.
  Future<void> sendCode(String email);
  Future<void> verifyCode({required String email, required String code});
  Future<void> signOut();
}

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._auth);

  final sb.GoTrueClient _auth;

  @override
  bool get configured => true;

  @override
  AppUser? get currentUser {
    final u = _auth.currentUser;
    return u == null ? null : AppUser(id: u.id, email: u.email);
  }

  @override
  String? get accessToken => _auth.currentSession?.accessToken;

  @override
  Stream<AuthEvent> get events => _auth.onAuthStateChange.map(
    (s) => switch (s.event) {
      sb.AuthChangeEvent.signedIn => AuthEvent.signedIn,
      sb.AuthChangeEvent.signedOut => AuthEvent.signedOut,
      _ => AuthEvent.other,
    },
  );

  Future<void> _guard(Future<void> Function() fn) async {
    try {
      await fn();
    } on sb.AuthException catch (e) {
      final code = e.code ?? '';
      if (code == 'otp_expired' || code == 'invalid_credentials') throw AuthFailure('invalid_code');
      if (code.startsWith('over_') || e.statusCode == '429') throw AuthFailure('rate_limited');
      throw AuthFailure('unknown');
    } on Object {
      throw AuthFailure('network');
    }
  }

  @override
  Future<void> sendCode(String email) => _guard(() => _auth.signInWithOtp(email: email.trim()));

  @override
  Future<void> verifyCode({required String email, required String code}) =>
      _guard(() => _auth.verifyOTP(email: email.trim(), token: code.trim(), type: sb.OtpType.email));

  @override
  Future<void> signOut() => _guard(() => _auth.signOut());
}

/// Used when the build has no Supabase configuration.
class UnconfiguredAuthRepository implements AuthRepository {
  const UnconfiguredAuthRepository();
  @override
  bool get configured => false;
  @override
  AppUser? get currentUser => null;
  @override
  String? get accessToken => null;
  @override
  Stream<AuthEvent> get events => const Stream.empty();
  @override
  Future<void> sendCode(String email) async => throw AuthFailure('unavailable');
  @override
  Future<void> verifyCode({required String email, required String code}) async => throw AuthFailure('unavailable');
  @override
  Future<void> signOut() async {}
}

/// A light check before asking the server; the server is the real judge.
bool looksLikeEmail(String v) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim());
