import re

new_en = {
    'statement_sync_in_progress': 'STATEMENT SYNC IN PROGRESS',
    'sanctioned_amount': 'Sanctioned Amount',
    'pending_confirmation': 'Pending Confirmation',
    'statement_sync_desc': 'Final RPS schedule & UTR reference statement are being updated.',
    'refresh_disbursal_details': 'Refresh Disbursal Details',
    'repayment_schedule_for': 'Repayment schedule for',
    'rps_populated_utr_synced': 'will be populated as soon as final UTR statement is synced.',
    'repayment_schedule_populated_lender': 'Repayment schedule will be populated as soon as loan details are confirmed by lender.',
    'loan_account_no': 'Loan Account No. (LAN)',
    'application_no': 'Application No.'
}

new_hi = {
    'statement_sync_in_progress': 'स्टेटमेंट सिंक जारी है',
    'sanctioned_amount': 'स्वीकृत राशि',
    'pending_confirmation': 'पुष्टि लंबित',
    'statement_sync_desc': 'अंतिम RPS अनुसूची और UTR संदर्भ अपडेट किए जा रहे हैं।',
    'refresh_disbursal_details': 'विवरण रिफ्रेश करें',
    'repayment_schedule_for': 'के लिए पुनर्भुगतान अनुसूची',
    'rps_populated_utr_synced': 'अंतिम UTR सिंक होने पर अपडेट की जाएगी।',
    'repayment_schedule_populated_lender': 'लेंडर द्वारा ऋण विवरण की पुष्टि होते ही पुनर्भुगतान अनुसूची अपडेट कर दी जाएगी।',
    'loan_account_no': 'ऋण खाता संख्या (LAN)',
    'application_no': 'आवेदन संख्या'
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
