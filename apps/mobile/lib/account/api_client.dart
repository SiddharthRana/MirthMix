import 'package:dio/dio.dart';

class ApiException implements Exception {
  ApiException({this.status, this.code, this.isNetworkError = false});

  final int? status;

  /// Stable error code from the API (e.g. purchase_account_mismatch), when there is one.
  final String? code;
  final bool isNetworkError;

  @override
  String toString() => 'ApiException($status, $code)';
}

class SubscriptionInfo {
  const SubscriptionInfo({
    required this.provider,
    required this.status,
    this.interval,
    this.currentPeriodEnd,
    required this.cancelAtPeriodEnd,
  });

  factory SubscriptionInfo.fromJson(Map<String, dynamic> j) => SubscriptionInfo(
    provider: j['provider'] as String,
    status: j['status'] as String,
    interval: j['interval'] as String?,
    currentPeriodEnd: _date(j['currentPeriodEnd']),
    cancelAtPeriodEnd: j['cancelAtPeriodEnd'] == true,
  );

  /// google_play, paddle or dodo.
  final String provider;
  final String status;
  final String? interval;
  final DateTime? currentPeriodEnd;
  final bool cancelAtPeriodEnd;

  bool get isWeb => provider != 'google_play';
}

/// GET /v1/me: what the server has verified for this purchaser.
class AccountInfo {
  const AccountInfo({
    required this.id,
    this.email,
    required this.premium,
    this.validUntil,
    this.subscriptions = const [],
  });

  factory AccountInfo.fromJson(Map<String, dynamic> j) => AccountInfo(
    id: j['id'] as String,
    email: j['email'] as String?,
    premium: (j['entitlements'] as Map<String, dynamic>?)?['premiumContent'] == true,
    validUntil: _date(j['validUntil']),
    subscriptions: [
      for (final s in (j['subscriptions'] as List<dynamic>? ?? const []))
        SubscriptionInfo.fromJson(s as Map<String, dynamic>),
    ],
  );

  final String id;
  final String? email;
  final bool premium;
  final DateTime? validUntil;
  final List<SubscriptionInfo> subscriptions;
}

/// GET /v1/billing/config (public).
class BillingConfig {
  const BillingConfig({required this.playAvailable, required this.subscriptionId, required this.webAvailable});

  factory BillingConfig.fromJson(Map<String, dynamic> j) {
    final play = j['googlePlay'] as Map<String, dynamic>? ?? const {};
    final web = j['web'] as Map<String, dynamic>? ?? const {};
    return BillingConfig(
      playAvailable: play['available'] == true,
      subscriptionId: play['subscriptionId'] as String? ?? '',
      webAvailable: web['available'] == true,
    );
  }

  static const unavailable = BillingConfig(playAvailable: false, subscriptionId: '', webAvailable: false);

  final bool playAvailable;
  final String subscriptionId;
  final bool webAvailable;
}

class PlayVerifyResult {
  const PlayVerifyResult({required this.premium, required this.duplicateSubscription});
  final bool premium;
  final bool duplicateSubscription;
}

DateTime? _date(Object? v) => v is String ? DateTime.tryParse(v) : null;

/// The MirthMix API, as far as the app uses it. Tests use a fake.
abstract class AccountApi {
  bool get configured;
  Future<BillingConfig> billingConfig();
  Future<AccountInfo> me();
  Future<String> playAccountRef();
  Future<PlayVerifyResult> verifyPlayPurchase(String purchaseToken);
  Future<void> deleteAccount();
}

class HttpAccountApi implements AccountApi {
  HttpAccountApi(this._dio, this._token);

  /// Base URL is the API origin; paths are versioned here.
  final Dio _dio;
  final String? Function() _token;

  @override
  bool get configured => true;

  Future<Map<String, dynamic>> _send(String method, String path, {Object? data, bool auth = true}) async {
    final token = auth ? _token() : null;
    if (auth && token == null) throw ApiException(status: 401, code: 'signed_out');
    try {
      final res = await _dio.request<Map<String, dynamic>>(
        path,
        data: data,
        options: Options(method: method, headers: {if (token != null) 'Authorization': 'Bearer $token'}),
      );
      return res.data ?? const {};
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == null) throw ApiException(isNetworkError: true);
      final body = e.response?.data;
      throw ApiException(status: status, code: body is Map ? body['code'] as String? : null);
    }
  }

  @override
  Future<BillingConfig> billingConfig() async =>
      BillingConfig.fromJson(await _send('GET', '/v1/billing/config', auth: false));

  @override
  Future<AccountInfo> me() async => AccountInfo.fromJson(await _send('GET', '/v1/me'));

  @override
  Future<String> playAccountRef() async =>
      (await _send('GET', '/v1/billing/google-play/account-ref'))['accountRef'] as String;

  @override
  Future<PlayVerifyResult> verifyPlayPurchase(String purchaseToken) async {
    final j = await _send('POST', '/v1/billing/google-play/verify', data: {'purchaseToken': purchaseToken});
    return PlayVerifyResult(
      premium: j['planId'] == 'premium',
      duplicateSubscription: j['duplicateSubscription'] == true,
    );
  }

  @override
  Future<void> deleteAccount() => _send('DELETE', '/v1/me', data: {'confirm': 'DELETE'});
}

class UnconfiguredAccountApi implements AccountApi {
  const UnconfiguredAccountApi();
  @override
  bool get configured => false;
  Never _fail() => throw ApiException(code: 'unavailable');
  @override
  Future<BillingConfig> billingConfig() async => BillingConfig.unavailable;
  @override
  Future<AccountInfo> me() async => _fail();
  @override
  Future<String> playAccountRef() async => _fail();
  @override
  Future<PlayVerifyResult> verifyPlayPurchase(String purchaseToken) async => _fail();
  @override
  Future<void> deleteAccount() async => _fail();
}
