class PostApprovalJourneyModel {
  final LoanSummaryModel loan;
  final LenderInfoModel lender;
  final OfferInfoModel offer;
  final DigilockerInfoModel digilocker;
  final AddressInfoModel? address;
  final BankInfoModel bank;
  final WorkflowInfoModel workflow;

  const PostApprovalJourneyModel({
    required this.loan,
    required this.lender,
    required this.offer,
    required this.digilocker,
    this.address,
    required this.bank,
    required this.workflow,
  });

  factory PostApprovalJourneyModel.fromJson(Map<String, dynamic> json) {
    return PostApprovalJourneyModel(
      loan: LoanSummaryModel.fromJson(json['loan'] ?? {}),
      lender: LenderInfoModel.fromJson(json['lender'] ?? {}),
      offer: OfferInfoModel.fromJson(json['offer'] ?? {}),
      digilocker: DigilockerInfoModel.fromJson(json['digilocker'] ?? {}),
      address: json['address'] != null ? AddressInfoModel.fromJson(json['address']) : null,
      bank: BankInfoModel.fromJson(json['bank'] ?? {}),
      workflow: WorkflowInfoModel.fromJson(json['workflow'] ?? {}),
    );
  }
}

class LoanSummaryModel {
  final String id;
  final String lan;
  final String status;
  final String applicationId;
  final String applicationNumber;
  final num? approvedAmount;
  final String? approvedAt;
  final String? disbursalRequestedAt;
  final String? disbursalCompletedAt;
  final String? disbursalUtr;
  final num? disbursalAmount;
  final String? disbursalDate;
  final String? disbursalStatus;

  const LoanSummaryModel({
    required this.id,
    required this.lan,
    required this.status,
    required this.applicationId,
    required this.applicationNumber,
    this.approvedAmount,
    this.approvedAt,
    this.disbursalRequestedAt,
    this.disbursalCompletedAt,
    this.disbursalUtr,
    this.disbursalAmount,
    this.disbursalDate,
    this.disbursalStatus,
  });

  factory LoanSummaryModel.fromJson(Map<String, dynamic> json) {
    return LoanSummaryModel(
      id: json['id']?.toString() ?? '',
      lan: json['lan'] ?? '',
      status: json['status'] ?? '',
      applicationId: json['applicationId']?.toString() ?? '',
      applicationNumber: json['applicationNumber'] ?? '',
      approvedAmount: json['approvedAmount'] != null ? num.tryParse(json['approvedAmount'].toString()) : null,
      approvedAt: json['approvedAt']?.toString(),
      disbursalRequestedAt: json['disbursalRequestedAt']?.toString(),
      disbursalCompletedAt: json['disbursalCompletedAt']?.toString(),
      disbursalUtr: json['disbursalUtr']?.toString(),
      disbursalAmount: json['disbursalAmount'] != null ? num.tryParse(json['disbursalAmount'].toString()) : null,
      disbursalDate: json['disbursalDate']?.toString(),
      disbursalStatus: json['disbursalStatus']?.toString(),
    );
  }
}

class LenderInfoModel {
  final String code;
  final String name;

  const LenderInfoModel({required this.code, required this.name});

  factory LenderInfoModel.fromJson(Map<String, dynamic> json) {
    return LenderInfoModel(
      code: json['code'] ?? 'FTF',
      name: json['name'] ?? 'Fintree Finance Private Limited',
    );
  }
}

class OfferInfoModel {
  final String offerStatus;
  final num? approvedAmount;
  final List<int> allowedTenures;
  final String? validUntil;
  final int? acceptedTenureDays;
  final num? acceptedInterestRate;
  final num? acceptedProcessingFee;
  final num? acceptedEmiAmount;
  final num? acceptedTotalRepayment;

  const OfferInfoModel({
    required this.offerStatus,
    this.approvedAmount,
    required this.allowedTenures,
    this.validUntil,
    this.acceptedTenureDays,
    this.acceptedInterestRate,
    this.acceptedProcessingFee,
    this.acceptedEmiAmount,
    this.acceptedTotalRepayment,
  });

