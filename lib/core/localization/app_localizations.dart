import 'package:flutter/material.dart';

class AppLocalizations {
  final String languageCode;

  const AppLocalizations(this.languageCode);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        const AppLocalizations('en');
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  bool get isHindi => languageCode == 'hi';

  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      // General & Common
      'hello': 'Hello,',
      'hello_user': 'Hello, {name}',
      'welcome_back': 'Welcome back to Finle',
      'submit': 'Submit',
      'continue_btn': 'Continue',
      'proceed': 'Proceed',
      'cancel': 'Cancel',
      'save': 'Save',
      'retry': 'Retry',
      'loading': 'Loading...',
      'please_wait': 'Please wait...',
      'error': 'Error',
      'success': 'Success',
      'back': 'Back',
      'dashboard': 'Dashboard',
      'home': 'Home',
      'my_loans': 'My Loans',
      'support': 'Support & Help',
      'help_desk': '24/7 Customer Care',
      'profile': 'Profile',
      'kyc_verification': 'KYC Verification',
      'bank_details': 'Bank Account Details',
      'active': 'ACTIVE',
      'overdue': 'OVERDUE',
      'paid': 'PAID',
      'unpaid': 'UNPAID',
      'processing': 'PROCESSING',

      // Auth & Login
      'login_title': 'Enter Mobile Number',
      'login_subtitle': 'We will send a 6-digit OTP to verify your account.',
      'mobile_number': 'Mobile Number',
      'get_otp': 'Get OTP',
      'terms_disclaimer':
          'By continuing, you agree to our Terms of Service & Privacy Policy.',
      'verify_otp_title': 'Verify OTP',
      'otp_sent_to': 'Enter the 6-digit OTP sent to +91 {mobile}',
      'resend_otp': 'Resend OTP',
      'verify_continue': 'Verify & Continue',

      // Onboarding & Basic Details
      'basic_details_title': 'Basic Personal Information',
      'first_name': 'First Name',
      'last_name': 'Last Name',
      'dob': 'Date of Birth',
      'gender': 'Gender',
      'male': 'Male',
      'female': 'Female',
      'other': 'Other',
      'pan_number': 'PAN Number',
      'pincode': 'PIN Code',
      'profile_details_title': 'Employment & Monthly Income',
      'employment_type': 'Employment Type',
      'salaried': 'Salaried',
      'self_employed': 'Self Employed',
      'monthly_income': 'Monthly Net Income (₹)',
      'company_name': 'Company Name',

      // Verification Screens
      'pan_verification_title': 'PAN Verification',
      'pan_verified_success': 'PAN Verified Successfully!',
      'name_as_per_pan': 'Name as per PAN',
      'confirm_pan_details': 'Confirm & Continue',
      'digilocker_title': 'Aadhaar KYC Verification',
      'digilocker_sub':
          'Instant Aadhaar verification powered by Govt DigiLocker portal.',
      'proceed_digilocker': 'Proceed to DigiLocker',
      'live_photo_title': 'Take a Clear Selfie',
      'live_photo_sub':
          'Ensure good lighting and face clearly visible inside the circle.',
      'capture_photo': 'Capture Photo',
      'retake': 'Retake',
      'confirm_photo': 'Use This Photo',
      'address_title': 'Current Residential Address',
      'address_line1': 'Address Line 1',
      'address_line2': 'Address Line 2 (Optional)',
      'city': 'City',
      'state': 'State',
      'save_address': 'Save & Proceed',
      'aa_title': 'Bank Statement Verification',
      'aa_sub':
          'Securely fetch 6-month bank statement via RBI Account Aggregator.',
      'fetch_statement': 'Fetch Statement',

      // Application Review & Status
      'review_application_title': 'Review Loan Application',
      'declaration_text':
          'I declare all submitted information is accurate & true.',
      'submit_application': 'Submit Application',
      'underwriting_title': 'Application Submitted & Under Credit Review',
      'underwriting_sub':
          'Our automated underwriting engine is verifying your loan offer.',
      'underwriting_in_progress': 'Underwriting in Progress',
      'application_status': 'Application Status',

      // Loan Offer & Bank Verification
      'loan_offer_title': 'Pre-Approved Loan Offer',
      'approved_loan_amount': 'Approved Loan Amount',
      'tenure_months': 'Tenure ({months} Days)',
      'accept_offer': 'Accept Loan Offer',
      'bank_verification_title': 'Bank Account Verification',
      'account_number': 'Bank Account Number',
      'confirm_account_number': 'Confirm Account Number',
      'ifsc_code': 'IFSC Code',
      'verify_bank': 'Verify Bank Account',

      // KFS, Mandate, e-Sign, Disbursal
      'kfs_title': 'Key Fact Statement (KFS)',
      'apr': 'Annual Percentage Rate (APR)',
      'mandate_title': 'e-NACH Auto-Debit Mandate',
      'mandate_sub': 'Set up automatic EMI repayment from your bank account.',
      'esign_title': 'e-Sign Loan Agreement',
      'sign_agreement': 'e-Sign with Aadhaar OTP',
      'disbursal_title': 'Instant Money Disbursal',
      'transferring_funds': 'Transferring funds to your bank account...',
      'loan_disbursed_celebration': 'Loan Disbursed Successfully! 🎉',
      'funds_credited_msg':
          'Funds have been credited directly to your bank account.',

