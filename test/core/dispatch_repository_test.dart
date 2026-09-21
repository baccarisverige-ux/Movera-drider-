import 'package:flutter_test/flutter_test.dart';
import 'package:movera/core/dispatch/demo_dispatch_repository.dart';
import 'package:movera/core/dispatch/dispatch_repository.dart';

void main() {
  test('demo dispatch wins nearby-1 and loses nearby-2', () async {
    final dispatch = DemoDispatchRepository(
      claimDelay: Duration.zero,
    );
    addTearDown(dispatch.dispose);

    final won = await dispatch.claimOffer('nearby-1');
    expect(won.outcome, ClaimOutcome.success);
    expect(won.offer?.id, 'nearby-1');

    final lost = await dispatch.claimOffer('nearby-2');
    expect(lost.outcome, ClaimOutcome.alreadyClaimed);
    expect(lost.offer, isNull);

    final missing = await dispatch.claimOffer('does-not-exist');
    expect(missing.outcome, ClaimOutcome.unavailable);
  });
}
