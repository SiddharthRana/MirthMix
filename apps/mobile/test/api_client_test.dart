import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mirthmix/account/api_client.dart';

/// Answers requests from a table instead of the network, and records them.
class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.routes);
  final Map<String, (int, Object)> routes;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final route = routes['${options.method} ${options.path}'];
    if (route == null) throw DioException.connectionError(requestOptions: options, reason: 'offline');
    return ResponseBody.fromString(
      jsonEncode(route.$2),
      route.$1,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  HttpAccountApi api(FakeAdapter adapter, {String? token = 'jwt'}) =>
      HttpAccountApi(Dio(BaseOptions(baseUrl: 'https://api.test'))..httpClientAdapter = adapter, () => token);

  test('reads the account with the bearer token', () async {
    final adapter = FakeAdapter({
      'GET /v1/me': (
        200,
        {
          'id': 'u1',
          'email': 'a@b.test',
          'entitlements': {'premiumContent': true},
          'validUntil': '2026-12-01T00:00:00.000Z',
          'subscriptions': [
            {
              'provider': 'google_play',
              'status': 'active',
              'interval': 'annual',
              'currentPeriodEnd': '2026-12-01T00:00:00.000Z',
              'cancelAtPeriodEnd': false,
            },
          ],
        },
      ),
    });
    final me = await api(adapter).me();
    expect(adapter.requests.single.headers['Authorization'], 'Bearer jwt');
    expect(me.premium, isTrue);
    expect(me.validUntil, DateTime.utc(2026, 12));
    expect(me.subscriptions.single.isWeb, isFalse);
  });

  test('billing config is public and parses availability', () async {
    final adapter = FakeAdapter({
      'GET /v1/billing/config': (
        200,
        {
          'enabled': true,
          'web': {'provider': 'paddle', 'available': true},
          'googlePlay': {'available': true, 'subscriptionId': 'mirthmix_premium'},
        },
      ),
    });
    final c = await api(adapter, token: null).billingConfig();
    expect(adapter.requests.single.headers.containsKey('Authorization'), isFalse);
    expect((c.playAvailable, c.subscriptionId, c.webAvailable), (true, 'mirthmix_premium', true));
  });

  test('sends the purchase token and maps API error codes', () async {
    final ok = FakeAdapter({
      'POST /v1/billing/google-play/verify': (
        200,
        {'planId': 'premium', 'status': 'active', 'duplicateSubscription': true},
      ),
    });
    final res = await api(ok).verifyPlayPurchase('tok');
    expect(ok.requests.single.data, {'purchaseToken': 'tok'});
    expect((res.premium, res.duplicateSubscription), (true, true));

    final bad = FakeAdapter({
      'POST /v1/billing/google-play/verify': (403, {'code': 'purchase_account_mismatch'}),
    });
    await expectLater(
      api(bad).verifyPlayPurchase('tok'),
      throwsA(isA<ApiException>().having((e) => e.code, 'code', 'purchase_account_mismatch')),
    );
  });

  test('network failures and missing sessions are distinguishable', () async {
    await expectLater(
      api(FakeAdapter({})).me(),
      throwsA(isA<ApiException>().having((e) => e.isNetworkError, 'network', isTrue)),
    );
    await expectLater(
      api(FakeAdapter({}), token: null).me(),
      throwsA(isA<ApiException>().having((e) => e.status, 'status', 401)),
    );
  });

  test('account deletion sends the confirmation the API requires', () async {
    final adapter = FakeAdapter({
      'DELETE /v1/me': (200, {'status': 'deleted'}),
    });
    await api(adapter).deleteAccount();
    expect(adapter.requests.single.data, {'confirm': 'DELETE'});
  });
}
