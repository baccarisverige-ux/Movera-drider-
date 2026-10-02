/// Trip ID for one accepted occurrence of a dispatch offer.
///
/// Demo offer templates reuse IDs such as `nearby-1` across launches, while
/// terminal markers and receipts are durable. Every accept path must use this
/// so a repeated demo ride is never hidden as an already-finished trip.
/// A backend accept response will supply the authoritative trip ID instead.
String tripOccurrenceId(String offerId, {DateTime? now}) =>
    '$offerId-${(now ?? DateTime.now()).microsecondsSinceEpoch}';
