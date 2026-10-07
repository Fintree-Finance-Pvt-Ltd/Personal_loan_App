import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../models/referral_model.dart';
import 'providers.dart';

class ReferralState {
  final ReferralDashboardModel dashboard;
  final bool isLoading;
  final String? errorMessage;
  final ReferralBenefitResult? appliedBenefit;
  final ReferralValidationResult? validatedReferrer;

  const ReferralState({
    this.dashboard = ReferralDashboardModel.empty,
    this.isLoading = false,
    this.errorMessage,
    this.appliedBenefit,
    this.validatedReferrer,
  });

  ReferralState copyWith({
    ReferralDashboardModel? dashboard,
    bool? isLoading,
    String? errorMessage,
    ReferralBenefitResult? appliedBenefit,
    ReferralValidationResult? validatedReferrer,
  }) {
    return ReferralState(
      dashboard: dashboard ?? this.dashboard,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      appliedBenefit: appliedBenefit ?? this.appliedBenefit,
      validatedReferrer: validatedReferrer ?? this.validatedReferrer,
    );
  }
}

class ReferralNotifier extends StateNotifier<ReferralState> {
  final ApiClient _apiClient;

  ReferralNotifier(this._apiClient) : super(const ReferralState());

  /// Fetch Referral Dashboard Details from GET /api/referral/dashboard
  Future<void> fetchDashboard() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final res = await _apiClient.get('/referral/dashboard');
      final data = res['data'] ?? res;

      if (data is Map<String, dynamic>) {
        final dashboard = ReferralDashboardModel.fromJson(data);
        state = state.copyWith(
          isLoading: false,
          dashboard: dashboard,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      debugPrint('[ReferralNotifier] Error fetching dashboard: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load referral data.',
      );
    }
  }

  /// Validate Referral Code (Registration / Deep Link) via POST /api/referral/validate
  Future<ReferralValidationResult?> validateReferralCode(String code) async {
    try {
      final res = await _apiClient.post(
        '/referral/validate',
        data: {'referralCode': code.trim().toUpperCase()},
      );
      final data = res['data'] ?? res;

      if (data is Map<String, dynamic>) {
        final result = ReferralValidationResult.fromJson(data);
        state = state.copyWith(validatedReferrer: result);
        return result;
      }
    } catch (e) {
      debugPrint('[ReferralNotifier] Error validating code: $e');
    }
    return null;
  }

  /// Apply Fee Waiver Benefit on Processing / Assessment Fee via POST /api/referral/apply-benefit
  Future<ReferralBenefitResult?> applyBenefit({
    required num baseProcessingFee,
    int loanNumber = 1,
  }) async {
    try {
      final res = await _apiClient.post(
        '/referral/apply-benefit',
        data: {
          'baseProcessingFee': baseProcessingFee,
          'loanNumber': loanNumber,
        },
      );
      final data = res['data'] ?? res;

      if (data is Map<String, dynamic>) {
        final result = ReferralBenefitResult.fromJson(data);
        state = state.copyWith(appliedBenefit: result);
        return result;
      }
    } catch (e) {
      debugPrint('[ReferralNotifier] Error applying benefit: $e');
    }
    return null;
  }
}

final referralProvider =
    StateNotifierProvider<ReferralNotifier, ReferralState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ReferralNotifier(apiClient);
});
