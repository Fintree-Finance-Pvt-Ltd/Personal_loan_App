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
      
      final customer = CustomerModel.fromJson(rawCustomerData is Map<String, dynamic> ? rawCustomerData : {});

      PostApprovalJourneyModel? postApproval;
      String nextRoute = '/dashboard';

      if (!customer.panVerified) {
        nextRoute = '/dashboard';
      } else if (customer.fullName == null || customer.residentialPincode == null) {
        nextRoute = '/onboarding/basic-details';
      } else if (customer.employmentType == null) {
        nextRoute = '/dashboard';
      } else if (customer.latestApplicationStatus == null || customer.latestApplicationStatus == 'DRAFT') {
        nextRoute = '/dashboard';
      } else if (customer.latestApplicationStatus == 'SUBMITTED') {
        nextRoute = '/application/status';
      } else if (customer.latestApplicationStatus == 'LENDER_APPROVED' && customer.latestLan != null) {
        final lan = customer.latestLan!;
        await storage.saveActiveLan(lan);
        final postApprovalRes = await apiClient.get('/customer/loans/$lan/post-approval?customerId=$customerId');
        
        dynamic rawPostData = postApprovalRes;
        if (rawPostData is Map<String, dynamic> && rawPostData['data'] != null) {
          rawPostData = rawPostData['data'];
        }
        
        postApproval = PostApprovalJourneyModel.fromJson(rawPostData is Map<String, dynamic> ? rawPostData : postApprovalRes);
        final step = postApproval.workflow.currentStep;
        nextRoute = _mapPostApprovalStepToRoute(step, lan);
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
        return '/loan/$lan/digilocker';
      case 'ADDRESS_CONFIRMATION':
        return '/loan/$lan/address';
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
        return '/dashboard';
    }
  }
}

final journeyControllerProvider = StateNotifierProvider<JourneyController, JourneyState>((ref) {
  return JourneyController(ref);
});
