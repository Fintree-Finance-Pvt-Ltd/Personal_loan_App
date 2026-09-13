import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../../core/api/api_exception.dart';
import '../../../../app/theme.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_stepper.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_header.dart';
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
      String msg = e.toString();
      if (e is DioException) {
        final apiClient = ref.read(apiClientProvider);
        msg = apiClient.handleError(e).message;
      } else if (e is AppException) {
        msg = e.message;
      } else if (msg.startsWith('Exception: ')) {
        msg = msg.substring(11);
      }
      setState(() {
        _errorMessage = msg;
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
      appBar: const AppHeader(
        title: 'Profile & Employment',
        fallbackRoute: '/payment/processing-fee',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppStepper(
                  currentStep: 4,
                  totalSteps: 7,
                  stepTitles: ['PAN Verification', 'Personal Details', 'Assessment Fee', 'Profile & Income', 'Photo & Liveness', 'DigiLocker KYC', 'Account Aggregator'],
                ),
                const SizedBox(height: 20),

                // Hero Illustration Banner Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF073B2E),
                        Color(0xFF0F5A47),
                        Color(0xFF136E57),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F5A47).withValues(alpha: 0.2),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF34D399).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFF34D399), width: 0.8),
                              ),
                              child: const Text(
                                '✓ STEP 4 OF 7',
                                style: TextStyle(
                                  color: Color(0xFF6EE7B7),
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Employment & Financial Profile',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tell us about your work and income to verify your pre-approved limit.',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Colors.white.withValues(alpha: 0.8),
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      SvgPicture.asset(
                        'lib/assets/images/illustrations/Personal settings-pana.svg',
                        height: 95,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Card 1: Residence & Employment Type
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.home_work_rounded, color: Color(0xFF0F5A47), size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Residence & Employment Type',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                      const Divider(height: 20, color: Color(0xFFF1F5F9)),
                      const Text('Residence Type', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: _residenceStatus,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'OWNED', child: Text('Owned by Self / Parents')),
                          DropdownMenuItem(value: 'RENTED', child: Text('Rented Apartment / Flat')),
                          DropdownMenuItem(value: 'FAMILY_OWNED', child: Text('Family Owned House')),
                          DropdownMenuItem(value: 'COMPANY_PROVIDED', child: Text('Company Quarters / Provided')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _residenceStatus = val);
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text('Employment Type', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<String>(
                          style: SegmentedButton.styleFrom(
                            selectedBackgroundColor: const Color(0xFF0F5A47),
                            selectedForegroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          segments: const [
                            ButtonSegment(value: 'SALARIED', label: Text('Salaried Employee'), icon: Icon(Icons.work_rounded, size: 16)),
                            ButtonSegment(value: 'SELF_EMPLOYED', label: Text('Self-Employed'), icon: Icon(Icons.storefront_rounded, size: 16)),
                          ],
                          selected: {_employmentType},
                          onSelectionChanged: (set) {
                            setState(() => _employmentType = set.first);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Card 2: Financial Details & Income
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF0F5A47), size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Financial & Income Information',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                      const Divider(height: 20, color: Color(0xFFF1F5F9)),
                      AppTextField(
                        label: 'Monthly Net Take-Home Income (₹)',
                        hint: 'e.g. 55000',
                        controller: _monthlyIncomeController,
                        keyboardType: TextInputType.number,
                        validator: (v) => Validators.validateRequired(v, 'Monthly income'),
                        prefix: const Icon(Icons.currency_rupee_rounded, size: 18, color: Color(0xFF0F5A47)),
                      ),
                      const SizedBox(height: 10),

                      // Quick Selection Income Chips
                      const Text(
                        'Quick select monthly income:',
                        style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: ['35000', '50000', '75000', '100000', '150000'].map((amt) {
                          final isSelected = _monthlyIncomeController.text == amt;
                          return ChoiceChip(
                            label: Text('₹${int.parse(amt) ~/ 1000}k'),
                            selected: isSelected,
                            selectedColor: const Color(0xFF0F5A47),
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : const Color(0xFF334155),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            onSelected: (_) {
                              setState(() {
                                _monthlyIncomeController.text = amt;
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Card 3: Employer or Business Details
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(isSalaried ? Icons.business_rounded : Icons.store_rounded, color: const Color(0xFF0F5A47), size: 18),
                          const SizedBox(width: 8),
                          Text(
                            isSalaried ? 'Employer & Company Details' : 'Business & Business Details',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                      const Divider(height: 20, color: Color(0xFFF1F5F9)),
                      if (isSalaried) ...[
                        const Text('Company Category', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: _companyType,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'PRIVATE_LIMITED', child: Text('Private Limited Company')),
                            DropdownMenuItem(value: 'PUBLIC_LIMITED', child: Text('Public Limited / Listed')),
                            DropdownMenuItem(value: 'GOVERNMENT', child: Text('Government / PSU Sector')),
                            DropdownMenuItem(value: 'PARTNERSHIP', child: Text('Partnership / LLP Firm')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _companyType = val);
                          },
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          label: 'Employer / Company Name',
                          hint: 'Official Company Name',
                          controller: _companyNameController,
                          validator: (v) => Validators.validateRequired(v, 'Company name'),
                          prefix: const Icon(Icons.apartment_rounded, size: 18, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          label: 'Designation / Job Title',
                          hint: 'e.g. Senior Software Engineer',
                          controller: _designationController,
                          validator: (v) => Validators.validateRequired(v, 'Designation'),
                          prefix: const Icon(Icons.badge_rounded, size: 18, color: Color(0xFF64748B)),
                        ),
                      ] else ...[
                        AppTextField(
                          label: 'Business / Firm Name',
                          hint: 'Official Firm Name',
                          controller: _businessNameController,
                          validator: (v) => Validators.validateRequired(v, 'Business name'),
                          prefix: const Icon(Icons.storefront_rounded, size: 18, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          label: 'Annual Business Turnover (₹)',
                          hint: 'e.g. 1200000',
                          controller: _annualTurnoverController,
                          keyboardType: TextInputType.number,
                          validator: (v) => Validators.validateRequired(v, 'Annual turnover'),
                          prefix: const Icon(Icons.currency_rupee_rounded, size: 18, color: Color(0xFF64748B)),
                        ),
                      ],
                    ],
                  ),
                ),

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
