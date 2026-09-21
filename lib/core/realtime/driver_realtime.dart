import 'dart:async';

import 'package:movera/core/contracts/trip_status.dart';

/// Platform realtime envelope (P5 / D8). Sequence-numbered, no WebSocket yet.
enum DriverRealtimeKind {
  tripProjection,
  riderCancelled,
  location,
  driverArrived,
  riderOnTheWay,
}

class DriverRealtimeEvent {
  const DriverRealtimeEvent({
    required this.tripId,
    required this.kind,
    required this.sequence,
    required this.at,
    this.status,
    this.latitude,
    this.longitude,
    this.message,
  });

  final String tripId;
  final DriverRealtimeKind kind;
  final int sequence;
  final DateTime at;
  final TripStatus? status;
  final double? latitude;
  final double? longitude;
  final String? message;
}

/// Mirror of Rider's [RideRealtime] shape so both apps hit the same seam.
abstract interface class DriverRealtime {
  Stream<DriverRealtimeEvent> subscribe(String tripId);

  Future<void> reconnectAndResync(String tripId);

  Future<void> sendSignal({
    required String tripId,
    required DriverRealtimeKind kind,
    String? message,
  });

  void unsubscribe();

  void dispose();
}

/// In-memory bus. A WebSocket adapter replaces this class later.
class MemoryDriverRealtime implements DriverRealtime {
  MemoryDriverRealtime();

  final _controller = StreamController<DriverRealtimeEvent>.broadcast();
  final _lastByTrip = <String, DriverRealtimeEvent>{};
  int _sequence = 0;
  String? _tripId;

  int get sequence => _sequence;

  void publish(DriverRealtimeEvent event) {
    _lastByTrip[event.tripId] = event;
    if (event.sequence > _sequence) _sequence = event.sequence;
    _controller.add(event);
  }

  DriverRealtimeEvent emit({
    required String tripId,
    required DriverRealtimeKind kind,
    TripStatus? status,
    double? latitude,
    double? longitude,
    String? message,
    DateTime? at,
  }) {
    _sequence += 1;
    final event = DriverRealtimeEvent(
      tripId: tripId,
      kind: kind,
      sequence: _sequence,
      at: at ?? DateTime.now(),
      status: status,
      latitude: latitude,
      longitude: longitude,
      message: message,
    );
    publish(event);
    return event;
  }

  @override
  Stream<DriverRealtimeEvent> subscribe(String tripId) {
    _tripId = tripId;
    return _controller.stream.where((event) => event.tripId == tripId);
  }

  @override
  Future<void> sendSignal({
    required String tripId,
    required DriverRealtimeKind kind,
    String? message,
  }) async {
    emit(
      tripId: tripId,
      kind: kind,
      message: message,
    );
  }

  @override
  Future<void> reconnectAndResync(String tripId) async {
    _tripId = tripId;
    final last = _lastByTrip[tripId];
    if (last != null) _controller.add(last);
  }

  @override
  void unsubscribe() {
    _tripId = null;
  }

  @override
  void dispose() {
    unsubscribe();
    _controller.close();
  }

  String? get subscribedTripId => _tripId;
}
