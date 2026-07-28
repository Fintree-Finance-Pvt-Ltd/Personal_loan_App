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
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
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
      assessmentFeePaid: json['assessmentFeePaid'] == true,
    );
  }
}
