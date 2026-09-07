import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/customer_model.dart';
import '../../../core/models/post_approval_model.dart';
import '../../../core/providers/providers.dart';

class JourneyState {
  final bool isLoading;
  final String? errorMessage;
  final CustomerModel? customer;
  final PostApprovalJourneyModel? postApproval;
  final String targetRoute;

  const JourneyState({
    this.isLoading = false,
    this.errorMessage,
    this.customer,
    this.postApproval,
    this.targetRoute = '/login',
  });

  JourneyState copyWith({
    bool? isLoading,
    String? errorMessage,
    CustomerModel? customer,
    PostApprovalJourneyModel? postApproval,
    String? targetRoute,
  }) {
    return JourneyState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      customer: customer ?? this.customer,
      postApproval: postApproval ?? this.postApproval,
      targetRoute: targetRoute ?? this.targetRoute,
    );
  }
}

class JourneyController extends StateNotifier<JourneyState> {
  final Ref ref;

  JourneyController(this.ref) : super(const JourneyState());

  Future<void> syncCustomerState() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final storage = ref.read(secureStorageProvider);
      final apiClient = ref.read(apiClientProvider);

      final customerId = await storage.getCustomerId();
      if (customerId == null || customerId.isEmpty) {
        state = state.copyWith(isLoading: false, targetRoute: '/login');
        return;
      }

      final customerRes = await apiClient.get('/customer/$customerId');
      
      // Unwrap double nested 'data' from NestJS backend if present
      dynamic rawCustomerData = customerRes;
      if (rawCustomerData is Map<String, dynamic> && rawCustomerData['data'] != null) {
        rawCustomerData = rawCustomerData['data'];
      }
      if (rawCustomerData is Map<String, dynamic> && rawCustomerData['data'] != null) {
        rawCustomerData = rawCustomerData['data'];
      }
      
      CustomerModel customer = CustomerModel.fromJson(rawCustomerData is Map<String, dynamic> ? rawCustomerData : {});

      final lan = customer.latestLan ?? customer.platformLan ?? '';
      if (!customer.aaVerified && lan.isNotEmpty) {
        try {
          final aaRes = await apiClient.get('/customer/loans/$lan/account-aggregator/status');
          dynamic aaData = aaRes;
          if (aaData is Map<String, dynamic> && aaData['data'] != null) {
            aaData = aaData['data'];
          }
          if (aaData is Map<String, dynamic>) {
            final statusStr = (aaData['status'] ?? '').toString().toUpperCase();
            final dataStatusStr = (aaData['dataStatus'] ?? '').toString().toUpperCase();
            final isDone = aaData['completed'] == true ||
                ['SUCCESS', 'COMPLETED', 'VERIFIED'].contains(statusStr) ||
                ['COMPLETED', 'FETCHED', 'DELIVERED'].contains(dataStatusStr);
            if (isDone) {
              customer = customer.copyWith(
                aaVerified: true,
                aaStatus: statusStr.isNotEmpty ? statusStr : 'SUCCESS',
                accountAggregatorStatus: statusStr.isNotEmpty ? statusStr : 'SUCCESS',
              );
            }
          }
        } catch (_) {}
      }

      PostApprovalJourneyModel? postApproval;
      String nextRoute = '/dashboard';

      final livePhotoDone = customer.updateReadinessReasons.isEmpty ||
          !customer.updateReadinessReasons.contains('LIVE_PHOTO_NOT_VERIFIED');

      final digilockerDone = customer.aadhaarVerified ||
          customer.aadhaarKycStatus == 'VERIFIED' ||
          !customer.updateReadinessReasons.contains('DIGILOCKER_KYC_NOT_VERIFIED');

      final addressDone = !customer.updateReadinessReasons.contains('ADDRESS_NOT_CONFIRMED');

