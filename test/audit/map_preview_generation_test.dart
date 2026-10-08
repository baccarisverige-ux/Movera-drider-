import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:movera/core/navigation/map_preview_generation.dart';

void main() {
  test('older offer route cannot change zoom or markers after newer selection',
      () async {
    final requests = MapPreviewGeneration();
    final offerA = Completer<String>();
    final offerB = Completer<String>();
    String? displayedRoute;
    final displayedPreviews = <String>[];

    Future<void> resolve(Completer<String> networkResponse) async {
      final owner = requests.begin();
      final route = await networkResponse.future;
      if (!requests.owns(owner)) return;
      displayedRoute = route;
      displayedPreviews.add(route);
    }

    final first = resolve(offerA);
    final second = resolve(offerB);
    offerB.complete('B / pickup / dropoff');
    await second;
    offerA.complete('A / pickup / dropoff');
    await first;

    expect(displayedRoute, 'B / pickup / dropoff');
    expect(displayedPreviews, ['B / pickup / dropoff']);
  });

  test('dismiss and destination replacement revoke older camera ownership',
      () async {
    final requests = MapPreviewGeneration();
    final pendingRoute = Completer<String>();
    var cameraFits = 0;

    Future<void> resolve() async {
      final owner = requests.begin();
      await pendingRoute.future;
      if (requests.owns(owner)) cameraFits++;
    }

    final pending = resolve();
    requests.cancel();
    pendingRoute.complete('late offer');
    await pending;
    expect(cameraFits, 0);

    final destinationToken = requests.begin();
    expect(requests.owns(destinationToken), isTrue);
    final nextOffer = requests.begin();
    expect(requests.owns(destinationToken), isFalse);
    expect(requests.owns(nextOffer), isTrue);
    requests.cancel();
    expect(requests.owns(nextOffer), isFalse);
  });
}
