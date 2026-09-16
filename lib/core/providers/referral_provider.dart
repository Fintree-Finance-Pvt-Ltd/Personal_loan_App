import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/referral_model.dart';
import '../../features/dashboard/presentation/journey_controller.dart';
import '../models/customer_model.dart';

class ReferralState {
  final ReferralProfileModel profile;
  final List<ReferralItemModel> items;
  final bool isWithdrawLoading;
  final String? lastWithdrawMsg;

  const ReferralState({
    required this.profile,
    this.items = const [],
    this.isWithdrawLoading = false,
    this.lastWithdrawMsg,
  });

  ReferralState copyWith({
    ReferralProfileModel? profile,
    List<ReferralItemModel>? items,
    bool? isWithdrawLoading,
    String? lastWithdrawMsg,
  }) {
    return ReferralState(
      profile: profile ?? this.profile,
      items: items ?? this.items,
      isWithdrawLoading: isWithdrawLoading ?? this.isWithdrawLoading,
      lastWithdrawMsg: lastWithdrawMsg,
    );
  }
}

class ReferralNotifier extends StateNotifier<ReferralState> {
  ReferralNotifier()
      : super(
          ReferralState(
            profile: const ReferralProfileModel(
              referralCode: 'VISHAL250',
              referralLink: 'https://fintree.app/ref/VISHAL250',
              totalEarned: 750.0,
              walletBalance: 500.0,
              pendingEarnings: 250.0,
              totalReferredCount: 4,
              successfulDisbursalsCount: 3,
            ),
            items: [
              ReferralItemModel(
                id: 'ref_1',
                friendName: 'Rahul Sharma',
                friendPhone: '+91 98765*****',
                status: ReferralStatus.completed,
                rewardAmount: 250.0,
                date: DateTime.now().subtract(const Duration(days: 2)),
              ),
              ReferralItemModel(
                id: 'ref_2',
                friendName: 'Priya Singh',
                friendPhone: '+91 98123*****',
                status: ReferralStatus.completed,
                rewardAmount: 250.0,
                date: DateTime.now().subtract(const Duration(days: 5)),
              ),
              ReferralItemModel(
                id: 'ref_3',
                friendName: 'Amit Verma',
                friendPhone: '+91 97654*****',
                status: ReferralStatus.pending,
                rewardAmount: 250.0,
                date: DateTime.now().subtract(const Duration(hours: 14)),
              ),
              ReferralItemModel(
                id: 'ref_4',
                friendName: 'Siddharth Patel',
                friendPhone: '+91 99887*****',
                status: ReferralStatus.completed,
                rewardAmount: 250.0,
                date: DateTime.now().subtract(const Duration(days: 12)),
              ),
            ],
          ),
        );

  void seedForCustomer(CustomerModel? customer) {
    if (customer == null) return;

    final String name = (customer.fullName != null && customer.fullName!.trim().isNotEmpty)
        ? customer.fullName!.trim().split(' ').first.toUpperCase()
        : 'USER';
    final String code = '${name}250';

    state = state.copyWith(
      profile: state.profile.copyWith(
        referralCode: code,
        referralLink: 'https://fintree.app/ref/$code',
      ),
    );
  }

  Future<bool> withdrawRewards(double amount, String upiId) async {
    if (amount <= 0 || amount > state.profile.walletBalance) {
      state = state.copyWith(lastWithdrawMsg: 'Invalid withdrawal amount.');
      return false;
    }

    state = state.copyWith(isWithdrawLoading: true, lastWithdrawMsg: null);
    await Future.delayed(const Duration(milliseconds: 1400));

    final newBalance = state.profile.walletBalance - amount;
    state = state.copyWith(
      isWithdrawLoading: false,
      profile: state.profile.copyWith(walletBalance: newBalance),
      lastWithdrawMsg: '₹${amount.toStringAsFixed(0)} transferred successfully to $upiId! 🎉',
    );
    return true;
  }
}

final referralProvider =
    StateNotifierProvider<ReferralNotifier, ReferralState>((ref) {
  final notifier = ReferralNotifier();

  ref.listen<JourneyState>(journeyControllerProvider, (previous, next) {
    if (!next.isLoading && next.customer != null) {
      notifier.seedForCustomer(next.customer);
    }
  });

  final journey = ref.read(journeyControllerProvider);
  if (!journey.isLoading && journey.customer != null) {
    notifier.seedForCustomer(journey.customer);
  }

  return notifier;
});
