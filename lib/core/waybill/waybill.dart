import 'package:flutter/foundation.dart';

class WaybillRecord {
  const WaybillRecord({
    required this.tripId,
    required this.statusLabel,
    required this.issuedAt,
    required this.fare,
    required this.service,
    required this.riderName,
    required this.pickup,
    required this.dropoff,
    required this.source,
    required this.driverName,
    required this.vehicle,
    required this.licensePlate,
    required this.passengerCapacity,
  });

  final String tripId;
  final String statusLabel;
  final DateTime issuedAt;
  final String fare;
  final String service;
  final String riderName;
  final String pickup;
  final String dropoff;
  final String source;
  final String driverName;
  final String vehicle;
  final String licensePlate;
  final int passengerCapacity;

  WaybillRecord copyWith({
    String? statusLabel,
    DateTime? issuedAt,
  }) {
    return WaybillRecord(
      tripId: tripId,
      statusLabel: statusLabel ?? this.statusLabel,
      issuedAt: issuedAt ?? this.issuedAt,
      fare: fare,
      service: service,
      riderName: riderName,
      pickup: pickup,
      dropoff: dropoff,
      source: source,
      driverName: driverName,
      vehicle: vehicle,
      licensePlate: licensePlate,
      passengerCapacity: passengerCapacity,
    );
  }
}

abstract interface class WaybillRepository {
  WaybillRecord? get current;
  WaybillRecord? get next;
  WaybillRecord? get last;

  ValueListenable<WaybillRecord?> get currentListenable;
  ValueListenable<WaybillRecord?> get nextListenable;
  ValueListenable<WaybillRecord?> get lastListenable;

  void beginCurrent(WaybillRecord record);
  void secureNext(WaybillRecord record);
  void completeCurrent();
  void discardCurrent();
  void clearNext();
  void reset();

  /// Move a secured next trip into the current slot.
  ///
  /// Returns the promoted record, or null if nothing was queued.
  WaybillRecord? promoteNextToCurrent();
}

/// Frontend implementation. A persistent/backend repository can replace this
/// without changing trip screens.
class InMemoryWaybillRepository implements WaybillRepository {
  InMemoryWaybillRepository._();

  static final InMemoryWaybillRepository instance =
      InMemoryWaybillRepository._();

  final ValueNotifier<WaybillRecord?> _current =
      ValueNotifier<WaybillRecord?>(null);
  final ValueNotifier<WaybillRecord?> _next =
      ValueNotifier<WaybillRecord?>(null);
  final ValueNotifier<WaybillRecord?> _last =
      ValueNotifier<WaybillRecord?>(null);

  @override
  WaybillRecord? get current => _current.value;

  @override
  WaybillRecord? get next => _next.value;

  @override
  WaybillRecord? get last => _last.value;

  @override
  ValueListenable<WaybillRecord?> get currentListenable => _current;

  @override
  ValueListenable<WaybillRecord?> get nextListenable => _next;

  @override
  ValueListenable<WaybillRecord?> get lastListenable => _last;

  @override
  void beginCurrent(WaybillRecord record) {
    _current.value = record;
  }

  @override
  void secureNext(WaybillRecord record) {
    _next.value = record;
  }

  @override
  void completeCurrent() {
    final active = current;
    if (active == null) return;

    _last.value = active.copyWith(
      statusLabel: 'Completed',
      issuedAt: DateTime.now(),
    );
    _current.value = null;
  }

  @override
  void discardCurrent() {
    _current.value = null;
  }

  @override
  void clearNext() {
    _next.value = null;
  }

  @override
  WaybillRecord? promoteNextToCurrent() {
    final queued = next;
    if (queued == null) return null;
    _current.value = queued.copyWith(statusLabel: 'Current trip');
    _next.value = null;
    return queued;
  }

  @override
  void reset() {
    _current.value = null;
    _next.value = null;
    _last.value = null;
  }

  void setLastForTesting(WaybillRecord? record) {
    _last.value = record;
  }
}

/// Compatibility facade while older screens/tests migrate to WaybillRepository.
class WaybillStore {
  WaybillStore._();

  static final InMemoryWaybillRepository _repository =
      InMemoryWaybillRepository.instance;

  static WaybillRecord? get current => _repository.current;
  static set current(WaybillRecord? value) {
    if (value == null) {
      _repository.discardCurrent();
    } else {
      _repository.beginCurrent(value);
    }
  }

  static WaybillRecord? get next => _repository.next;
  static set next(WaybillRecord? value) {
    if (value == null) {
      _repository.clearNext();
    } else {
      _repository.secureNext(value);
    }
  }

  static WaybillRecord? get last => _repository.last;
  static set last(WaybillRecord? value) {
    _repository.setLastForTesting(value);
  }

  static ValueListenable<WaybillRecord?> get currentNotifier =>
      _repository.currentListenable;
  static ValueListenable<WaybillRecord?> get nextNotifier =>
      _repository.nextListenable;
  static ValueListenable<WaybillRecord?> get lastNotifier =>
      _repository.lastListenable;

  static void beginCurrent(WaybillRecord record) =>
      _repository.beginCurrent(record);
  static void secureNext(WaybillRecord record) =>
      _repository.secureNext(record);
  static void completeCurrent() => _repository.completeCurrent();
  static void clearNext() => _repository.clearNext();
  static WaybillRecord? promoteNextToCurrent() =>
      _repository.promoteNextToCurrent();
  static void reset() => _repository.reset();
}