      // Active Loan & Servicing
      'active_loan_details': 'Active Loan Details',
      'loan_disbursed': 'Loan Disbursed',
      'net_disbursed_amount': 'Disbursed Net Amount',
      'pay_now': 'Pay Now',
      'view_rps': 'View RPS Schedule',
      'utr_reference': 'UTR Reference',
      'destination_bank': 'Destination Bank',
      'refer_earn': 'Refer & Earn ₹250 🎁',
      'refer_earn_sub': 'Invite friends & get instant cashback payout in UPI.',
      'invite': 'Invite',
      'my_profile': 'My Profile & Settings',
      'app_language': 'App Language',
      'english': 'English',
      'hindi': 'हिंदी (Hindi)',
      'sign_out': 'Sign Out of Account',
      'notifications': 'Notifications',
      'mark_all_read': 'Mark all read',
      'all': 'All',
      'loans': 'Loans',
      'emi_due': 'EMI Due',
      'offers': 'Offers',
      'system': 'System',
      'clear_all': 'Clear All Notifications',
      'repayment_schedule': 'Repayment Schedule (RPS)',
      'fixed_emi_amount': 'Fixed EMI Amount',
      'proceed_payment': 'Proceed to Instant Payment',
      'pay_emi': 'Pay EMI',
      'loan_details': 'Loan Details',
      'installment': 'Installment',
      'due_date': 'Due Date',
      'status': 'Status',
      'amount': 'Amount',
      'lender': 'Lending Partner',
      'interest_rate': 'Interest Rate',
      'tenure': 'Tenure',
      'total_repayable': 'Total Repayable',

      // Validation & Error Messages
      'req_field': '{field} is required',
      'invalid_mobile': 'Enter a valid 10-digit mobile number',
      'invalid_otp': 'Enter a valid 6-digit OTP',
      'invalid_pan': 'Enter a valid 10-character PAN (e.g. ABCDE1234F)',
      'invalid_pincode': 'Enter a valid 6-digit PIN code',
      'invalid_ifsc': 'Enter a valid 11-character IFSC code',
      'invalid_account': 'Enter a valid bank account number (9 to 20 digits)',
      'acc_mismatch': 'Account numbers do not match',

      // Additional UI & Dashboard / Loan Details
      'application': 'Application',
      'loan_details_nav': 'Loan Details',
      'active_loan_badge': 'ACTIVE LOAN - DISBURSED',
      'sanctioned_amount': 'Sanctioned Loan Amount',
      'disbursed_loan_amount': 'Disbursed Loan Amount',
      'total_outstanding': 'Total Outstanding Amount',
      'total_paid': 'Total Paid',
      'next_due_emi': 'Next Due EMI',
      'quick_actions': 'Quick Actions',
      'loan_account_summary': 'Loan Account Summary',
      'disbursal_bank_account': 'Disbursal Bank Account',
      'repayment_history': 'Repayment History',
      'lan_copied': 'LAN copied to clipboard',
      'pending_confirmation': 'Pending Confirmation',
      'syncing_details': 'Syncing Loan Details with Lender',
      'no_dues_pending': 'No dues pending',
      'on_schedule': 'On schedule',
      'statement_sync_progress': 'STATEMENT SYNC IN PROGRESS',
      'refresh_details': 'Refresh Disbursal Details',
      'emi_amount': 'EMI Amount',
      'bank_name': 'Bank Name',
      'account_holder': 'Account Holder',
      'repayment_frequency': 'Repayment Frequency',
      'all_caught_up': 'All caught up! 🎉',
      'no_new_notifications': 'You have no new notifications right now.',
      'statement_sync_in_progress': 'STATEMENT SYNC IN PROGRESS',
      'statement_sync_desc':
          'Final RPS schedule & UTR reference statement are being updated.',
      'refresh_disbursal_details': 'Refresh Disbursal Details',
      'repayment_schedule_for': 'Repayment schedule for',
      'rps_populated_utr_synced':
          'will be populated as soon as final UTR statement is synced.',
      'repayment_schedule_populated_lender':
          'Repayment schedule will be populated as soon as loan details are confirmed by lender.',
      'loan_account_no': 'Loan Account No. (LAN)',
      'application_no': 'Application No.',
      'loan_overview': 'Loan Overview',
      'loan_journey': 'Loan Journey',
      'review_approved_loan_offer': 'Review Approved Loan Offer',
      'complete_digilocker_kyc': 'Complete DigiLocker KYC',
      'confirm_residence_address': 'Confirm Residence Address',
      'verify_bank_account': 'Verify Bank Account',
      'review_accept_kfs': 'Review & Accept KFS',
      'register_enach_mandate': 'Register e-NACH Mandate',
      'complete_agreement_esign': 'Complete Agreement e-Sign',
      'view_disbursal_status': 'View Disbursal Status',
      'check_application_status': 'Check Application Status',
      'continue_loan_application': 'Continue Loan Application',
      'start_application': 'Start Application',

      // Dashboard - Hero Banner
      'hero_title': 'Make your financial\ngoals a reality',
      'hero_subtitle': 'Quick. Transparent. Reliable.',

      // Dashboard - KPI Stats
      'view_all': 'View All',
      'approved': 'Approved',
      'active_loan': 'Active Loan',

