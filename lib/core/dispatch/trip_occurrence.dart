/// Trip ID for one accepted occurrence of a dispatch offer.
///
/// Demo offer templates reuse IDs such as `nearby-1` across launches, while
/// terminal markers and receipts are durable. Every accept path must use this
/// so a repeated demo ride is never hidden as an already-finished trip.
/// A backend accept response will supply the authoritative trip ID instead.
// Monotonic within the running frontend session: two rapid acceptances can
// receive the same platform clock tick, but must never share an archive/terminal
// identity. An authoritative backend trip ID replaces this temporary ID later.
int _lastOccurrenceMicros = -1;

String tripOccurrenceId(String offerId, {DateTime? now}) {
  final clockMicros = (now ?? DateTime.now()).microsecondsSinceEpoch;
  final occurrenceMicros = clockMicros > _lastOccurrenceMicros
      ? clockMicros
      : _lastOccurrenceMicros + 1;
  _lastOccurrenceMicros = occurrenceMicros;
  return '$offerId-$occurrenceMicros';
}
