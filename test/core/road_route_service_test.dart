import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:movera/core/geo/geo_point.dart';
import 'package:movera/core/routing/road_route_service.dart';

class _FakeClient extends http.BaseClient {
  _FakeClient(this.onSend);

  final Future<http.StreamedResponse> Function(http.BaseRequest request) onSend;
  int closes = 0;
  int sends = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    sends += 1;
    return onSend(request);
  }

  @override
  void close() {
    closes += 1;
    super.close();
  }
}

void main() {
  const origin = GeoPoint(59.33, 18.06);
  const destination = GeoPoint(59.31, 18.07);

  test('closes an owned client once and leaves an injected client open', () {
    final owned = _FakeClient(
      (_) async => http.StreamedResponse(const Stream.empty(), 200),
    );
    final external = _FakeClient(
      (_) async => http.StreamedResponse(const Stream.empty(), 200),
    );
    final ownedService = RoadRouteService(client: owned, ownsClient: true);
    final externalService = RoadRouteService(client: external);

    ownedService.dispose();
    ownedService.dispose();
    externalService.dispose();

    expect(owned.closes, 1);
    expect(external.closes, 0);
  });

  test('timeout and offline stay route errors', () async {
    final hanging = _FakeClient(
      (_) => Completer<http.StreamedResponse>().future,
    );
    final offline = _FakeClient((_) async {
      throw http.ClientException('offline');
    });
    final slow = RoadRouteService(
      client: hanging,
      timeout: const Duration(milliseconds: 20),
    );
    final down = RoadRouteService(client: offline);

    await expectLater(
      slow.drivingRoute(origin: origin, destination: destination),
      throwsA(
        isA<RoadRouteException>().having(
          (error) => error.message,
          'message',
          contains('still active'),
        ),
      ),
    );
    await expectLater(
      down.drivingRoute(origin: origin, destination: destination),
      throwsA(isA<RoadRouteException>()),
    );
    slow.dispose();
    down.dispose();
  });

  test('malformed routing responses do not create extra clients', () async {
    final client = _FakeClient((_) async {
      return http.StreamedResponse(
        Stream.value(utf8.encode('{"code":"NoRoute"}')),
        200,
      );
    });
    final service = RoadRouteService(client: client);
    for (var i = 0; i < 3; i++) {
      await expectLater(
        service.drivingRoute(origin: origin, destination: destination),
        throwsA(isA<RoadRouteException>()),
      );
    }
    expect(client.sends, 3);
    service.dispose();
    expect(client.closes, 0);
  });
}
