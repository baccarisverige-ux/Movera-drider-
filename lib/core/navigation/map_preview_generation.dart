/// Latest-owner guard for async map previews. A route response may arrive
/// after another offer was selected or the preview was dismissed.
class MapPreviewGeneration {
  int _generation = 0;

  int begin() => ++_generation;

  void cancel() => _generation++;

  bool owns(int token) => token == _generation;
}