  factory OfferInfoModel.fromJson(Map<String, dynamic> json) {
    List<int> tenures = [30, 45, 60, 90];
    if (json['allowedTenures'] is List) {
      tenures = (json['allowedTenures'] as List).map((e) => int.tryParse(e.toString()) ?? 30).toList();
    }
    return OfferInfoModel(
      offerStatus: json['offerStatus'] ?? 'AVAILABLE',
      approvedAmount: json['approvedAmount'] != null ? num.tryParse(json['approvedAmount'].toString()) : null,
      allowedTenures: tenures,
      validUntil: json['validUntil']?.toString(),
      acceptedTenureDays: json['acceptedTenureDays'] != null ? int.tryParse(json['acceptedTenureDays'].toString()) : null,
      acceptedInterestRate: json['acceptedInterestRate'] != null ? num.tryParse(json['acceptedInterestRate'].toString()) : null,
      acceptedProcessingFee: json['acceptedProcessingFee'] != null ? num.tryParse(json['acceptedProcessingFee'].toString()) : null,
      acceptedEmiAmount: json['acceptedEmiAmount'] != null ? num.tryParse(json['acceptedEmiAmount'].toString()) : null,
      acceptedTotalRepayment: json['acceptedTotalRepayment'] != null ? num.tryParse(json['acceptedTotalRepayment'].toString()) : null,
    );
  }
}

class DigilockerInfoModel {
  final String status;
  final String? maskedAadhaar;
  final String? verifiedAt;

  const DigilockerInfoModel({
    required this.status,
    this.maskedAadhaar,
    this.verifiedAt,
  });

  factory DigilockerInfoModel.fromJson(Map<String, dynamic> json) {
    return DigilockerInfoModel(
      status: json['status'] ?? 'NOT_STARTED',
      maskedAadhaar: json['maskedAadhaar'],
      verifiedAt: json['verifiedAt']?.toString(),
    );
  }
}

class AddressInfoModel {
  final String? addressLine1;
  final String? addressLine2;
  final String? landmark;
  final String? locality;
  final String? district;
  final String? city;
  final String? state;
  final String? country;
  final String? pincode;

  const AddressInfoModel({
    this.addressLine1,
    this.addressLine2,
    this.landmark,
    this.locality,
    this.district,
    this.city,
    this.state,
    this.country,
    this.pincode,
  });

  factory AddressInfoModel.fromJson(Map<String, dynamic> json) {
    return AddressInfoModel(
      addressLine1: json['addressLine1'],
      addressLine2: json['addressLine2'],
      landmark: json['landmark'],
      locality: json['locality'],
      district: json['district'],
      city: json['city'],
      state: json['state'],
      country: json['country'],
      pincode: json['pincode'],
    );
  }
}

class BankInfoModel {
  final bool verified;
  final String? accountHolderName;
  final String? accountType;
  final String? accountMasked;
  final String? ifsc;
  final String? bankName;

  const BankInfoModel({
    required this.verified,
    this.accountHolderName,
    this.accountType,
    this.accountMasked,
    this.ifsc,
    this.bankName,
  });

  factory BankInfoModel.fromJson(Map<String, dynamic> json) {
    return BankInfoModel(
      verified: json['verified'] == true,
      accountHolderName: json['accountHolderName'],
      accountType: json['accountType'],
      accountMasked: json['accountMasked'],
      ifsc: json['ifsc'],
      bankName: json['bankName'],
    );
  }
}

class WorkflowInfoModel {
  final bool lenderApproved;
  final bool offerAccepted;
  final bool digilockerVerified;
  final bool addressConfirmed;
  final bool bankVerified;
  final bool kfsAccepted;
  final bool mandateCompleted;
  final bool esignCompleted;
  final bool readyForDisbursal;
  final String disbursalStatus;
  final String currentStep;

  const WorkflowInfoModel({
    required this.lenderApproved,
    required this.offerAccepted,
    required this.digilockerVerified,
    required this.addressConfirmed,
    required this.bankVerified,
    required this.kfsAccepted,
    required this.mandateCompleted,
    required this.esignCompleted,
    required this.readyForDisbursal,
    required this.disbursalStatus,
    required this.currentStep,
  });

  factory WorkflowInfoModel.fromJson(Map<String, dynamic> json) {
    return WorkflowInfoModel(
      lenderApproved: json['lenderApproved'] == true,
      offerAccepted: json['offerAccepted'] == true,
      digilockerVerified: json['digilockerVerified'] == true,
      addressConfirmed: json['addressConfirmed'] == true,
      bankVerified: json['bankVerified'] == true,
      kfsAccepted: json['kfsAccepted'] == true,
      mandateCompleted: json['mandateCompleted'] == true,
      esignCompleted: json['esignCompleted'] == true,
      readyForDisbursal: json['readyForDisbursal'] == true,
      disbursalStatus: json['disbursalStatus'] ?? 'NOT_STARTED',
      currentStep: json['currentStep'] ?? 'APPROVAL_SUMMARY',
    );
  }
}