      // Dashboard - Segmented Tabs
      'application_tab': 'Application',

      // Dashboard - Post-Approval Tab
      'approved_loan': 'APPROVED LOAN',
      'pending_confirmation_label': 'Pending Confirmation',
      'monthly_emi': 'Monthly EMI',
      'to_be_confirmed': 'To be confirmed',
      'your_next_step': 'Your next step',
      'complete_step_disbursal':
          'Complete this step to move closer to disbursal.',
      'loan_journey_progress':
          'Loan Journey ({completed} of {total} completed)',
      'verify_bank_step': 'Verify bank account',
      'verify_bank_step_sub':
          'Complete penny-drop verification for disbursal account',
      'accept_kfs_step': 'Accept Key Fact Statement',
      'accept_kfs_step_sub': 'Review interest, charges and repayment terms',
      'register_mandate_step': 'Register e-NACH mandate',
      'register_mandate_step_sub':
          'Set up automatic EMI repayment from your bank account',
      'esign_step': 'e-Sign loan agreement',
      'esign_step_sub': 'Digitally sign RBI compliant loan documentation',
      'disbursal_step': 'Disbursal',
      'disbursal_step_sub': 'Track direct bank account funds transfer',

      // Dashboard - Crediting Soon Card
      'loan_credited_shortly': 'Your loan will be credited shortly!',
      'disbursal_processing': 'Disbursal is being processed by the lender.',
      'view_loan_details': 'View Loan Details',

      // Dashboard - Disbursed Card
      'active_disbursed_loan': 'ACTIVE DISBURSED LOAN',
      'funds_credited_bank': 'Funds credited to your bank account',
      'disbursed': 'DISBURSED',
      'disbursed_amount': 'Disbursed Amount',
      'loan_account_lan': 'Loan Account (LAN)',
      'disbursal_utr': 'Disbursal UTR',
      'credited_account': 'Credited Account',
      'pay_emi_repay_loan': 'Pay EMI / Repay Loan',
      'view_full_loan_details_rps': 'View Full Loan Details & RPS',

      // Dashboard - My Loans Tab
      'pre_approved_repeat_loan':
          'Pre-Approved Repeat Loan ({multiplier}x applied)',
      'eligible_revised_limit':
          'Eligible for revised limit of {amount} with instant disbursal.',
      'apply_repeat_loan': 'Apply Repeat Loan',
      'approved_loan_amount_label': 'Approved Loan Amount',
      'destination_bank_label': 'Destination Bank',
      'fully_paid': 'Fully Paid',
      'view_rps_label': 'View RPS',

      // Dashboard - Application Tab
      'application_dossier': 'Application Dossier',
      'personal_loan_fintree': 'Personal Loan • Fintree Finance',
      'steps_completed': '{completed} of {total} steps completed',
      'view_application_status': 'View Application Status',
      'apply_for_loan': 'Apply for Loan',
      'resume_application': 'Resume Application',
      'review_submit_application': 'Review & Submit Application',
      'applicant_profile': 'Applicant Profile',
      'applicant_name': 'Applicant Name',
      'email_address': 'Email Address',
      'employer_business': 'Employer / Business',
      'monthly_net_income': 'Monthly Net Income',
      'not_provided': 'Not provided',
      'residence_pincode': 'Residence Pincode',
      'application_journey': 'Application Journey',

      // Application Steps
      'step_basic_details': 'Basic personal details',
      'step_basic_details_sub': 'Name, date of birth, gender and pincode',
      'step_pan_verification': 'PAN verification',
      'step_pan_verification_sub': 'Verify your Permanent Account Number',
      'step_lender_assessment': 'Lender & Assessment fee',
      'step_lender_assessment_sub':
          'Allocated lender and processing fee payment',
      'step_profile_income': 'Profile and income',
      'step_profile_income_sub': 'Employment, income and organisation details',
      'step_live_photo': 'Live photo',
      'step_live_photo_sub': 'Selfie capture and liveness verification',
      'step_digilocker': 'DigiLocker Aadhaar KYC',
      'step_digilocker_sub': 'Secure Aadhaar verification through DigiLocker',
      'step_address': 'Address confirmation',
      'step_address_sub': 'Review and confirm your residence address',
      'step_aa': 'Account Aggregator Verification',
      'step_aa_sub': 'Connect bank account for statement analysis',
      'step_loan_offer': 'Loan Offer Selection',
      'step_loan_offer_sub': 'Select loan tenure and review approved pricing',
      'step_review_submit': 'Review and submit',
      'step_review_submit_sub':
          'Confirm the application before lender submission',

      // Dashboard - Promo Card
      'need_personal_loan': 'Need a Personal Loan?',
      'get_instant_offers':
          'Get instant offers from multiple lenders with minimal documents.',
      'apply_now': 'Apply Now',

      // Dashboard - Smart Credit Perks
      'smart_credit_benefits': 'Smart Credit Benefits',
      'exclusive_perks':
          'Exclusive perks & approval readiness for your profile',
      'high_odds': '98% High Odds',
      'approval_readiness': 'Approval Readiness: Excellent',
      'pre_verified_instant': 'Pre-verified for instant loan disbursement',
      'instant_disbursal': 'Instant 30s Disbursal',
      'direct_transfer_esign': 'Direct transfer upon eSign',
      'zero_foreclosure': 'Zero Foreclosure Fee',
      'pay_off_anytime': 'Pay off anytime with 0% penalty',
      'tier_multiplier': 'Tier Multiplier',
      'higher_limits_emi': 'Higher limits on timely EMIs',
      'digital_kyc': '100% Digital KYC',
      'paperless_digilocker': 'Paperless via DigiLocker & AA',
      'questions_credit_perks': 'Have questions about credit perks?',
      'support_label': 'Support',

