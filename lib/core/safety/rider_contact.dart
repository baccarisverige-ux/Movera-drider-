/// Single source of truth for rider phone contact.
///
/// No per-trip number is connected. Demo names must never be dialed.
class RiderContactPolicy {
  const RiderContactPolicy._();

  static const bool available = false;

  static const String unavailableMessage =
      'Rider phone contact is not connected in this demo.';
}
