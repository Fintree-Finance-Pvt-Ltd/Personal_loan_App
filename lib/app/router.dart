import 'package:go_router/go_router.dart';
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
import '../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../features/dashboard/presentation/screens/splash_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/otp',
      builder: (context, state) => const OtpScreen(),
    ),
    GoRoute(
      path: '/onboarding/basic-details',
      builder: (context, state) => const BasicDetailsScreen(),
    ),
    GoRoute(
      path: '/onboarding/pan',
      builder: (context, state) => const PanVerificationScreen(),
    ),
    GoRoute(
      path: '/onboarding/profile',
      builder: (context, state) => const ProfileDetailsScreen(),
    ),
    GoRoute(
      path: '/onboarding/live-photo',
      builder: (context, state) => const LivePhotoScreen(),
    ),
    GoRoute(
      path: '/onboarding/digilocker',
      builder: (context, state) => const DigilockerScreen(lan: ''),
    ),
    GoRoute(
      path: '/onboarding/address',
      builder: (context, state) => const AddressScreen(lan: ''),
    ),
    GoRoute(
      path: '/onboarding/review',
      builder: (context, state) => const ApplicationReviewScreen(),
    ),
    GoRoute(
      path: '/application/status',
      builder: (context, state) => const ApplicationStatusScreen(),
    ),
    GoRoute(
      path: '/payment/processing-fee',
      builder: (context, state) => const ProcessingFeeScreen(),
    ),
    GoRoute(
      path: '/loan/:lan/offer',
      builder: (context, state) => LoanOfferScreen(lan: state.pathParameters['lan'] ?? ''),
    ),
    GoRoute(
      path: '/loan/:lan/digilocker',
      builder: (context, state) => DigilockerScreen(lan: state.pathParameters['lan'] ?? ''),
    ),
    GoRoute(
      path: '/loan/:lan/address',
      builder: (context, state) => AddressScreen(lan: state.pathParameters['lan'] ?? ''),
    ),
    GoRoute(
      path: '/loan/:lan/bank',
      builder: (context, state) => BankVerificationScreen(lan: state.pathParameters['lan'] ?? ''),
    ),
    GoRoute(
      path: '/loan/:lan/kfs',
      builder: (context, state) => KfsScreen(lan: state.pathParameters['lan'] ?? ''),
    ),
    GoRoute(
      path: '/loan/:lan/mandate',
      builder: (context, state) => MandateScreen(lan: state.pathParameters['lan'] ?? ''),
    ),
    GoRoute(
      path: '/loan/:lan/esign',
      builder: (context, state) => EsignScreen(lan: state.pathParameters['lan'] ?? ''),
    ),
    GoRoute(
      path: '/loan/:lan/disbursal',
      builder: (context, state) => DisbursalScreen(lan: state.pathParameters['lan'] ?? ''),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardScreen(),
    ),
  ],
);
