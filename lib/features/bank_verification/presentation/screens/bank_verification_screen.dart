import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../dashboard/presentation/journey_controller.dart';

class BankVerificationScreen extends ConsumerStatefulWidget {
  final String lan;

  const BankVerificationScreen({super.key, required this.lan});

  @override
  ConsumerState<BankVerificationScreen> createState() => _BankVerificationScreenState();
}

class _BankVerificationScreenState extends ConsumerState<BankVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _holderNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _confirmAccountController = TextEditingController();
  final _ifscController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _branchNameController = TextEditingController();
  String _accountType = 'SAVINGS';

  bool _isVerifying = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final customer = ref.read(journeyControllerProvider).customer;
    if (customer?.fullName != null) {
      _holderNameController.text = customer!.fullName!;
    }
  }

  @override
  void dispose() {
    _holderNameController.dispose();
    _accountNumberController.dispose();
    _confirmAccountController.dispose();
    _ifscController.dispose();
    _bankNameController.dispose();
    _branchNameController.dispose();
    super.dispose();
  }

  void _verifyBank() async {
    if (!_formKey.currentState!.validate()) return;
    final customerId = ref.read(journeyControllerProvider).customer?.id;
    if (customerId == null) return;

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.post(
        '/customer/loans/${widget.lan}/bank-accounts/verify',
        data: {
          'customerId': customerId,
          'accountHolderName': _holderNameController.text.trim(),
          'accountNumber': _accountNumberController.text.trim(),
          'confirmAccountNumber': _confirmAccountController.text.trim(),
          'ifscCode': _ifscController.text.trim().toUpperCase(),
          'bankName': _bankNameController.text.trim().isNotEmpty ? _bankNameController.text.trim() : 'HDFC Bank',
          'branchName': _branchNameController.text.trim().isNotEmpty ? _branchNameController.text.trim() : 'Main Branch',
          'accountType': _accountType,
        },
      );

      await ref.read(journeyControllerProvider.notifier).syncCustomerState();

      if (mounted) {
        context.push('/loan/${widget.lan}/kfs');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bank = ref.watch(journeyControllerProvider).postApproval?.bank;
    final isVerified = bank?.verified == true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bank Account Verification'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                const Text(
                  'Bank Penny-Drop Verification',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textDarkPrimary),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Enter bank details for loan disbursal & penny-drop verification.',
                  style: TextStyle(fontSize: 14, color: AppTheme.textDarkSecondary),
                ),
                const SizedBox(height: 24),
                if (isVerified) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Bank Account Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              AppStatusBadge(status: 'VERIFIED', label: 'Penny-Drop Verified'),
                            ],
                          ),
                          const Divider(height: 20),
                          _row('Account Holder', bank?.accountHolderName ?? 'N/A'),
                          _row('Bank Name', bank?.bankName ?? 'HDFC Bank'),
                          _row('IFSC Code', bank?.ifsc ?? 'N/A'),
                          _row('Account Number', Formatters.maskBankAccount(bank?.accountMasked ?? _accountNumberController.text)),
                          _row('Account Type', bank?.accountType ?? 'SAVINGS'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  AppButton(
                    text: 'Proceed to Key Fact Statement (KFS)',
                    onPressed: () => context.push('/loan/${widget.lan}/kfs'),
                    icon: Icons.arrow_forward_rounded,
                  ),
                ] else ...[
                  AppTextField(
                    label: 'Account Holder Name (As in Bank)',
                    hint: 'Full Name',
                    controller: _holderNameController,
                    validator: (v) => Validators.validateRequired(v, 'Account holder name'),
                    prefix: const Icon(Icons.person_outline, size: 20),
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Account Number',
                    hint: '9 to 20 digit account number',
                    controller: _accountNumberController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    validator: Validators.validateAccountNumber,
                    prefix: const Icon(Icons.account_balance_outlined, size: 20),
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Confirm Account Number',
                    hint: 'Re-enter account number',
                    controller: _confirmAccountController,
                    keyboardType: TextInputType.number,
                    validator: (v) => Validators.validateConfirmAccountNumber(_accountNumberController.text, v),
                    prefix: const Icon(Icons.lock_outline, size: 20),
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'IFSC Code',
                    hint: 'HDFC0001234',
                    controller: _ifscController,
                    textCapitalization: TextCapitalization.characters,
                    validator: Validators.validateIfsc,
                    prefix: const Icon(Icons.code_rounded, size: 20),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          label: 'Bank Name',
                          hint: 'e.g. HDFC Bank',
                          controller: _bankNameController,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppTextField(
                          label: 'Branch Name',
                          hint: 'Branch',
                          controller: _branchNameController,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Account Type', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _accountType,
                    decoration: const InputDecoration(),
                    items: const [
                      DropdownMenuItem(value: 'SAVINGS', child: Text('Savings Account')),
                      DropdownMenuItem(value: 'CURRENT', child: Text('Current Account')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _accountType = val);
                    },
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.errorBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(_errorMessage!, style: const TextStyle(color: AppTheme.errorRed, fontSize: 13)),
                    ),
                  ],
                  const SizedBox(height: 32),
                  AppButton(
                    text: 'Verify Bank Account (Penny Drop)',
                    isLoading: _isVerifying,
                    onPressed: _verifyBank,
                    icon: Icons.check_circle_outline,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String val) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textDarkSecondary)),
          Text(val, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textDarkPrimary)),
        ],
      ),
    );
  }
}
