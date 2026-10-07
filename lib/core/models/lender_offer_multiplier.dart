class LenderOfferMultiplier {
  final String id;
  final String productVersionId;
  final int minimumCompletedLoans;
  final double multiplier;
  final int sortOrder;

  const LenderOfferMultiplier({
    required this.id,
    required this.productVersionId,
    required this.minimumCompletedLoans,
    required this.multiplier,
    required this.sortOrder,
  });

  factory LenderOfferMultiplier.fromJson(Map<String, dynamic> json) {
    return LenderOfferMultiplier(
      id: json['id']?.toString() ?? '',
      productVersionId: json['productVersionId']?.toString() ?? '',
      minimumCompletedLoans: int.tryParse(json['minimumCompletedLoans']?.toString() ?? '0') ?? 0,
      multiplier: double.tryParse(json['multiplier']?.toString() ?? '1.0') ?? 1.0,
      sortOrder: int.tryParse(json['sortOrder']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productVersionId': productVersionId,
      'minimumCompletedLoans': minimumCompletedLoans,
      'multiplier': multiplier,
      'sortOrder': sortOrder,
    };
  }
}

class LenderMultiplierCalculator {
  /// Default multiplier matrix based on system LenderOfferMultiplier configuration:
  /// - 0 Completed Loans -> 1.0000x multiplier
  /// - 1 Completed Loan  -> 1.2500x multiplier
  /// - 2 Completed Loans -> 1.7500x multiplier
  /// - 3+ Completed Loans -> 1.8500x multiplier
  static const List<LenderOfferMultiplier> defaultMultipliers = [
    LenderOfferMultiplier(
      id: 'cms63c4030024tsmckp5y838e',
      productVersionId: 'cms63c4010023tsmc242iecd7',
      minimumCompletedLoans: 0,
      multiplier: 1.0000,
      sortOrder: 0,
    ),
    LenderOfferMultiplier(
      id: 'cms63c4030025tsmc3v8xsqvv',
      productVersionId: 'cms63c4010023tsmc242iecd7',
      minimumCompletedLoans: 1,
      multiplier: 1.2500,
      sortOrder: 1,
    ),
    LenderOfferMultiplier(
      id: 'cms63c4030026tsmca8xjpn2o',
      productVersionId: 'cms63c4010023tsmc242iecd7',
      minimumCompletedLoans: 2,
      multiplier: 1.7500,
      sortOrder: 2,
    ),
    LenderOfferMultiplier(
      id: 'cms63c4030027tsmclh4vhzfo',
      productVersionId: 'cms63c4010023tsmc242iecd7',
      minimumCompletedLoans: 3,
      multiplier: 1.8500,
      sortOrder: 3,
    ),
  ];

  /// Resolves the applicable LenderOfferMultiplier for a given number of completed loans.
  static double getMultiplier(
    int completedLoans, [
    List<LenderOfferMultiplier>? customMultipliers,
  ]) {
    final list = customMultipliers != null && customMultipliers.isNotEmpty
        ? customMultipliers
        : defaultMultipliers;

    final sorted = List<LenderOfferMultiplier>.from(list)
      ..sort((a, b) => b.minimumCompletedLoans.compareTo(a.minimumCompletedLoans));

    for (final item in sorted) {
      if (completedLoans >= item.minimumCompletedLoans) {
        return item.multiplier;
      }
    }

    return 1.0;
  }

  /// Calculates the revised loan offer limit based on previous base amount and completed loans count.
  static double calculateRevisedLimit(
    num baseAmount,
    int completedLoans, [
    List<LenderOfferMultiplier>? customMultipliers,
  ]) {
    final multiplier = getMultiplier(completedLoans, customMultipliers);
    return baseAmount * multiplier;
  }
}