      // Dashboard - Logout Modal
      'logout_title': 'Logout from your account?',
      'logout_message':
          'You will need to verify your mobile number again to access your loan journey.',
      'logout': 'Logout',

      // Dashboard - Profile Modal
      'verified_badge': '✓ VERIFIED',
      'profile_score': 'Profile Score',
      'profile_verified': '100% Verified',
      'kyc_status_label': 'KYC Status',
      'digilocker_ok': 'DigiLocker OK',
      'lender_tier': 'Lender Tier',
      'prime_match': 'Prime Match',
      'identity_kyc_details': 'Identity & KYC Details',
      'full_name': 'Full Name',
      'pan_card_number': 'PAN Card Number',
      'aadhaar_kyc': 'Aadhaar KYC',
      'digilocker_linked': 'DigiLocker Linked',
      'employment_financials': 'Employment & Financials',
      'designation': 'Designation',
      'residence_bank_details': 'Residence & Bank Details',
      'residence_status': 'Residence Status',
      'residential_pincode': 'Residential Pincode',
      'disbursal_bank': 'Disbursal Bank',
      'primary_account': 'Primary Account',
      'linked_account': 'Linked Account',

      // Dashboard - Help & Support
      'help_support': 'Help & Support',
      'faqs': 'FAQs',
      'faqs_sub': 'Get answers to common questions',
      'call_support': 'Call Support',
      'email_support': 'Email Support',

