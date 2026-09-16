import re

filepath = "lib/features/dashboard/presentation/screens/dashboard_screen.dart"
with open(filepath, "r", encoding="utf-8") as f:
    content = f.read()

replacements = {
    "'Loan Overview'": "ref.watch(appLocalizationsProvider).tr('loan_overview')",
    "'Loan Journey'": "ref.watch(appLocalizationsProvider).tr('loan_journey')",
    "'Active Loan Details'": "ref.watch(appLocalizationsProvider).tr('active_loan_details')",
    "'Review Approved Loan Offer'": "ref.watch(appLocalizationsProvider).tr('review_approved_loan_offer')",
    "'Complete DigiLocker KYC'": "ref.watch(appLocalizationsProvider).tr('complete_digilocker_kyc')",
    "'Confirm Residence Address'": "ref.watch(appLocalizationsProvider).tr('confirm_residence_address')",
    "'Verify Bank Account'": "ref.watch(appLocalizationsProvider).tr('verify_bank_account')",
    "'Review & Accept KFS'": "ref.watch(appLocalizationsProvider).tr('review_accept_kfs')",
    "'Register e-NACH Mandate'": "ref.watch(appLocalizationsProvider).tr('register_enach_mandate')",
    "'Complete Agreement e-Sign'": "ref.watch(appLocalizationsProvider).tr('complete_agreement_esign')",
    "'View Disbursal Status'": "ref.watch(appLocalizationsProvider).tr('view_disbursal_status')",
    "'Check Application Status'": "ref.watch(appLocalizationsProvider).tr('check_application_status')",
    "'Continue Loan Application'": "ref.watch(appLocalizationsProvider).tr('continue_loan_application')",
    "'Start Application'": "ref.watch(appLocalizationsProvider).tr('start_application')"
}

for old, new in replacements.items():
    content = content.replace(old, new)

with open(filepath, "w", encoding="utf-8") as f:
    f.write(content)
