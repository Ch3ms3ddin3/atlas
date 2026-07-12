/// Jour férié normalisé pour le mapper.
class HolidayEntry {
  const HolidayEntry({
    required this.date,
    required this.name,
    this.isIslamicEstimated = false,
  });

  /// Date civile (année-mois-jour, sans fuseau).
  final DateTime date;
  final String name;
  final bool isIslamicEstimated;
}
