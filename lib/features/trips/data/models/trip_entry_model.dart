/// Presentation-layer models for the Trips feature.
///
/// These are rich, self-contained plain Dart classes used by the UI.
/// They deliberately duplicate some fields from the domain entities so
/// that the presentation layer never imports the data/domain layers
/// directly.  Expense formulas live here so widgets stay pure.
///
/// Business rules:
///   Fuel  = (distanceKm / mileageKmpl) × fuelRatePerLitre
///   Total = fuel + toll + parking + other
///   Share = Total / attendees.length  (driver included in split)

// ── Member ────────────────────────────────────────────────────────────────────

class MemberModel {
  final String id;
  final String name;
  final String initials;

  /// 0-based colour-bucket index → mapped to a palette in the UI layer.
  final int colorIndex;
  final bool isCurrentUser;

  const MemberModel({
    required this.id,
    required this.name,
    required this.initials,
    required this.colorIndex,
    this.isCurrentUser = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is MemberModel && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => name;
}

// ── Expense breakdown ─────────────────────────────────────────────────────────

class ExpenseBreakdown {
  final double distanceKm;
  final double fuelRatePerLitre;
  final double mileageKmpl;
  final double tollExpense;
  final double parkingExpense;
  final double otherExpense;

  const ExpenseBreakdown({
    required this.distanceKm,
    required this.fuelRatePerLitre,
    required this.mileageKmpl,
    this.tollExpense = 0,
    this.parkingExpense = 0,
    this.otherExpense = 0,
  });

  double get fuelExpense => (distanceKm / mileageKmpl) * fuelRatePerLitre;

  double get totalExpense =>
      fuelExpense + tollExpense + parkingExpense + otherExpense;

  ExpenseBreakdown copyWith({
    double? distanceKm,
    double? fuelRatePerLitre,
    double? mileageKmpl,
    double? tollExpense,
    double? parkingExpense,
    double? otherExpense,
  }) {
    return ExpenseBreakdown(
      distanceKm: distanceKm ?? this.distanceKm,
      fuelRatePerLitre: fuelRatePerLitre ?? this.fuelRatePerLitre,
      mileageKmpl: mileageKmpl ?? this.mileageKmpl,
      tollExpense: tollExpense ?? this.tollExpense,
      parkingExpense: parkingExpense ?? this.parkingExpense,
      otherExpense: otherExpense ?? this.otherExpense,
    );
  }
}

// ── Trip entry ────────────────────────────────────────────────────────────────

/// Status constants — kept as plain strings to avoid enum serialisation issues.
class TripStatus {
  TripStatus._();
  static const String active = 'active';
  static const String completed = 'completed';
  static const String cancelled = 'cancelled';
}

class TripEntry {
  final String id;
  final DateTime date;
  final MemberModel driver;

  /// Includes the driver.
  final List<MemberModel> attendees;
  final ExpenseBreakdown expenses;
  final String status;
  final String? notes;
  final DateTime createdAt;

  const TripEntry({
    required this.id,
    required this.date,
    required this.driver,
    required this.attendees,
    required this.expenses,
    required this.status,
    this.notes,
    required this.createdAt,
  });

  int get passengerCount => attendees.length;

  double get perPersonShare =>
      passengerCount == 0 ? 0 : expenses.totalExpense / passengerCount;

  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  TripEntry copyWith({
    String? id,
    DateTime? date,
    MemberModel? driver,
    List<MemberModel>? attendees,
    ExpenseBreakdown? expenses,
    String? status,
    String? notes,
    DateTime? createdAt,
  }) {
    return TripEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      driver: driver ?? this.driver,
      attendees: attendees ?? this.attendees,
      expenses: expenses ?? this.expenses,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

// ── New-trip form state (used by the entry sheet) ─────────────────────────────

class TripFormState {
  final DateTime date;
  final MemberModel? driver;
  final List<MemberModel> attendees;
  final double distanceKm;
  final double fuelRatePerLitre;
  final double mileageKmpl;
  final double tollExpense;
  final double parkingExpense;
  final double otherExpense;
  final String? notes;

  const TripFormState({
    required this.date,
    this.driver,
    this.attendees = const [],
    this.distanceKm = 45.0,
    this.fuelRatePerLitre = 102.0,
    this.mileageKmpl = 15.0,
    this.tollExpense = 0,
    this.parkingExpense = 0,
    this.otherExpense = 0,
    this.notes,
  });

  ExpenseBreakdown get breakdown => ExpenseBreakdown(
        distanceKm: distanceKm,
        fuelRatePerLitre: fuelRatePerLitre,
        mileageKmpl: mileageKmpl,
        tollExpense: tollExpense,
        parkingExpense: parkingExpense,
        otherExpense: otherExpense,
      );

  double get fuelExpense => breakdown.fuelExpense;
  double get totalExpense => breakdown.totalExpense;
  double get perPersonShare =>
      attendees.isEmpty ? 0 : totalExpense / attendees.length;

  bool get isValid =>
      driver != null && attendees.isNotEmpty && distanceKm > 0;

  TripFormState copyWith({
    DateTime? date,
    MemberModel? driver,
    List<MemberModel>? attendees,
    double? distanceKm,
    double? fuelRatePerLitre,
    double? mileageKmpl,
    double? tollExpense,
    double? parkingExpense,
    double? otherExpense,
    String? notes,
  }) {
    return TripFormState(
      date: date ?? this.date,
      driver: driver ?? this.driver,
      attendees: attendees ?? this.attendees,
      distanceKm: distanceKm ?? this.distanceKm,
      fuelRatePerLitre: fuelRatePerLitre ?? this.fuelRatePerLitre,
      mileageKmpl: mileageKmpl ?? this.mileageKmpl,
      tollExpense: tollExpense ?? this.tollExpense,
      parkingExpense: parkingExpense ?? this.parkingExpense,
      otherExpense: otherExpense ?? this.otherExpense,
      notes: notes ?? this.notes,
    );
  }
}