      // Verification Status
      'verified': 'Verified',
      'pending': 'Pending',
      'mobile': 'Mobile',
    },
    'hi': {
      'hello': 'नमस्ते,',
      'hello_user': 'नमस्ते, {name}',
      'welcome_back': 'Finle में आपका स्वागत है',
      'submit': 'जमा करें',
      'continue_btn': 'आगे बढ़ें',
      'proceed': 'आगे बढ़ें',
      'cancel': 'रद्द करें',
      'save': 'सुरक्षित करें',
      'retry': 'पुनः प्रयास करें',
      'loading': 'लोड हो रहा है...',
      'please_wait': 'कृपया प्रतीक्षा करें...',
      'error': 'त्रुटि',
      'success': 'सफलता',
      'back': 'पीछे',
      'dashboard': 'डैशबोर्ड',
      'home': 'होम',
      'my_loans': 'मेरे ऋण',
      'support': 'सहायता एवं संपर्क',
      'help_desk': '24/7 ग्राहक सहायता',
      'profile': 'प्रोफाइल',
      'kyc_verification': 'केवाईसी सत्यापन',
      'bank_details': 'बैंक खाता विवरण',
      'active': 'सक्रिय (Active)',
      'overdue': 'अतिदेय (Overdue)',
      'paid': 'भुगतान किया गया (Paid)',
      'unpaid': 'अदत्त (Unpaid)',
      'processing': 'प्रक्रियाधीन (Processing)',

      // Auth & Login
      'login_title': 'मोबाइल नंबर दर्ज करें',
      'login_subtitle':
          'हम आपके खाते को सत्यापित करने के लिए 6 अंकों का OTP भेजेंगे।',
      'mobile_number': 'मोबाइल नंबर',
      'get_otp': 'OTP प्राप्त करें',
      'terms_disclaimer':
          'आगे बढ़कर, आप हमारी सेवा की शर्तों और गोपनीयता नीति से सहमत होते हैं।',
      'verify_otp_title': 'OTP सत्यापित करें',
      'otp_sent_to': '+91 {mobile} पर भेजा गया 6 अंकों का OTP दर्ज करें',
      'resend_otp': 'OTP पुनः भेजें',
      'verify_continue': 'सत्यापित करें और आगे बढ़ें',

      // Onboarding & Basic Details
      'basic_details_title': 'मूल व्यक्तिगत जानकारी',
      'first_name': 'पहला नाम',
      'last_name': 'उपनाम (अंतिम नाम)',
      'dob': 'जन्म तिथि',
      'gender': 'लिंग',
      'male': 'पुरुष',
      'female': 'महिला',
      'other': 'अन्य',
      'pan_number': 'पैन (PAN) संख्या',
      'pincode': 'पिन (PIN) कोड',
      'profile_details_title': 'रोजगार एवं मासिक आय',
      'employment_type': 'रोजगार का प्रकार',
      'salaried': 'वेतनभोगी (Salaried)',
      'self_employed': 'स्व-नियोजित (Self Employed)',
      'monthly_income': 'मासिक शुद्ध आय (₹)',
      'company_name': 'कंपनी का नाम',

      // Verification Screens
      'pan_verification_title': 'पैन (PAN) सत्यापन',
      'pan_verified_success': 'पैन (PAN) सफलतापूर्वक सत्यापित हुआ!',
      'name_as_per_pan': 'पैन के अनुसार नाम',
      'confirm_pan_details': 'पुष्टि करें और आगे बढ़ें',
      'digilocker_title': 'आधार केवाईसी सत्यापन',
      'digilocker_sub': 'सरकारी डिजीलॉकर पोर्टल द्वारा त्वरित आधार सत्यापन।',
      'proceed_digilocker': 'डिजीलॉकर पर आगे बढ़ें',
      'live_photo_title': 'एक स्पष्ट सेल्फी लें',
      'live_photo_sub':
          'सुनिश्चित करें कि प्रकाश अच्छा हो और आपका चेहरा घेरे में स्पष्ट दिखे।',
      'capture_photo': 'फोटो खींचें',
      'retake': 'दोबारा फोटो लें',
      'confirm_photo': 'इस फोटो का उपयोग करें',
      'address_title': 'वर्तमान निवास का पता',
      'address_line1': 'पता पंक्ति 1',
      'address_line2': 'पता पंक्ति 2 (वैकल्पिक)',
      'city': 'शहर',
      'state': 'राज्य',
      'save_address': 'सहेजे और आगे बढ़ें',
      'aa_title': 'बैंक स्टेटमेंट सत्यापन',
      'aa_sub':
          'आरबीआई अकाउंट एग्रीगेटर के जरिए 6 महीने का बैंक विवरण सुरक्षित रूप से प्राप्त करें।',
      'fetch_statement': 'स्टेटमेंट प्राप्त करें',

      // Application Review & Status
      'review_application_title': 'ऋण आवेदन की समीक्षा',
      'declaration_text':
          'मैं घोषणा करता/करती हूं कि प्रस्तुत सभी जानकारी सटीक एवं सत्य है।',
      'submit_application': 'आवेदन जमा करें',
      'underwriting_title': 'आवेदन जमा किया गया एवं ऋण समीक्षा जारी है',
      'underwriting_sub':
          'हमारा स्वचालित मूल्यांकन इंजन आपके ऋण प्रस्ताव का सत्यापन कर रहा है।',
      'underwriting_in_progress': 'समीक्षा प्रगति पर है',
      'application_status': 'आवेदन की स्थिति',

      // Loan Offer & Bank Verification
      'loan_offer_title': 'पूर्व-स्वीकृत ऋण प्रस्ताव',
      'approved_loan_amount': 'स्वीकृत ऋण राशि',
      'tenure_months': 'अवधि ({months} दिन)',
      'accept_offer': 'ऋण प्रस्ताव स्वीकार करें',
      'bank_verification_title': 'बैंक खाता सत्यापन',
      'account_number': 'बैंक खाता संख्या',
      'confirm_account_number': 'खाता संख्या की पुष्टि करें',
      'ifsc_code': 'आईएफएससी (IFSC) कोड',
      'verify_bank': 'बैंक खाता सत्यापित करें',

      // KFS, Mandate, e-Sign, Disbursal
      'kfs_title': 'मुख्य तथ्य विवरण (KFS)',
      'apr': 'वार्षिक प्रतिशत दर (APR)',
      'mandate_title': 'ई-नाच ऑटो-डेबिट जनादेश (e-NACH)',
      'mandate_sub': 'अपने बैंक खाते से स्वचालित ईएमआई पुनर्भुगतान सेट करें।',
      'esign_title': 'ई-साइन ऋण समझौता',
      'sign_agreement': 'आधार OTP द्वारा ई-साइन करें',
      'disbursal_title': 'त्वरित राशि हस्तांतरण',
      'transferring_funds':
          'आपके बैंक खाते में राशि स्थानांतरित की जा रही है...',
      'loan_disbursed_celebration': 'ऋण सफलतापूर्वक जमा किया गया! 🎉',
      'funds_credited_msg': 'राशि सीधे आपके बैंक खाते में जमा कर दी गई है।',

      // Active Loan & Servicing
      'active_loan_details': 'सक्रिय ऋण विवरण',
      'loan_disbursed': 'ऋण स्वीकृत और जमा',
      'net_disbursed_amount': 'कुल जमा राशि (Net Disbursed)',
      'pay_now': 'अभी भुगतान करें',
      'view_rps': 'भुगतान अनुसूची (RPS) देखें',
      'utr_reference': 'यूटीआर (UTR) संख्या',
      'destination_bank': 'प्राप्तकर्ता बैंक',
      'refer_earn': 'रेफर करें और ₹250 कमाएं 🎁',
      'refer_earn_sub': 'दोस्तों को आमंत्रित करें और तुरंत UPI कैशबैक पाएं।',
      'invite': 'आमंत्रित करें',
      'my_profile': 'मेरी प्रोफ़ाइल एवं सेटिंग्स',
      'app_language': 'ऐप की भाषा (Language)',
      'english': 'English',
      'hindi': 'हिंदी (Hindi)',
      'sign_out': 'अकाउंट से साइन आउट करें',
      'notifications': 'सूचनाएं (Notifications)',
      'mark_all_read': 'सभी को पढ़ा हुआ चिन्हित करें',
      'all': 'सभी',
      'loans': 'ऋण (Loans)',
      'emi_due': 'ईएमआई देय',
      'offers': 'ऑफ़र (Offers)',
      'system': 'सिस्टम',
      'clear_all': 'सभी सूचनाएं हटाएं',
      'repayment_schedule': 'पुनर्भुगतान अनुसूची (RPS)',
      'fixed_emi_amount': 'निश्चित ईएमआई राशि',
      'proceed_payment': 'त्वरित भुगतान के लिए आगे बढ़ें',
      'pay_emi': 'ईएमआई का भुगतान करें',
      'loan_details': 'ऋण विवरण',
      'installment': 'किश्त (Installment)',
      'due_date': 'देय तिथि (Due Date)',
      'status': 'स्थिति',
      'amount': 'राशि',
      'lender': 'ऋण प्रदाता बैंक/NBFC',
      'interest_rate': 'ब्याज दर',
      'tenure': 'अवधि (Tenure)',
      'total_repayable': 'कुल देय राशि',

      // Validation & Error Messages
      'req_field': '{field} आवश्यक है',
      'invalid_mobile': 'वैध 10 अंकों का मोबाइल नंबर दर्ज करें',
      'invalid_otp': 'वैध 6 अंकों का OTP दर्ज करें',
      'invalid_pan': 'वैध 10 अक्षरों का पैन (PAN) दर्ज करें',
      'invalid_pincode': 'वैध 6 अंकों का पिन (PIN) कोड दर्ज करें',
      'invalid_ifsc': 'वैध 11 अक्षरों का IFSC कोड दर्ज करें',
      'invalid_account': 'वैध बैंक खाता संख्या दर्ज करें',
      'acc_mismatch': 'बैंक खाता संख्या मेल नहीं खाती',

      // Additional UI & Dashboard / Loan Details (Hindi)
      'application': 'आवेदन',
      'loan_details_nav': 'ऋण विवरण',
      'active_loan_badge': '✓ सक्रिय ऋण - राशि हस्तांतरित',
      'sanctioned_amount': 'स्वीकृत ऋण राशि',
      'disbursed_loan_amount': 'हस्तांतरित ऋण राशि',
      'total_outstanding': 'कुल बकाया राशि',
      'total_paid': 'कुल भुगतान',
      'next_due_emi': 'अगली देय ईएमआई',
      'quick_actions': 'त्वरित कार्य',
      'loan_account_summary': 'ऋण खाता सारांश',
      'disbursal_bank_account': 'राशि प्राप्तकर्ता बैंक खाता',
      'repayment_history': 'पुनर्भुगतान इतिहास',
      'lan_copied': 'LAN क्लिपबोर्ड में कॉपी हो गया',
      'pending_confirmation': 'पुष्टि प्रक्रियाधीन',
      'syncing_details': 'बैंक के साथ ऋण विवरण सिंक हो रहा है',
      'no_dues_pending': 'कोई बकाया लंबित नहीं',
      'on_schedule': 'समय पर',
      'statement_sync_progress': '⏳ स्टेटमेंट सिंक जारी है',
      'refresh_details': 'विवरण रिफ्रेश करें',
      'emi_amount': 'ईएमआई राशि',
      'bank_name': 'बैंक का नाम',
      'account_holder': 'खाताधारक',
      'repayment_frequency': 'पुनर्भुगतान आवृत्ति',
      'all_caught_up': 'सब कुछ अद्यतन है! 🎉',
      'no_new_notifications': 'आपके पास अभी कोई नई सूचनाएं नहीं हैं।',

      // Additional Dashboard keys (Hindi)
      'statement_sync_in_progress': '⏳ स्टेटमेंट सिंक जारी है',
      'statement_sync_desc':
          'अंतिम RPS अनुसूची और UTR संदर्भ विवरण अपडेट किए जा रहे हैं।',
      'refresh_disbursal_details': 'विवरण रिफ्रेश करें',
      'repayment_schedule_for': 'पुनर्भुगतान अनुसूची',
      'rps_populated_utr_synced': 'अंतिम UTR विवरण सिंक होते ही दिखाया जाएगा।',
      'repayment_schedule_populated_lender':
          'पुनर्भुगतान अनुसूची बैंक द्वारा ऋण विवरण की पुष्टि होते ही दिखाई जाएगी।',
      'loan_account_no': 'ऋण खाता संख्या (LAN)',
      'application_no': 'आवेदन संख्या',
      'loan_overview': 'ऋण अवलोकन',
      'loan_journey': 'ऋण यात्रा',
      'review_approved_loan_offer': 'स्वीकृत ऋण प्रस्ताव की समीक्षा करें',
      'complete_digilocker_kyc': 'डिजीलॉकर KYC पूरा करें',
      'confirm_residence_address': 'निवास पता की पुष्टि करें',
      'verify_bank_account': 'बैंक खाता सत्यापित करें',
      'review_accept_kfs': 'KFS की समीक्षा और स्वीकृति',
      'register_enach_mandate': 'ई-नाच जनादेश पंजीकृत करें',
      'complete_agreement_esign': 'समझौता ई-साइन पूरा करें',
      'view_disbursal_status': 'हस्तांतरण स्थिति देखें',
      'check_application_status': 'आवेदन स्थिति जांचें',
      'continue_loan_application': 'ऋण आवेदन जारी रखें',
      'start_application': 'आवेदन शुरू करें',

      // Dashboard - Hero Banner
      'hero_title': 'अपने वित्तीय\nलक्ष्यों को साकार करें',
      'hero_subtitle': 'त्वरित। पारदर्शी। विश्वसनीय।',

      // Dashboard - KPI Stats
      'view_all': 'सभी देखें',
      'approved': 'स्वीकृत',
      'active_loan': 'सक्रिय ऋण',

      // Dashboard - Segmented Tabs
      'application_tab': 'आवेदन',

      // Dashboard - Post-Approval Tab
      'approved_loan': 'स्वीकृत ऋण',
      'pending_confirmation_label': 'पुष्टि प्रतीक्षाधीन',
      'monthly_emi': 'मासिक ईएमआई',
      'to_be_confirmed': 'पुष्टि होना बाकी है',
      'your_next_step': 'आपका अगला कदम',
      'complete_step_disbursal':
          'राशि हस्तांतरण के करीब पहुँचने के लिए यह चरण पूरा करें।',
      'loan_journey_progress': 'ऋण यात्रा ({completed} में से {total} पूर्ण)',
      'verify_bank_step': 'बैंक खाता सत्यापित करें',
      'verify_bank_step_sub':
          'हस्तांतरण खाते के लिए पैसा-ड्रॉप सत्यापन पूरा करें',
      'accept_kfs_step': 'मुख्य तथ्य विवरण स्वीकार करें',
      'accept_kfs_step_sub':
          'ब्याज, शुल्क और पुनर्भुगतान शर्तों की समीक्षा करें',
      'register_mandate_step': 'ई-नाच जनादेश पंजीकृत करें',
      'register_mandate_step_sub':
          'बैंक खाते से स्वचालित ईएमआई पुनर्भुगतान सेट करें',
      'esign_step': 'ई-साइन ऋण समझौता',
      'esign_step_sub': 'RBI अनुपालन ऋण दस्तावेज़ पर डिजिटल हस्ताक्षर करें',
      'disbursal_step': 'राशि हस्तांतरण',
      'disbursal_step_sub': 'बैंक खाते में सीधे धनराशि हस्तांतरण ट्रैक करें',

      // Dashboard - Crediting Soon Card
      'loan_credited_shortly': 'आपका ऋण शीघ्र ही जमा किया जाएगा!',
      'disbursal_processing': 'बैंक द्वारा राशि हस्तांतरण प्रक्रियाधीन है।',
      'view_loan_details': 'ऋण विवरण देखें',

      // Dashboard - Disbursed Card
      'active_disbursed_loan': 'सक्रिय हस्तांतरित ऋण',
      'funds_credited_bank': 'आपके बैंक खाते में राशि जमा हो गई',
      'disbursed': 'हस्तांतरित',
      'disbursed_amount': 'हस्तांतरित राशि',
      'loan_account_lan': 'ऋण खाता (LAN)',
      'disbursal_utr': 'हस्तांतरण UTR',
      'credited_account': 'जमा खाता',
      'pay_emi_repay_loan': 'ईएमआई / ऋण भुगतान करें',
      'view_full_loan_details_rps': 'पूर्ण ऋण विवरण और RPS देखें',

      // Dashboard - My Loans Tab
      'pre_approved_repeat_loan': 'पूर्व-स्वीकृत पुनः ऋण ({multiplier}x लागू)',
      'eligible_revised_limit':
          '{amount} की संशोधित सीमा के साथ तत्काल हस्तांतरण के लिए पात्र।',
      'apply_repeat_loan': 'पुनः ऋण के लिए आवेदन करें',
      'approved_loan_amount_label': 'स्वीकृत ऋण राशि',
      'destination_bank_label': 'प्राप्तकर्ता बैंक',
      'fully_paid': 'पूर्ण भुगतान',
      'view_rps_label': 'RPS देखें',

      // Dashboard - Application Tab
      'application_dossier': 'आवेदन दस्तावेज़',
      'personal_loan_fintree': 'व्यक्तिगत ऋण • फिनट्री फाइनेंस',
      'steps_completed': '{completed} में से {total} चरण पूर्ण',
      'view_application_status': 'आवेदन स्थिति देखें',
      'apply_for_loan': 'ऋण के लिए आवेदन करें',
      'resume_application': 'आवेदन जारी रखें',
      'review_submit_application': 'समीक्षा करें और आवेदन जमा करें',
      'applicant_profile': 'आवेदक प्रोफ़ाइल',
      'applicant_name': 'आवेदक का नाम',
      'email_address': 'ईमेल पता',
      'employer_business': 'नियोक्ता / व्यवसाय',
      'monthly_net_income': 'मासिक शुद्ध आय',
      'not_provided': 'उपलब्ध नहीं',
      'residence_pincode': 'निवास पिन कोड',
      'application_journey': 'आवेदन यात्रा',

      // Application Steps
      'step_basic_details': 'मूल व्यक्तिगत विवरण',
      'step_basic_details_sub': 'नाम, जन्म तिथि, लिंग और पिनकोड',
      'step_pan_verification': 'पैन (PAN) सत्यापन',
      'step_pan_verification_sub': 'अपना स्थायी खाता संख्या सत्यापित करें',
      'step_lender_assessment': 'ऋणदाता और मूल्यांकन शुल्क',
      'step_lender_assessment_sub': 'आवंटित ऋणदाता और प्रसंस्करण शुल्क भुगतान',
      'step_profile_income': 'प्रोफ़ाइल और आय',
      'step_profile_income_sub': 'रोजगार, आय और संगठन विवरण',
      'step_live_photo': 'लाइव फोटो',
      'step_live_photo_sub': 'सेल्फी और लाइवनेस सत्यापन',
      'step_digilocker': 'डिजीलॉकर आधार KYC',
      'step_digilocker_sub': 'डिजीलॉकर के माध्यम से सुरक्षित आधार सत्यापन',
      'step_address': 'पता पुष्टि',
      'step_address_sub': 'अपने निवास पते की समीक्षा और पुष्टि करें',
      'step_aa': 'अकाउंट एग्रीगेटर सत्यापन',
      'step_aa_sub': 'स्टेटमेंट विश्लेषण के लिए बैंक खाता कनेक्ट करें',
      'step_loan_offer': 'ऋण प्रस्ताव चयन',
      'step_loan_offer_sub':
          'ऋण अवधि चुनें और स्वीकृत मूल्य निर्धारण की समीक्षा करें',
      'step_review_submit': 'समीक्षा और जमा करें',
      'step_review_submit_sub':
          'ऋणदाता को जमा करने से पहले आवेदन की पुष्टि करें',

      // Dashboard - Promo Card
      'need_personal_loan': 'व्यक्तिगत ऋण चाहिए?',
      'get_instant_offers':
          'न्यूनतम दस्तावेज़ों के साथ कई ऋणदाताओं से तत्काल ऑफर प्राप्त करें।',
      'apply_now': 'अभी आवेदन करें',

      // Dashboard - Smart Credit Perks
      'smart_credit_benefits': 'स्मार्ट क्रेडिट लाभ',
      'exclusive_perks': 'आपकी प्रोफ़ाइल के लिए विशेष लाभ और स्वीकृति तत्परता',
      'high_odds': '98% उच्च संभावना',
      'approval_readiness': 'स्वीकृति तत्परता: उत्कृष्ट',
      'pre_verified_instant': 'तत्काल ऋण हस्तांतरण के लिए पूर्व-सत्यापित',
      'instant_disbursal': 'तत्काल 30 सेकंड हस्तांतरण',
      'direct_transfer_esign': 'ई-साइन के बाद सीधा हस्तांतरण',
      'zero_foreclosure': 'शून्य पूर्व-भुगतान शुल्क',
      'pay_off_anytime': 'कभी भी 0% पेनल्टी के साथ भुगतान करें',
      'tier_multiplier': 'टियर मल्टीप्लायर',
      'higher_limits_emi': 'समय पर ईएमआई से उच्च सीमा',
      'digital_kyc': '100% डिजिटल KYC',
      'paperless_digilocker': 'डिजीलॉकर और AA द्वारा पेपरलेस',
      'questions_credit_perks': 'क्रेडिट लाभों के बारे में प्रश्न हैं?',
      'support_label': 'सहायता',

      // Dashboard - Logout Modal
      'logout_title': 'अपने खाते से लॉगआउट करें?',
      'logout_message':
          'अपनी ऋण यात्रा तक पहुंचने के लिए आपको अपना मोबाइल नंबर फिर से सत्यापित करना होगा।',
      'logout': 'लॉगआउट',

      // Dashboard - Profile Modal
      'verified_badge': '✓ सत्यापित',
      'profile_score': 'प्रोफ़ाइल स्कोर',
      'profile_verified': '100% सत्यापित',
      'kyc_status_label': 'KYC स्थिति',
      'digilocker_ok': 'डिजीलॉकर ओके',
      'lender_tier': 'ऋणदाता श्रेणी',
      'prime_match': 'प्राइम मैच',
      'identity_kyc_details': 'पहचान और KYC विवरण',
      'full_name': 'पूरा नाम',
      'pan_card_number': 'पैन कार्ड नंबर',
      'aadhaar_kyc': 'आधार KYC',
      'digilocker_linked': 'डिजीलॉकर लिंक्ड',
      'employment_financials': 'रोजगार और वित्तीय विवरण',
      'designation': 'पदनाम',
      'residence_bank_details': 'निवास और बैंक विवरण',
      'residence_status': 'निवास स्थिति',
      'residential_pincode': 'निवास पिन कोड',
      'disbursal_bank': 'हस्तांतरण बैंक',
      'primary_account': 'प्राथमिक खाता',
      'linked_account': 'लिंक्ड खाता',

      // Dashboard - Help & Support
      'help_support': 'सहायता और समर्थन',
      'faqs': 'सामान्य प्रश्न',
      'faqs_sub': 'सामान्य प्रश्नों के उत्तर पाएं',
      'call_support': 'कॉल सहायता',
      'email_support': 'ईमेल सहायता',

      // Verification Status
      'verified': 'सत्यापित',
      'pending': 'प्रतीक्षाधीन',
      'mobile': 'मोबाइल',
    },
  };

  String translate(String key, [Map<String, dynamic>? params]) {
    String value = _localizedValues[languageCode]?[key] ??
        _localizedValues['en']?[key] ??
        key;

    if (params != null && params.isNotEmpty) {
      params.forEach((paramKey, paramValue) {
        value = value.replaceAll('{$paramKey}', paramValue.toString());
      });
    }

    return value;
  }

  String tr(String key, [Map<String, dynamic>? params]) =>
      translate(key, params);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'hi'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale.languageCode);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
