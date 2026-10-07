import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/widgets/app_page_transitions.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/otp_screen.dart';
import '../features/onboarding/presentation/screens/basic_details_screen.dart';
import '../features/pan/presentation/screens/pan_verification_screen.dart';
import '../features/onboarding/presentation/screens/profile_details_screen.dart';
import '../features/live_photo/presentation/screens/live_photo_screen.dart';
import '../features/application/presentation/screens/application_review_screen.dart';
import '../features/application/presentation/screens/application_status_screen.dart';
import '../features/payment/presentation/screens/processing_fee_screen.dart';
import '../features/loan_offer/presentation/screens/loan_offer_screen.dart';
import '../features/digilocker/presentation/screens/digilocker_screen.dart';
import '../features/address/presentation/screens/address_screen.dart';
import '../features/bank_verification/presentation/screens/bank_verification_screen.dart';
import '../features/kfs/presentation/screens/kfs_screen.dart';
import '../features/mandate/presentation/screens/mandate_screen.dart';
import '../features/esign/presentation/screens/esign_screen.dart';
import '../features/disbursal/presentation/screens/disbursal_screen.dart';
import '../features/loan_details/presentation/screens/loan_details_screen.dart';
import '../features/repayment/presentation/screens/repayment_screen.dart';
import '../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../features/dashboard/presentation/screens/splash_screen.dart';
import '../features/account_aggregator/presentation/screens/account_aggregator_screen.dart';
import '../features/loan_details/presentation/screens/fully_paid_loan_review_screen.dart';
import '../features/loan_details/presentation/screens/all_loans_screen.dart';
import '../features/referral/presentation/screens/referral_screen.dart';
import '../features/support/presentation/screens/support_screen.dart';
import '../features/legal/presentation/screens/privacy_policy_screen.dart';
import '../features/legal/presentation/screens/refund_policy_screen.dart';
import '../features/legal/presentation/screens/legal_policies_screen.dart';

GoRoute _appRoute(
  String path,
  Widget Function(BuildContext context, GoRouterState state) builder,
) {
  return GoRoute(
    path: path,
    pageBuilder: (context, state) => buildAppPageTransition(
      context: context,
      state: state,
      child: builder(context, state),
    ),
  );
}

final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    _appRoute('/splash', (context, state) => const SplashScreen()),
    _appRoute('/login', (context, state) => const LoginScreen()),
    _appRoute('/otp', (context, state) => const OtpScreen()),
    _appRoute('/onboarding/basic-details', (context, state) => const BasicDetailsScreen()),
    _appRoute('/onboarding/pan', (context, state) => const PanVerificationScreen()),
    _appRoute('/onboarding/profile', (context, state) => const ProfileDetailsScreen()),
    _appRoute('/onboarding/live-photo', (context, state) => const LivePhotoScreen()),
    _appRoute('/onboarding/digilocker', (context, state) => const DigilockerScreen(lan: '')),
    _appRoute('/onboarding/address', (context, state) => const AddressScreen(lan: '')),
    _appRoute('/onboarding/account-aggregator', (context, state) => const AccountAggregatorScreen(lan: '')),
    _appRoute('/onboarding/offer', (context, state) => const LoanOfferScreen(lan: '', isOnboarding: true)),
    _appRoute('/onboarding/review', (context, state) => const ApplicationReviewScreen()),
    _appRoute('/application/status', (context, state) => const ApplicationStatusScreen()),
    _appRoute(
      '/payment/processing-fee',
      (context, state) => ProcessingFeeScreen(
        eligibilityData: state.extra as Map<String, dynamic>?,
      ),
    ),
    _appRoute(
      '/loan/:lan/offer',
      (context, state) => LoanOfferScreen(
        lan: state.pathParameters['lan'] ?? '',
        isOnboarding: false,
      ),
    ),
    _appRoute(
      '/loan/:lan/digilocker',
      (context, state) => DigilockerScreen(lan: state.pathParameters['lan'] ?? ''),
    ),
    _appRoute(
      '/loan/:lan/address',
      (context, state) => AddressScreen(lan: state.pathParameters['lan'] ?? ''),
    ),
    _appRoute(
      '/loan/:lan/account-aggregator',
      (context, state) => AccountAggregatorScreen(lan: state.pathParameters['lan'] ?? ''),
    ),
    _appRoute(
      '/loan/:lan/bank',
      (context, state) => BankVerificationScreen(lan: state.pathParameters['lan'] ?? ''),
    ),
    _appRoute(
      '/loan/:lan/kfs',
      (context, state) => KfsScreen(lan: state.pathParameters['lan'] ?? ''),
    ),
    _appRoute(
      '/loan/:lan/mandate',
      (context, state) => MandateScreen(lan: state.pathParameters['lan'] ?? ''),
    ),
    _appRoute(
      '/loan/:lan/esign',
      (context, state) => EsignScreen(lan: state.pathParameters['lan'] ?? ''),
    ),
    _appRoute(
      '/loan/:lan/disbursal',
      (context, state) => DisbursalScreen(lan: state.pathParameters['lan'] ?? ''),
    ),
    _appRoute(
      '/loan/:lan/loan-details',
      (context, state) => LoanDetailsScreen(lan: state.pathParameters['lan'] ?? ''),
    ),
    _appRoute(
      '/loan/:lan/repay',
      (context, state) => RepaymentScreen(lan: state.pathParameters['lan'] ?? ''),
    ),
    _appRoute(
      '/loan/fully-paid-review',
      (context, state) => const FullyPaidLoanReviewScreen(),
    ),
    _appRoute(
      '/loan/:lan/fully-paid-review',
      (context, state) => FullyPaidLoanReviewScreen(lan: state.pathParameters['lan'] ?? ''),
    ),
    _appRoute('/dashboard', (context, state) => const DashboardScreen()),
    _appRoute('/referral', (context, state) => const ReferralScreen()),
    _appRoute('/loans/all', (context, state) => const AllLoansScreen()),
    _appRoute('/my-loans', (context, state) => const AllLoansScreen()),
    _appRoute('/support', (context, state) => const SupportScreen()),
    _appRoute('/help', (context, state) => const SupportScreen()),
    _appRoute('/privacy-policy', (context, state) => const PrivacyPolicyScreen()),
    _appRoute('/refund-policy', (context, state) => const RefundPolicyScreen()),
    _appRoute('/legal', (context, state) => const LegalPoliciesScreen()),
    _appRoute('/policies', (context, state) => const LegalPoliciesScreen()),
  ],
);
