/// Latest-owner guard for async map previews. A route response may arrive
/// after another offer was selected or the preview was dismissed.
class MapPreviewGeneration {
  int _generation = 0;

  int begin() => ++_generation;

  void cancel() => _generation++;

  bool owns(int token) => token == _generation;

  /// A partial road route still needs both pickup and drop-off in its
  /// camera bounds. Do not let a failed leg crop the destination marker.
  static List<T> framingPoints<T>(
    T pickup,
    T dropoff,
    Iterable<T> roadPoints,
  ) => <T>[pickup, dropoff, ...roadPoints];
}
