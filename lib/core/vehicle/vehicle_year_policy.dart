/// Current model year plus next model year; retain an existing older value.
class VehicleYearPolicy {
  const VehicleYearPolicy._();
  static List<String> choices({required DateTime now, String? selected}) {
    final years = List<String>.generate(
      37,
      (index) => '${now.year + 1 - index}',
    );
    if (selected != null &&
        int.tryParse(selected) != null &&
        !years.contains(selected)) {
      years.add(selected);
    }
    return years;
  }
}
