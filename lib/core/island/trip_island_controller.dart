import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:movera/core/routing/route_instruction.dart';

enum TripIslandKind { guidance, arrival, waitingTimer, waitingMessage, status }

class TripIslandInput {
  const TripIslandInput({
    required this.status,
    required this.address,
    required this.waitingMessage,
    this.banner,
    this.arrival,
    this.arrived = false,
    this.waitingSeconds,
    this.paidWait = false,
    this.paidSeconds,
    this.waitingAtStop = false,
    this.navigationStatus,
  });
  final NavigationBanner? banner;
  final String status, address, waitingMessage;
  final String? arrival, navigationStatus;
  final bool arrived, paidWait, waitingAtStop;
  final int? waitingSeconds, paidSeconds;
}

class TripIslandFace {
  const TripIslandFace(this.kind, this.title, this.subtitle, this.identity);
  final TripIslandKind kind;
  final String title, subtitle, identity;
}

/// Chooses a single truthful message. Never changes trip or camera state.
/// Clock ticks and GPS updates do not restart presentation timers.
class TripIslandController extends ChangeNotifier {
  TripIslandController(TripIslandInput input) : _input = input {
    _cycle();
  }
  TripIslandInput _input;
  Timer? _idle, _waitingCycle, _noticeTimer;
  TripIslandFace? _notice;
  bool defaultFace = false, waitingMessageFace = false;
  int _pointers = 0;
  bool _disposed = false;

  void update(TripIslandInput input) {
    final wasWaiting = _input.waitingSeconds != null;
    final changedWait =
        wasWaiting != (input.waitingSeconds != null) ||
        _input.waitingAtStop != input.waitingAtStop;
    final previous = _input;
    final previousFault = previous.navigationStatus ?? previous.banner?.status;
    final fault = input.navigationStatus ?? input.banner?.status;
    _input = input;
    if (wasWaiting && input.waitingSeconds == null) {
      _showNotice(previous.waitingAtStop ? input.status : 'Trip started');
    } else if (previousFault != null && fault == null) {
      _showNotice(
        previousFault.contains('Location') ? 'GPS restored' : 'Route updated',
      );
    } else if (wasWaiting &&
        input.waitingSeconds != null &&
        previous.waitingAtStop == input.waitingAtStop &&
        previous.waitingMessage != input.waitingMessage) {
      _showNotice(input.waitingMessage);
    }
    if (changedWait) {
      waitingMessageFace = false;
      _cycle();
    }
    notifyListeners();
  }

  void _showNotice(String title) {
    _noticeTimer?.cancel();
    _notice = TripIslandFace(TripIslandKind.status, title, '', 'notice-$title');
    _noticeTimer = Timer(const Duration(seconds: 2), () {
      if (_disposed) return;
      _notice = null;
      notifyListeners();
    });
  }

  void hold() {
    _pointers++;
    _idle?.cancel();
  }

  void release() {
    _pointers = (_pointers - 1).clamp(0, 100);
    if (_pointers != 0) return;
    scheduleMicrotask(() {
      if (_disposed) return;
      defaultFace = true;
      notifyListeners();
      _idle?.cancel();
      _idle = Timer(const Duration(seconds: 2), () {
        if (_disposed) return;
        defaultFace = false;
        notifyListeners();
      });
    });
  }

  void _cycle() {
    _waitingCycle?.cancel();
    if (_input.waitingSeconds == null) return;
    _waitingCycle = Timer(Duration(seconds: waitingMessageFace ? 2 : 8), () {
      if (_disposed) return;
      waitingMessageFace = !waitingMessageFace;
      notifyListeners();
      _cycle();
    });
  }

  TripIslandFace get face {
    final i = _input;
    // Persistent location/reroute faults must not be hidden by an old banner.
    final fault = i.navigationStatus ?? i.banner?.status;
    if (fault != null && fault.isNotEmpty) {
      return TripIslandFace(TripIslandKind.status, fault, '', 'status-$fault');
    }
    final b = i.banner;
    final maneuver =
        b != null &&
        b.symbol != NavigationBannerSymbol.arrive &&
        b.symbol != NavigationBannerSymbol.straight;
    if (_notice != null && (i.waitingSeconds != null || !maneuver))
      return _notice!;
    if (i.waitingSeconds != null) {
      if (waitingMessageFace) {
        return TripIslandFace(
          TripIslandKind.waitingMessage,
          i.waitingMessage,
          '',
          'waiting-message-${i.waitingAtStop}',
        );
      }
      final seconds = i.paidWait
          ? (i.paidSeconds ?? i.waitingSeconds!)
          : i.waitingSeconds!;
      return TripIslandFace(
        TripIslandKind.waitingTimer,
        clock(seconds),
        i.waitingAtStop
            ? 'Waiting at stop'
            : i.paidWait
            ? 'Paid waiting'
            : 'Waiting time',
        'waiting-timer-${i.waitingAtStop}-${i.paidWait}',
      );
    }
    // A real maneuver beats proximity copy until the final arrival instruction.
    if (i.arrival != null && !maneuver) {
      return TripIslandFace(
        TripIslandKind.arrival,
        i.arrived ? 'Near ${i.arrival!.toLowerCase()}' : 'Arriving soon',
        i.address,
        'arrival-${i.arrival}',
      );
    }
    return TripIslandFace(
      TripIslandKind.guidance,
      b?.primary ?? i.status,
      [
        if (b != null &&
            b.distanceLabel.isNotEmpty &&
            !b.primary.contains(b.distanceLabel))
          b.distanceLabel,
        if (b?.roadName?.isNotEmpty ?? false) b!.roadName!,
      ].join(' · '),
      'guidance-${b?.symbol.name}-${b?.roadName}-${b?.exitNumber}',
    );
  }

  static String clock(int value) {
    final s = value < 0 ? 0 : value;
    return '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _disposed = true;
    _idle?.cancel();
    _waitingCycle?.cancel();
    _noticeTimer?.cancel();
    super.dispose();
  }
}