      if (!customer.panVerified) {
        nextRoute = '/onboarding/pan';
      } else if (customer.fullName == null || customer.fullName!.trim().isEmpty || customer.residentialPincode == null || customer.residentialPincode!.trim().isEmpty || customer.emailVerified != true) {
        nextRoute = '/onboarding/basic-details';
      } else if (!customer.assessmentFeePaid) {
        nextRoute = '/payment/processing-fee';
      } else if (customer.employmentType == null || customer.monthlyIncome == null) {
        nextRoute = '/onboarding/profile';
      } else if (!livePhotoDone) {
        nextRoute = '/onboarding/live-photo';
      } else if (!digilockerDone) {
        nextRoute = '/onboarding/digilocker';
      } else if (!addressDone) {
        nextRoute = '/onboarding/address';
      } else if (!customer.aaVerified) {
        nextRoute = '/onboarding/account-aggregator';
      } else if (customer.nextPermittedStep == 'PRE_APPROVAL_OFFER_SELECTION' ||
                 customer.latestApplicationStatus == 'LENDER_PRE_APPROVED') {
        final effectiveLan = customer.latestLan ?? customer.platformLan ?? '';
        nextRoute = effectiveLan.isNotEmpty ? '/loan/$effectiveLan/offer?isPreApproval=true' : '/onboarding/offer';
      } else if (customer.latestApplicationStatus == null ||
                 customer.latestApplicationStatus == 'DRAFT' ||
                 customer.nextPermittedStep == 'SUBMIT_APPLICATION') {
        nextRoute = '/onboarding/review';
      } else if (customer.latestApplicationStatus == 'SUBMITTED' ||
                 customer.latestApplicationStatus == 'PENDING_CREDIT_REVIEW' ||
                 customer.latestApplicationStatus == 'LENDER_REVIEW' ||
                 customer.nextPermittedStep == 'LENDER_DECISION_PROCESSING' ||
                 customer.nextPermittedStep == 'APPROVAL_PROCESSING') {
        nextRoute = '/application/status';
      } else if (customer.latestApplicationStatus == 'LENDER_APPROVED' && (customer.latestLan != null || customer.platformLan != null)) {
        final effectiveLan = (customer.latestLan ?? customer.platformLan)!;
        await storage.saveActiveLan(effectiveLan);
        final postApprovalRes = await apiClient.get('/customer/loans/$effectiveLan/post-approval?customerId=$customerId');
        
        dynamic rawPostData = postApprovalRes;
        if (rawPostData is Map<String, dynamic> && rawPostData['data'] != null) {
          rawPostData = rawPostData['data'];
        }
        
        postApproval = PostApprovalJourneyModel.fromJson(rawPostData is Map<String, dynamic> ? rawPostData : postApprovalRes);
        final step = postApproval.workflow.currentStep;
        nextRoute = _mapPostApprovalStepToRoute(step, effectiveLan);
      } else {
        nextRoute = '/dashboard';
      }

      state = state.copyWith(
        isLoading: false,
        customer: customer,
        postApproval: postApproval,
        targetRoute: nextRoute,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  String _mapPostApprovalStepToRoute(String step, String lan) {
    switch (step) {
      case 'APPROVAL_SUMMARY':
        return '/loan/$lan/offer';
      case 'DIGILOCKER_KYC':
      case 'ADDRESS_CONFIRMATION':
      case 'ACCOUNT_AGGREGATOR':
      case 'BANK_STATEMENT':
      case 'BANK_VERIFICATION':
        return '/loan/$lan/bank';
      case 'KFS_ACCEPTANCE':
        return '/loan/$lan/kfs';
      case 'EMANDATE':
        return '/loan/$lan/mandate';
      case 'ESIGN':
        return '/loan/$lan/esign';
      case 'READY_FOR_DISBURSAL':
        return '/loan/$lan/disbursal';
      case 'DISBURSAL_PROCESSING':
      case 'DISBURSED':
        return '/loan/$lan/loan-details';
      default:
        return '/loan/$lan/bank';
    }
  }
}

final journeyControllerProvider = StateNotifierProvider<JourneyController, JourneyState>((ref) {
  return JourneyController(ref);
});
