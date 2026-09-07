class CustomerModel {
  final String id;
  final String customerCode;
  final String mobileNumber;
  final bool mobileVerified;
  final String? fullName;
  final String? firstName;
  final String? middleName;
  final String? lastName;
  final String? fatherName;
  final String? panNumber;
  final bool panVerified;
  final String? dateOfBirth;
  final String? gender;
  final String? email;
  final bool emailVerified;
  final String? residentialPincode;
  final String? residentialCity;
  final String? residentialState;
  final String? workPincode;
  final String? residenceStatus;
  final String? employmentType;
  final String? companyType;
  final String? companyName;
  final String? designation;
  final String? businessName;
  final String? businessConstitution;
  final num? monthlyIncome;
  final num? annualTurnover;
  final String? employmentVintage;
  final String? totalExperience;
  final String? salaryMode;
  final String? businessVintage;
  final String? accountStatus;
  final String? onboardingStatus;
  final String? eligibilityStatus;
  final String? eligibilityReason;
  final String? latestApplicationId;
  final String? latestApplicationStatus;
  final String? latestLan;
  final String? latestLoanStatus;
  final bool assessmentFeePaid;
  final String? allocatedLenderName;
  final String? allocatedLenderCode;
  final Map<String, dynamic>? assessmentFee;
  final bool aadhaarVerified;
  final String? aadhaarKycStatus;
  final String? maskedAadhaar;
  final String? aadhaarVerifiedAt;
  final bool aaVerified;
  final String? aaStatus;
  final String? accountAggregatorStatus;
  final List<String> updateReadinessReasons;
  final Map<String, dynamic>? consentTexts;
  final String? nextPermittedStep;
  final String? platformLan;
  final int completedLoansCount;

  const CustomerModel({
    required this.id,
    required this.customerCode,
    required this.mobileNumber,
    required this.mobileVerified,
    this.fullName,
    this.firstName,
    this.middleName,
    this.lastName,
    this.fatherName,
    this.panNumber,
    required this.panVerified,
    this.dateOfBirth,
    this.gender,
    this.email,
    required this.emailVerified,
    this.residentialPincode,
    this.residentialCity,
    this.residentialState,
    this.workPincode,
    this.residenceStatus,
    this.employmentType,
    this.companyType,
    this.companyName,
    this.designation,
    this.businessName,
    this.businessConstitution,
    this.monthlyIncome,
    this.annualTurnover,
    this.employmentVintage,
    this.totalExperience,
    this.salaryMode,
    this.businessVintage,
    this.accountStatus,
    this.onboardingStatus,
    this.eligibilityStatus,
    this.eligibilityReason,
    this.latestApplicationId,
    this.latestApplicationStatus,
    this.latestLan,
    this.latestLoanStatus,
    this.assessmentFeePaid = false,
    this.allocatedLenderName,
    this.allocatedLenderCode,
    this.assessmentFee,
    this.aadhaarVerified = false,
    this.aadhaarKycStatus,
    this.maskedAadhaar,
    this.aadhaarVerifiedAt,
    this.aaVerified = false,
    this.aaStatus,
    this.accountAggregatorStatus,
    this.updateReadinessReasons = const [],
    this.consentTexts,
    this.nextPermittedStep,
    this.platformLan,
    this.completedLoansCount = 0,
  });

  CustomerModel copyWith({
    String? id,
    String? customerCode,
    String? mobileNumber,
    bool? mobileVerified,
    String? fullName,
    String? firstName,
    String? middleName,
    String? lastName,
    String? fatherName,
    String? panNumber,
    bool? panVerified,
    String? dateOfBirth,
    String? gender,
    String? email,
    bool? emailVerified,
    String? residentialPincode,
    String? residentialCity,
    String? residentialState,
    String? workPincode,
    String? residenceStatus,
    String? employmentType,
    String? companyType,
    String? companyName,
    String? designation,
    String? businessName,
    String? businessConstitution,
    num? monthlyIncome,
    num? annualTurnover,
    String? employmentVintage,
    String? totalExperience,
    String? salaryMode,
    String? businessVintage,
    String? accountStatus,
    String? onboardingStatus,
    String? eligibilityStatus,
    String? eligibilityReason,
    String? latestApplicationId,
    String? latestApplicationStatus,
    String? latestLan,
    String? latestLoanStatus,
    bool? assessmentFeePaid,
    String? allocatedLenderName,
    String? allocatedLenderCode,
    Map<String, dynamic>? assessmentFee,
    bool? aadhaarVerified,
    String? aadhaarKycStatus,
    String? maskedAadhaar,
    String? aadhaarVerifiedAt,
    bool? aaVerified,
    String? aaStatus,
    String? accountAggregatorStatus,
    List<String>? updateReadinessReasons,
    Map<String, dynamic>? consentTexts,
    String? nextPermittedStep,
    String? platformLan,
    int? completedLoansCount,
  }) {
    return CustomerModel(
      id: id ?? this.id,
      customerCode: customerCode ?? this.customerCode,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      mobileVerified: mobileVerified ?? this.mobileVerified,
      fullName: fullName ?? this.fullName,
      firstName: firstName ?? this.firstName,
      middleName: middleName ?? this.middleName,
      lastName: lastName ?? this.lastName,
      fatherName: fatherName ?? this.fatherName,
      panNumber: panNumber ?? this.panNumber,
      panVerified: panVerified ?? this.panVerified,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      email: email ?? this.email,
      emailVerified: emailVerified ?? this.emailVerified,
      residentialPincode: residentialPincode ?? this.residentialPincode,
      residentialCity: residentialCity ?? this.residentialCity,
      residentialState: residentialState ?? this.residentialState,
      workPincode: workPincode ?? this.workPincode,
      residenceStatus: residenceStatus ?? this.residenceStatus,
      employmentType: employmentType ?? this.employmentType,
      companyType: companyType ?? this.companyType,
      companyName: companyName ?? this.companyName,
      designation: designation ?? this.designation,
      businessName: businessName ?? this.businessName,
      businessConstitution: businessConstitution ?? this.businessConstitution,
      monthlyIncome: monthlyIncome ?? this.monthlyIncome,
      annualTurnover: annualTurnover ?? this.annualTurnover,
      employmentVintage: employmentVintage ?? this.employmentVintage,
      totalExperience: totalExperience ?? this.totalExperience,
      salaryMode: salaryMode ?? this.salaryMode,
      businessVintage: businessVintage ?? this.businessVintage,
      accountStatus: accountStatus ?? this.accountStatus,
      onboardingStatus: onboardingStatus ?? this.onboardingStatus,
      eligibilityStatus: eligibilityStatus ?? this.eligibilityStatus,
      eligibilityReason: eligibilityReason ?? this.eligibilityReason,
      latestApplicationId: latestApplicationId ?? this.latestApplicationId,
      latestApplicationStatus: latestApplicationStatus ?? this.latestApplicationStatus,
      latestLan: latestLan ?? this.latestLan,
      latestLoanStatus: latestLoanStatus ?? this.latestLoanStatus,
      assessmentFeePaid: assessmentFeePaid ?? this.assessmentFeePaid,
      allocatedLenderName: allocatedLenderName ?? this.allocatedLenderName,
      allocatedLenderCode: allocatedLenderCode ?? this.allocatedLenderCode,
      assessmentFee: assessmentFee ?? this.assessmentFee,
      aadhaarVerified: aadhaarVerified ?? this.aadhaarVerified,
      aadhaarKycStatus: aadhaarKycStatus ?? this.aadhaarKycStatus,
      maskedAadhaar: maskedAadhaar ?? this.maskedAadhaar,
      aadhaarVerifiedAt: aadhaarVerifiedAt ?? this.aadhaarVerifiedAt,
      aaVerified: aaVerified ?? this.aaVerified,
      aaStatus: aaStatus ?? this.aaStatus,
      accountAggregatorStatus: accountAggregatorStatus ?? this.accountAggregatorStatus,
      updateReadinessReasons: updateReadinessReasons ?? this.updateReadinessReasons,
      consentTexts: consentTexts ?? this.consentTexts,
      nextPermittedStep: nextPermittedStep ?? this.nextPermittedStep,
      platformLan: platformLan ?? this.platformLan,
      completedLoansCount: completedLoansCount ?? this.completedLoansCount,
    );
  }

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    final aaStatusVal = json['aaStatus']?.toString() ??
        json['accountAggregatorStatus']?.toString() ??
        json['bankStatementStatus']?.toString() ??
        json['journey']?['accountAggregatorStatus']?.toString() ??
        json['journey']?['aaStatus']?.toString();

    final isAaVerified = json['aaVerified'] == true ||
        json['accountAggregatorVerified'] == true ||
        json['bankStatementVerified'] == true ||
        json['isAaDone'] == true ||
        json['isAaVerified'] == true ||
        ['SUCCESS', 'COMPLETED', 'VERIFIED'].contains(aaStatusVal?.toUpperCase()) ||
        json['journey']?['aaVerified'] == true ||
        json['journey']?['accountAggregatorVerified'] == true ||
        json['journey']?['bankStatementVerified'] == true ||
        ['SUCCESS', 'COMPLETED', 'VERIFIED'].contains(json['journey']?['accountAggregatorStatus']?.toString().toUpperCase()) ||
        ['SUCCESS', 'COMPLETED', 'VERIFIED'].contains(json['journey']?['aaStatus']?.toString().toUpperCase());

    int parsedCompletedLoans = 0;
    if (json['completedLoansCount'] != null) {
      parsedCompletedLoans = int.tryParse(json['completedLoansCount'].toString()) ?? 0;
    } else if (json['completedLoans'] != null) {
      parsedCompletedLoans = int.tryParse(json['completedLoans'].toString()) ?? 0;
    } else if (json['minimumCompletedLoans'] != null) {
      parsedCompletedLoans = int.tryParse(json['minimumCompletedLoans'].toString()) ?? 0;
    } else if ((json['latestLoanStatus'] ?? '').toString().toUpperCase() == 'FULLY_PAID' ||
               (json['latestLoanStatus'] ?? '').toString().toUpperCase() == 'CLOSED') {
      parsedCompletedLoans = 1;
    }

    Map<String, dynamic>? parsedConsentTexts;
    if (json['consentTexts'] is Map<String, dynamic>) {
      parsedConsentTexts = json['consentTexts'] as Map<String, dynamic>;
    } else if (json['journey']?['consentTexts'] is Map<String, dynamic>) {
      parsedConsentTexts = json['journey']['consentTexts'] as Map<String, dynamic>;
    }

    return CustomerModel(
      id: json['id']?.toString() ?? '',
      customerCode: json['customerCode'] ?? '',
      mobileNumber: json['mobileNumber'] ?? '',
      mobileVerified: json['mobileVerified'] == true,
      fullName: json['fullName'],
      firstName: json['firstName'],
      middleName: json['middleName'],
      lastName: json['lastName'],
      fatherName: json['fatherName'],
      panNumber: json['panNumber'],
      panVerified: json['panVerified'] == true,
      dateOfBirth: json['dateOfBirth'],
      gender: json['gender'],
      email: json['email'],
      emailVerified: json['emailVerified'] == true,
      residentialPincode: json['residentialPincode'],
      residentialCity: json['residentialCity'],
      residentialState: json['residentialState'],
      workPincode: json['workPincode'],
      residenceStatus: json['residenceStatus'],
      employmentType: json['employmentType'],
      companyType: json['companyType'],
      companyName: json['companyName'],
      designation: json['designation'],
      businessName: json['businessName'],
      businessConstitution: json['businessConstitution'],
      monthlyIncome: json['monthlyIncome'] != null ? num.tryParse(json['monthlyIncome'].toString()) : null,
      annualTurnover: json['annualTurnover'] != null ? num.tryParse(json['annualTurnover'].toString()) : null,
      employmentVintage: json['employmentVintage'],
      totalExperience: json['totalExperience'],
      salaryMode: json['salaryMode'],
      businessVintage: json['businessVintage'],
      accountStatus: json['accountStatus'],
      onboardingStatus: json['onboardingStatus'],
      eligibilityStatus: json['eligibilityStatus'],
      eligibilityReason: json['eligibilityReason'],
      latestApplicationId: json['latestApplicationId']?.toString(),
      latestApplicationStatus: json['latestApplicationStatus'],
      latestLan: json['latestLan'],
      latestLoanStatus: json['latestLoanStatus'],
      assessmentFeePaid: json['assessmentFeePaid'] == true ||
          json['latestPaymentStatus']?.toString().toUpperCase() == 'SUCCESS' ||
          (json['latestPayment'] is Map && (json['latestPayment']['status']?.toString().toUpperCase() == 'SUCCESS' || json['latestPayment']['status']?.toString().toUpperCase() == 'PAID')) ||
          (json['plPaymentLinks'] is List && (json['plPaymentLinks'] as List).any((p) => p is Map && (p['status']?.toString().toUpperCase() == 'SUCCESS' || p['status']?.toString().toUpperCase() == 'PAID'))),
      allocatedLenderName: json['allocatedLenderName'],
      allocatedLenderCode: json['allocatedLenderCode'],
      assessmentFee: json['assessmentFee'] is Map<String, dynamic> ? json['assessmentFee'] : null,
      aadhaarVerified: json['aadhaarVerified'] == true,
      aadhaarKycStatus: json['aadhaarKycStatus'],
      maskedAadhaar: json['maskedAadhaar'],
      aadhaarVerifiedAt: json['aadhaarVerifiedAt'],
      aaVerified: isAaVerified,
      aaStatus: aaStatusVal,
      accountAggregatorStatus: json['accountAggregatorStatus']?.toString() ?? aaStatusVal,
      updateReadinessReasons: (json['journey']?['updateReadiness']?['reasons'] is List)
          ? List<String>.from(json['journey']['updateReadiness']['reasons'])
          : [],
      consentTexts: parsedConsentTexts,
      nextPermittedStep: json['journey']?['nextPermittedStep'] as String?,
      platformLan: json['journey']?['platformLan'] as String? ?? json['latestLan'] as String?,
      completedLoansCount: parsedCompletedLoans,
    );
  }
}
