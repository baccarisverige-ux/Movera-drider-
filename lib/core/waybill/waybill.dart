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

class WaybillStore {
  WaybillStore._();

  static WaybillRecord? _current;
  static WaybillRecord? _next;
  static WaybillRecord? _last;

  static final ValueNotifier<WaybillRecord?> currentNotifier =
      ValueNotifier<WaybillRecord?>(null);
  static final ValueNotifier<WaybillRecord?> nextNotifier =
      ValueNotifier<WaybillRecord?>(null);
  static final ValueNotifier<WaybillRecord?> lastNotifier =
      ValueNotifier<WaybillRecord?>(null);

  static WaybillRecord? get current => _current;
  static set current(WaybillRecord? value) {
    _current = value;
    currentNotifier.value = value;
  }

  static WaybillRecord? get next => _next;
  static set next(WaybillRecord? value) {
    _next = value;
    nextNotifier.value = value;
  }

  static WaybillRecord? get last => _last;
  static set last(WaybillRecord? value) {
    _last = value;
    lastNotifier.value = value;
  }

  static void beginCurrent(WaybillRecord record) {
    current = record;
  }

  static void secureNext(WaybillRecord record) {
    next = record;
  }

  static void completeCurrent() {
    final active = current;
    if (active == null) return;

    last = active.copyWith(
      statusLabel: 'Completed',
      issuedAt: DateTime.now(),
    );
    current = null;
  }

  static void clearNext() {
    next = null;
  }

  static void reset() {
    current = null;
    next = null;
    last = null;
  }
}
