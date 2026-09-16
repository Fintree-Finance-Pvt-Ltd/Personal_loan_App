import sys

with open("lib/core/localization/app_localizations.dart", "r", encoding="utf-8") as f:
    lines = f.readlines()

# Find where 'hi': { starts after 'en': {
hi_start = -1
for i, line in enumerate(lines):
    if "'hi': {" in line:
        hi_start = i
        break

if hi_start != -1:
    # Delete everything from hi_start to the end of _localizedValues
    # _localizedValues ends when we see "  String translate(String key"
    translate_start = -1
    for i in range(hi_start, len(lines)):
        if "String translate(String key" in lines[i]:
            translate_start = i
            break
    
    if translate_start != -1:
        new_hi_block = """    'hi': {
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
      'login_subtitle': 'हम आपके खाते को सत्यापित करने के लिए 6 अंकों का OTP भेजेंगे।',
      'mobile_number': 'मोबाइल नंबर',
      'get_otp': 'OTP प्राप्त करें',
      'terms_disclaimer': 'आगे बढ़कर, आप हमारी सेवा की शर्तों और गोपनीयता नीति से सहमत होते हैं।',
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
      'live_photo_sub': 'सुनिश्चित करें कि प्रकाश अच्छा हो और आपका चेहरा घेरे में स्पष्ट दिखे।',
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
      'aa_sub': 'आरबीआई अकाउंट एग्रीगेटर के जरिए 6 महीने का बैंक विवरण सुरक्षित रूप से प्राप्त करें।',
      'fetch_statement': 'स्टेटमेंट प्राप्त करें',

      // Application Review & Status
      'review_application_title': 'ऋण आवेदन की समीक्षा',
      'declaration_text': 'मैं घोषणा करता/करती हूं कि प्रस्तुत सभी जानकारी सटीक एवं सत्य है।',
      'submit_application': 'आवेदन जमा करें',
      'underwriting_title': 'आवेदन जमा किया गया एवं ऋण समीक्षा जारी है',
      'underwriting_sub': 'हमारा स्वचालित मूल्यांकन इंजन आपके ऋण प्रस्ताव का सत्यापन कर रहा है।',
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
      'transferring_funds': 'आपके बैंक खाते में राशि स्थानांतरित की जा रही है...',
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
    },
  };
"""
        
        new_lines = lines[:hi_start] + [new_hi_block + "\n\n"] + lines[translate_start:]
        with open("lib/core/localization/app_localizations.dart", "w", encoding="utf-8") as f:
            f.writelines(new_lines)
