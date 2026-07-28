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
  final String lan;

  const AddressScreen({super.key, required this.lan});

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
      await apiClient.patch(
        '/customer/loans/${widget.lan}/address',
        data: {
          'customerId': customerId,
          'sameAsPermanent': _sameAsPermanent,
          'currentAddrLine1': _sameAsPermanent ? null : _line1Controller.text.trim(),
          'currentAddrLine2': _sameAsPermanent ? null : _line2Controller.text.trim(),
          'currentAddrPincode': _sameAsPermanent ? null : _pincodeController.text.trim(),
          'currentAddrCity': _sameAsPermanent ? null : _cityController.text.trim(),
          'currentAddrState': _sameAsPermanent ? null : _stateController.text.trim(),
        },
      );

      await ref.read(journeyControllerProvider.notifier).syncCustomerState();

      if (mounted) {
        context.push('/loan/${widget.lan}/bank');
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
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.home_outlined, color: AppTheme.primaryTeal),
                            SizedBox(width: 8),
                            Text('Permanent Address (Aadhaar Verified)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                        Divider(height: 20),
                        Text(
                          '123, Green Avenue, MG Road, Sector 14, New Delhi - 110001, India',
                          style: TextStyle(fontSize: 13, color: AppTheme.textDarkPrimary, height: 1.4),
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
