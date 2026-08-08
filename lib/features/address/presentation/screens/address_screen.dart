import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../dashboard/presentation/journey_controller.dart';

class AddressScreen extends ConsumerStatefulWidget {
  final String? lan;

  const AddressScreen({super.key, this.lan});

  @override
  ConsumerState<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends ConsumerState<AddressScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _sameAsPermanent = true;

  final _line1Controller = TextEditingController();
  final _line2Controller = TextEditingController();
  final _pincodeController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();

  bool _isSaving = false;
  String? _errorMessage;
  String? _aadhaarAddress;
  bool _isLoadingAddress = false;

  @override
  void initState() {
    super.initState();
    _fetchAadhaarAddress();
  }

  void _fetchAadhaarAddress() async {
    setState(() {
      _isLoadingAddress = true;
      _errorMessage = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      final res = await apiClient.get('/customer/aadhaar-kyc/digilocker/status');
      
      Map<String, dynamic> innerData = {};
      if (res['data'] is Map) {
        final d1 = res['data'];
        if (d1['data'] is Map) {
          innerData = Map<String, dynamic>.from(d1['data']);
        } else {
          innerData = Map<String, dynamic>.from(d1);
        }
      } else {
        innerData = Map<String, dynamic>.from(res);
      }

      final permanentAddress = innerData['permanentAddress'];
      if (permanentAddress != null) {
        setState(() {
          _aadhaarAddress = permanentAddress['formattedAddress'];
        });
      }
    } catch (e) {
      // Ignored
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAddress = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _line1Controller.dispose();
    _line2Controller.dispose();
    _pincodeController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  void _saveAddress() async {
    if (!_sameAsPermanent && !_formKey.currentState!.validate()) return;
    final customerId = ref.read(journeyControllerProvider).customer?.id;
    if (customerId == null) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);

      if (_sameAsPermanent) {
        await apiClient.patch(
          '/customer/application/address',
          data: {
            'addressType': 'CURRENT',
            'sameAsPermanent': true,
          },
        );
      } else {
        await apiClient.patch(
          '/customer/application/address',
          data: {
            'addressType': 'CURRENT',
            'sameAsPermanent': false,
            'addressLine1': _line1Controller.text.trim(),
            'addressLine2': _line2Controller.text.trim(),
            'pincode': _pincodeController.text.trim(),
            'city': _cityController.text.trim(),
            'state': _stateController.text.trim(),
          },
        );
      }

      await ref.read(journeyControllerProvider.notifier).syncCustomerState();

      if (mounted) {
        context.push('/onboarding/review');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Address Confirmation'),
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
                  'Address Details',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textDarkPrimary),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Confirm your permanent Aadhaar address and current residence.',
                  style: TextStyle(fontSize: 14, color: AppTheme.textDarkSecondary),
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.home_outlined, color: AppTheme.primaryTeal),
                            SizedBox(width: 8),
                            Text('Permanent Address (Aadhaar Verified)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                        const Divider(height: 20),
                        if (_isLoadingAddress)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        else
                          Text(
                            _aadhaarAddress ?? 'Address details missing from Aadhaar profile.',
                            style: const TextStyle(fontSize: 13, color: AppTheme.textDarkPrimary, height: 1.4),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Checkbox(
                      value: _sameAsPermanent,
                      activeColor: AppTheme.primaryTeal,
                      onChanged: (val) {
                        setState(() {
                          _sameAsPermanent = val == true;
                        });
                      },
                    ),
                    const Expanded(
                      child: Text(
                        'My current residential address is the same as permanent Aadhaar address',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
                if (!_sameAsPermanent) ...[
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Current Address Line 1',
                    hint: 'Flat, House No, Building',
                    controller: _line1Controller,
                    validator: (v) => Validators.validateRequired(v, 'Address Line 1'),
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'Current Address Line 2',
                    hint: 'Street, Sector, Locality',
                    controller: _line2Controller,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'PIN Code',
                    hint: '6-digit PIN code',
                    controller: _pincodeController,
                    keyboardType: TextInputType.number,
                    validator: Validators.validatePincode,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          label: 'City',
                          hint: 'City',
                          controller: _cityController,
                          validator: (v) => Validators.validateRequired(v, 'City'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppTextField(
                          label: 'State',
                          hint: 'State',
                          controller: _stateController,
                          validator: (v) => Validators.validateRequired(v, 'State'),
                        ),
                      ),
                    ],
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
                    child: Text(_errorMessage!, style: const TextStyle(color: AppTheme.errorRed, fontSize: 13)),
                  ),
                ],
                const SizedBox(height: 32),
                AppButton(
                  text: 'Confirm Address & Continue',
                  isLoading: _isSaving,
                  onPressed: _saveAddress,
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
