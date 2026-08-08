import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../../../../app/theme.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../../../core/widgets/app_stepper.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../dashboard/presentation/journey_controller.dart';

class PanVerificationScreen extends ConsumerStatefulWidget {
  const PanVerificationScreen({super.key});

  @override
  ConsumerState<PanVerificationScreen> createState() => _PanVerificationScreenState();
}

class _PanVerificationScreenState extends ConsumerState<PanVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _panController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _verifiedResult;
  File? _panImageFile;
  bool _isOcrLoading = false;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void dispose() {
    _panController.dispose();
    super.dispose();
  }

  Future<void> _pickPanImage(ImageSource source) async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: source,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 85,
      );

      if (photo == null) return;

      final file = File(photo.path);
      setState(() {
        _panImageFile = file;
        _errorMessage = null;
      });

      await _processPanOcr(file);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to select image: $e';
      });
    }
  }

  Future<void> _processPanOcr(File file) async {
    setState(() {
      _isOcrLoading = true;
      _errorMessage = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: 'pan_card.jpg'),
      });

      final res = await apiClient.post(
        '/external-api/pan-ocr',
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );

      final data = res['data'] ?? res;
      final extractedPan = data['panNumber'] as String?;
      if (extractedPan != null && extractedPan.isNotEmpty) {
        setState(() {
          _panController.text = extractedPan.toUpperCase();
        });
      } else {
        setState(() {
          _errorMessage = 'Could not extract PAN number. Please verify or type it manually.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'OCR extraction failed: $e. You can still enter your PAN details manually.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isOcrLoading = false;
        });
      }
    }
  }

  void _verifyPan() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final customerId = ref.read(journeyControllerProvider).customer?.id;
      final apiClient = ref.read(apiClientProvider);

      if (customerId != null) {
        final res = await apiClient.post(
          '/external-api/verify-pan',
          data: {
            'customerId': customerId,
            'panNumber': _panController.text.trim().toUpperCase(),
          },
        );

        setState(() {
          _verifiedResult = res['data'] ?? res;
        });

        await ref.read(journeyControllerProvider.notifier).syncCustomerState();
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

  void _continue() {
    context.push('/onboarding/basic-details');
  }

  @override
  Widget build(BuildContext context) {
    final customer = ref.watch(journeyControllerProvider).customer;
    final isAlreadyVerified = customer?.panVerified == true || _verifiedResult != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('PAN Verification'),
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
                  currentStep: 1,
                  totalSteps: 5,
                  stepTitles: ['PAN Verification', 'Personal Details', 'Profile & Income', 'Photo & Liveness', 'Submit'],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Verify Your PAN',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDarkPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Enter your 10-character Permanent Account Number (PAN) for identity verification.',
                  style: TextStyle(fontSize: 14, color: AppTheme.textDarkSecondary),
                ),
                                const SizedBox(height: 24),
                if (!isAlreadyVerified) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceWhite,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.primaryTeal.withValues(alpha: 0.15), width: 1.5),
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
                            Icon(Icons.credit_card_rounded, color: AppTheme.primaryTeal, size: 22),
                            SizedBox(width: 8),
                            Text(
                              'PAN Card Scan / Upload',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textDarkPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Scan your PAN card to auto-fill the field below, or enter details manually.',
                          style: TextStyle(fontSize: 12, color: AppTheme.textDarkSecondary),
                        ),
                        const SizedBox(height: 16),
                        if (_panImageFile != null) ...[
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  width: double.infinity,
                                  height: 160,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                  ),
                                  child: Image.file(
                                    _panImageFile!,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              if (_isOcrLoading)
                                Container(
                                  width: double.infinity,
                                  height: 160,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.4),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                      SizedBox(height: 12),
                                      Text(
                                        'Extracting PAN details...',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _isOcrLoading ? null : () => _pickPanImage(ImageSource.camera),
                                  icon: const Icon(Icons.camera_alt_outlined, size: 18),
                                  label: const Text('Retake Photo'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppTheme.primaryTeal,
                                    side: const BorderSide(color: AppTheme.primaryTeal),
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _isOcrLoading ? null : () => _pickPanImage(ImageSource.gallery),
                                  icon: const Icon(Icons.photo_library_outlined, size: 18),
                                  label: const Text('Upload New'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppTheme.primaryTeal,
                                    side: const BorderSide(color: AppTheme.primaryTeal),
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          if (_isOcrLoading)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 24.0),
                                child: Column(
                                  children: [
                                    CircularProgressIndicator(color: AppTheme.primaryTeal),
                                    SizedBox(height: 12),
                                    Text('Uploading & processing PAN...'),
                                  ],
                                ),
                              ),
                            )
                          else
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _pickPanImage(ImageSource.camera),
                                    icon: const Icon(Icons.camera_alt_outlined, size: 18),
                                    label: const Text('Take Photo'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryTeal,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _pickPanImage(ImageSource.gallery),
                                    icon: const Icon(Icons.photo_library_outlined, size: 18),
                                    label: const Text('Upload Photo'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppTheme.primaryTeal,
                                      side: const BorderSide(color: AppTheme.primaryTeal),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                AppTextField(
                  label: 'PAN Number',
                  hint: 'ABCDE1234F',
                  controller: _panController,
                  validator: Validators.validatePan,
                  textCapitalization: TextCapitalization.characters,
                  readOnly: isAlreadyVerified,
                  prefix: const Icon(Icons.badge_outlined, size: 20),
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
                if (isAlreadyVerified) ...[
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'PAN Verification Details',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              AppStatusBadge(status: 'VERIFIED', label: 'Verified'),
                            ],
                          ),
                          const Divider(height: 24),
                          _buildDetailRow('Masked PAN', Formatters.maskPan(customer?.panNumber ?? _panController.text)),
                          _buildDetailRow('Verified Name', customer?.fullName ?? _verifiedResult?['fullName'] ?? 'N/A'),
                          _buildDetailRow('Date of Birth', customer?.dateOfBirth ?? _verifiedResult?['dateOfBirth'] ?? 'N/A'),
                          _buildDetailRow('Gender', customer?.gender ?? _verifiedResult?['gender'] ?? 'N/A'),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                if (!isAlreadyVerified)
                  AppButton(
                    text: 'Verify PAN',
                    isLoading: _isLoading,
                    onPressed: _verifyPan,
                    icon: Icons.check_circle_outline,
                  )
                else
                  AppButton(
                    text: 'Continue',
                    onPressed: _continue,
                    icon: Icons.arrow_forward_rounded,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textDarkSecondary)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textDarkPrimary)),
        ],
      ),
    );
  }
}
