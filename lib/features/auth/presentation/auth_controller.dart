import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/customer_model.dart';
import '../../../core/providers/providers.dart';
import '../data/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(apiClientProvider),
    ref.watch(secureStorageProvider),
  );
});

class AuthState {
  final bool isLoading;
  final String? errorMessage;
  final CustomerModel? customer;
  final String? mobileNumber;
  final bool isOtpSent;

  const AuthState({
    this.isLoading = false,
    this.errorMessage,
    this.customer,
    this.mobileNumber,
    this.isOtpSent = false,
  });

  AuthState copyWith({
    bool? isLoading,
    String? errorMessage,
    CustomerModel? customer,
    String? mobileNumber,
    bool? isOtpSent,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      customer: customer ?? this.customer,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      isOtpSent: isOtpSent ?? this.isOtpSent,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthController(this._repository) : super(const AuthState());

  Future<bool> sendOtp(String mobileNumber, bool consent) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.sendMobileOtp(
        mobileNumber: mobileNumber,
        consentGiven: consent,
      );
      state = state.copyWith(
        isLoading: false,
        mobileNumber: mobileNumber,
        isOtpSent: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<CustomerModel?> verifyOtp(String otp) async {
    if (state.mobileNumber == null) return null;
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final customer = await _repository.verifyMobileOtp(
        mobileNumber: state.mobileNumber!,
        otp: otp,
      );
      state = state.copyWith(
        isLoading: false,
        customer: customer,
      );
      return customer;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return null;
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AuthState();
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref.watch(authRepositoryProvider));
});
