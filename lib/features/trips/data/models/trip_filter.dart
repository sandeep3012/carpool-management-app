/// Filter class for querying trips — plain Dart, no Isar query types
class TripFilter {
  final DateTime? startDate;
  final DateTime? endDate;
  final String? driverId;
  final String? status;
  final int? month;
  final int? year;
  final bool? isLocked;

  const TripFilter({
    this.startDate,
    this.endDate,
    this.driverId,
    this.status,
    this.month,
    this.year,
    this.isLocked,
  });

  TripFilter copyWith({
    DateTime? startDate,
    DateTime? endDate,
    String? driverId,
    String? status,
    int? month,
    int? year,
    bool? isLocked,
  }) {
    return TripFilter(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      driverId: driverId ?? this.driverId,
      status: status ?? this.status,
      month: month ?? this.month,
      year: year ?? this.year,
      isLocked: isLocked ?? this.isLocked,
    );
  }
}
