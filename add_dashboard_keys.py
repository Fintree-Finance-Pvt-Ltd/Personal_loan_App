import re

new_en = {
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
    'start_application': 'Start Application'
}

new_hi = {
    'loan_overview': 'ऋण सारांश',
    'loan_journey': 'ऋण यात्रा',
    'review_approved_loan_offer': 'स्वीकृत ऋण प्रस्ताव की समीक्षा करें',
    'complete_digilocker_kyc': 'डिजीलॉकर केवाईसी पूरा करें',
    'confirm_residence_address': 'निवास स्थान की पुष्टि करें',
    'verify_bank_account': 'बैंक खाता सत्यापित करें',
    'review_accept_kfs': 'KFS की समीक्षा और स्वीकार करें',
    'register_enach_mandate': 'ई-नाच जनादेश पंजीकृत करें',
    'complete_agreement_esign': 'ई-हस्ताक्षर समझौता पूरा करें',
    'view_disbursal_status': 'वितरण स्थिति देखें',
    'check_application_status': 'आवेदन की स्थिति जांचें',
    'continue_loan_application': 'ऋण आवेदन जारी रखें',
    'start_application': 'आवेदन शुरू करें'
}

with open("lib/core/localization/app_localizations.dart", "r", encoding="utf-8") as f:
    content = f.read()

# Insert into 'en'
en_insert_idx = content.find("    },\n    'hi': {")
if en_insert_idx != -1:
    en_str = ""
    for k, v in new_en.items():
        if f"'{k}':" not in content:
            en_str += f"      '{k}': '{v}',\n"
    content = content[:en_insert_idx] + en_str + content[en_insert_idx:]

# Insert into 'hi'
hi_insert_idx = content.find("    },\n  };\n\n  String translate")
if hi_insert_idx != -1:
    hi_str = ""
    for k, v in new_hi.items():
        if f"'{k}':" not in content[en_insert_idx:]:
            hi_str += f"      '{k}': '{v}',\n"
    content = content[:hi_insert_idx] + hi_str + content[hi_insert_idx:]

with open("lib/core/localization/app_localizations.dart", "w", encoding="utf-8") as f:
    f.write(content)
