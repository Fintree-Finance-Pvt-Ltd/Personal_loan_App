class ReferralProfileModel {
  final String referralCode;
  final String referralLink;
  final double totalEarned;
  final double walletBalance;
  final double pendingEarnings;
  final int totalReferredCount;
  final int successfulDisbursalsCount;

  const ReferralProfileModel({
    required this.referralCode,
    required this.referralLink,
    required this.totalEarned,
    required this.walletBalance,
    required this.pendingEarnings,
    required this.totalReferredCount,
    required this.successfulDisbursalsCount,
  });

  ReferralProfileModel copyWith({
    String? referralCode,
    String? referralLink,
    double? totalEarned,
    double? walletBalance,
    double? pendingEarnings,
    int? totalReferredCount,
    int? successfulDisbursalsCount,
  }) {
    return ReferralProfileModel(
      referralCode: referralCode ?? this.referralCode,
      referralLink: referralLink ?? this.referralLink,
      totalEarned: totalEarned ?? this.totalEarned,
      walletBalance: walletBalance ?? this.walletBalance,
      pendingEarnings: pendingEarnings ?? this.pendingEarnings,
      totalReferredCount: totalReferredCount ?? this.totalReferredCount,
      successfulDisbursalsCount: successfulDisbursalsCount ?? this.successfulDisbursalsCount,
    );
  }
}

enum ReferralStatus {
  completed,
  pending,
  expired,
}

class ReferralItemModel {
  final String id;
  final String friendName;
  final String friendPhone;
  final ReferralStatus status;
  final double rewardAmount;
  final DateTime date;

  const ReferralItemModel({
    required this.id,
    required this.friendName,
    required this.friendPhone,
    required this.status,
    required this.rewardAmount,
    required this.date,
  });

  String get formattedStatus {
    switch (status) {
      case ReferralStatus.completed:
        return 'Disbursed (Earned)';
      case ReferralStatus.pending:
        return 'Onboarding Pending';
      case ReferralStatus.expired:
        return 'Expired';
    }
  }
}
