import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_stepper.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../dashboard/presentation/journey_controller.dart';

class ProfileDetailsScreen extends ConsumerStatefulWidget {
  const ProfileDetailsScreen({super.key});

  @override
  ConsumerState<ProfileDetailsScreen> createState() => _ProfileDetailsScreenState();
}

class _ProfileDetailsScreenState extends ConsumerState<ProfileDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  String _residenceStatus = 'OWNED';
  String _employmentType = 'SALARIED';
  final _monthlyIncomeController = TextEditingController();

  // Salaried fields
  String _companyType = 'PRIVATE_LIMITED';
  final _companyNameController = TextEditingController();
  final _designationController = TextEditingController();
  final String _salaryMode = 'BANK_TRANSFER';

  // Self employed fields
  final _businessNameController = TextEditingController();
  final String _businessConstitution = 'PROPRIETORSHIP';
  final _annualTurnoverController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final customer = ref.read(journeyControllerProvider).customer;
    if (customer != null) {
      _residenceStatus = customer.residenceStatus ?? 'OWNED';
      _employmentType = customer.employmentType ?? 'SALARIED';
      if (customer.monthlyIncome != null) {
        _monthlyIncomeController.text = customer.monthlyIncome.toString();
      }
      _companyType = customer.companyType ?? 'PRIVATE_LIMITED';
      _companyNameController.text = customer.companyName ?? '';
      _designationController.text = customer.designation ?? '';
      _businessNameController.text = customer.businessName ?? '';
      if (customer.annualTurnover != null) {
        _annualTurnoverController.text = customer.annualTurnover.toString();
      }
    }
  }

  @override
  void dispose() {
    _monthlyIncomeController.dispose();
    _companyNameController.dispose();
    _designationController.dispose();
    _businessNameController.dispose();
    _annualTurnoverController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final customerId = ref.read(journeyControllerProvider).customer?.id;
      final apiClient = ref.read(apiClientProvider);

      if (customerId != null) {
        final data = {
          'residenceStatus': _residenceStatus,
          'employmentType': _employmentType,
          'monthlyIncome': _monthlyIncomeController.text.trim(),
          'kfsLanguage': 'English',
        };

        if (_employmentType == 'SALARIED') {
          data['companyType'] = _companyType;
          data['companyName'] = _companyNameController.text.trim();
          data['designation'] = _designationController.text.trim();
          data['salaryMode'] = _salaryMode;
        } else {
          data['businessName'] = _businessNameController.text.trim();
          data['businessConstitution'] = _businessConstitution;
          data['annualTurnover'] = _annualTurnoverController.text.trim();
        }

        await apiClient.patch('/customer/$customerId/profile', data: data);
        await ref.read(journeyControllerProvider.notifier).syncCustomerState();

        if (mounted) {
          context.push('/onboarding/live-photo');
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSalaried = _employmentType == 'SALARIED';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Employment'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppStepper(
                  currentStep: 3,
                  totalSteps: 5,
                  stepTitles: ['PAN Verification', 'Personal Details', 'Profile & Income', 'Photo & Liveness', 'Submit'],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Employment & Financial Profile',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDarkPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Specify your employment type and monthly income details.',
                  style: TextStyle(fontSize: 14, color: AppTheme.textDarkSecondary),
                ),
                const SizedBox(height: 24),
                const Text('Residence Type', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _residenceStatus,
                  decoration: const InputDecoration(),
                  items: const [
                    DropdownMenuItem(value: 'OWNED', child: Text('Owned by Self / Parents')),
                    DropdownMenuItem(value: 'RENTED', child: Text('Rented')),
                    DropdownMenuItem(value: 'PROVIDED_BY_EMPLOYER', child: Text('Company Provided')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _residenceStatus = val);
                  },
                ),
                const SizedBox(height: 16),
                const Text('Employment Type', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'SALARIED', label: Text('Salaried')),
                    ButtonSegment(value: 'SELF_EMPLOYED', label: Text('Self-Employed')),
                  ],
                  selected: {_employmentType},
                  onSelectionChanged: (set) {
                    setState(() => _employmentType = set.first);
                  },
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Monthly Net Income (₹)',
                  hint: 'e.g. 55000',
                  controller: _monthlyIncomeController,
                  keyboardType: TextInputType.number,
                  validator: (v) => Validators.validateRequired(v, 'Monthly income'),
                  prefix: const Icon(Icons.currency_rupee_rounded, size: 20),
                ),
                const SizedBox(height: 16),
                if (isSalaried) ...[
                  const Text('Company Category', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _companyType,
                    decoration: const InputDecoration(),
                    items: const [
                      DropdownMenuItem(value: 'PRIVATE_LIMITED', child: Text('Private Limited')),
                      DropdownMenuItem(value: 'PUBLIC_LIMITED', child: Text('Public Limited')),
                      DropdownMenuItem(value: 'GOVERNMENT', child: Text('Government / PSU')),
                      DropdownMenuItem(value: 'PARTNERSHIP', child: Text('Partnership Firm')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _companyType = val);
                    },
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Employer / Company Name',
                    hint: 'Company Name',
                    controller: _companyNameController,
                    validator: (v) => Validators.validateRequired(v, 'Company name'),
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Designation',
                    hint: 'Designation / Job Title',
                    controller: _designationController,
                    validator: (v) => Validators.validateRequired(v, 'Designation'),
                  ),
                ] else ...[
                  AppTextField(
                    label: 'Business / Firm Name',
                    hint: 'Firm Name',
                    controller: _businessNameController,
                    validator: (v) => Validators.validateRequired(v, 'Business name'),
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Annual Business Turnover (₹)',
                    hint: 'e.g. 1200000',
                    controller: _annualTurnoverController,
                    keyboardType: TextInputType.number,
                    validator: (v) => Validators.validateRequired(v, 'Annual turnover'),
                  ),
                ],
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.errorBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppTheme.errorRed, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: AppTheme.errorRed, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                AppButton(
                  text: 'Save & Continue',
                  isLoading: _isLoading,
                  onPressed: _submit,
                  icon: Icons.arrow_forward_rounded,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
