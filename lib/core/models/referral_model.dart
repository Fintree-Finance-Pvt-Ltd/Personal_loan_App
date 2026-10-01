class ReferralDashboardModel {
  final String referralCode;
  final String shareLink;
  final int totalReferrals;
  final int successfulReferrals;
  final double availableDiscount;
  final double usedDiscount;
  final String? expiryDate;
  final bool hasAvailableBenefit;
  final int availableBenefitsCount;
  final List<ReferralHistoryItem> referralHistory;

  const ReferralDashboardModel({
    required this.referralCode,
    required this.shareLink,
    required this.totalReferrals,
    required this.successfulReferrals,
    required this.availableDiscount,
    required this.usedDiscount,
    this.expiryDate,
    required this.hasAvailableBenefit,
    required this.availableBenefitsCount,
    required this.referralHistory,
  });

  factory ReferralDashboardModel.fromJson(Map<String, dynamic> json) {
    final historyList = (json['referralHistory'] as List<dynamic>?)
            ?.map((e) => ReferralHistoryItem.fromJson(Map<String, dynamic>.from(e)))
            .toList() ??
        [];

    return ReferralDashboardModel(
      referralCode: json['referralCode']?.toString() ?? '',
      shareLink: json['shareLink']?.toString() ?? '',
      totalReferrals: (json['totalReferrals'] as num?)?.toInt() ?? 0,
      successfulReferrals: (json['successfulReferrals'] as num?)?.toInt() ?? 0,
      availableDiscount: (json['availableDiscount'] as num?)?.toDouble() ?? 0.0,
      usedDiscount: (json['usedDiscount'] as num?)?.toDouble() ?? 0.0,
      expiryDate: json['expiryDate']?.toString(),
      hasAvailableBenefit: json['hasAvailableBenefit'] == true,
      availableBenefitsCount: (json['availableBenefitsCount'] as num?)?.toInt() ?? 0,
      referralHistory: historyList,
    );
  }

  static const ReferralDashboardModel empty = ReferralDashboardModel(
    referralCode: '',
    shareLink: '',
    totalReferrals: 0,
    successfulReferrals: 0,
    availableDiscount: 0.0,
    usedDiscount: 0.0,
    expiryDate: null,
    hasAvailableBenefit: false,
    availableBenefitsCount: 0,
    referralHistory: [],
  );
}

class ReferralHistoryItem {
  final String id;
  final String customerName;
  final String referredAt;
  final String? disbursedAt;
  final String loanStatus;
  final String referralStatus;

  const ReferralHistoryItem({
    required this.id,
    required this.customerName,
    required this.referredAt,
    this.disbursedAt,
    required this.loanStatus,
    required this.referralStatus,
  });

  factory ReferralHistoryItem.fromJson(Map<String, dynamic> json) {
    return ReferralHistoryItem(
      id: json['id']?.toString() ?? '',
      customerName: json['customerName']?.toString() ?? 'Applicant',
      referredAt: json['referredAt']?.toString() ?? '',
      disbursedAt: json['disbursedAt']?.toString(),
      loanStatus: json['loanStatus']?.toString() ?? 'REGISTERED',
      referralStatus: json['referralStatus']?.toString() ?? 'PENDING',
    );
  }

  bool get isDisbursed => loanStatus.toUpperCase() == 'DISBURSED';
  bool get isBenefitCredited => referralStatus.toUpperCase() == 'QUALIFIED' || isDisbursed;

  String get formattedRewardStatus {
    if (isBenefitCredited) {
      return 'Benefit Credited';
    }
    return 'Pending Milestone';
  }
}

class ReferralBenefitResult {
  final bool benefitApplied;
  final String? benefitId;
  final double originalProcessingFee;
  final double discountApplied;
  final double finalProcessingFee;
  final String? discountType;
  final double? discountValue;
  final double? maxDiscountLimit;

  const ReferralBenefitResult({
    required this.benefitApplied,
    this.benefitId,
    required this.originalProcessingFee,
    required this.discountApplied,
    required this.finalProcessingFee,
    this.discountType,
    this.discountValue,
    this.maxDiscountLimit,
  });

  factory ReferralBenefitResult.fromJson(Map<String, dynamic> json) {
    return ReferralBenefitResult(
      benefitApplied: json['benefitApplied'] == true,
      benefitId: json['benefitId']?.toString(),
      originalProcessingFee: (json['originalProcessingFee'] as num?)?.toDouble() ?? 0.0,
      discountApplied: (json['discountApplied'] as num?)?.toDouble() ?? 0.0,
      finalProcessingFee: (json['finalProcessingFee'] as num?)?.toDouble() ?? 0.0,
      discountType: json['discountType']?.toString(),
      discountValue: (json['discountValue'] as num?)?.toDouble(),
      maxDiscountLimit: (json['maxDiscountLimit'] as num?)?.toDouble(),
    );
  }
}

class ReferralValidationResult {
  final bool valid;
  final String? referrerName;

  const ReferralValidationResult({
    required this.valid,
    this.referrerName,
  });

  factory ReferralValidationResult.fromJson(Map<String, dynamic> json) {
    return ReferralValidationResult(
      valid: json['valid'] == true,
      referrerName: json['referrerName']?.toString(),
    );
  }
}
