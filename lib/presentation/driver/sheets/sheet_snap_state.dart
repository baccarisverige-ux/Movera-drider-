enum SheetSnapState { collapsed, middle, expanded }

extension SheetSnapStateX on SheetSnapState {
  static SheetSnapState fromPosition({
    required double position,
    required double snap,
  }) {
    if (position < snap * 0.5) return SheetSnapState.collapsed;
    if (position < (snap + 1) * 0.5) return SheetSnapState.middle;
    return SheetSnapState.expanded;
  }
}
