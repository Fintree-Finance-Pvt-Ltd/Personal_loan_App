import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/theme.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../../../core/widgets/app_stepper.dart';
import '../../../dashboard/presentation/journey_controller.dart';

class LivePhotoScreen extends ConsumerStatefulWidget {
  const LivePhotoScreen({super.key});

  @override
  ConsumerState<LivePhotoScreen> createState() => _LivePhotoScreenState();
}

class _LivePhotoScreenState extends ConsumerState<LivePhotoScreen> {
  File? _imageFile;
  bool _isUploading = false;
  bool _isLivenessChecking = false;
  bool _isCompleted = false;
  String? _errorMessage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _capturePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 85,
      );

      if (photo != null) {
        setState(() {
          _imageFile = File(photo.path);
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to access camera: $e';
      });
    }
  }

  Future<void> _uploadAndCheckLiveness() async {
    if (_imageFile == null) return;
    final customerId = ref.read(journeyControllerProvider).customer?.id;
    if (customerId == null) return;

    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);

      // 1. Upload live photo
      final formData = FormData.fromMap({
        'customerId': customerId,
        'file': await MultipartFile.fromFile(_imageFile!.path, filename: 'live_photo.jpg'),
      });

      final uploadRes = await apiClient.post(
        '/documents/customer-live-photo',
        data: formData,
      );

      setState(() {
        _isUploading = false;
        _isLivenessChecking = true;
      });

      // 2. Call face liveness verification
      final livenessRes = await apiClient.post(
        '/external-api/face-liveness',
        data: {
          'customerId': customerId,
          'documentId': uploadRes['data']?['id'] ?? uploadRes['id'],
        },
      );

      final passed = livenessRes['success'] == true || livenessRes['status'] == 'SUCCESS' || livenessRes['passed'] == true;

      if (passed) {
        setState(() {
          _isCompleted = true;
        });
        // Delete temporary image file after successful upload
        if (await _imageFile!.exists()) {
          await _imageFile!.delete();
        }
        await ref.read(journeyControllerProvider.notifier).syncCustomerState();
      } else {
        setState(() {
          _errorMessage = livenessRes['message'] ?? 'Face liveness check failed. Please ensure proper lighting and retry.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _isLivenessChecking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Photograph'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppStepper(
                currentStep: 4,
                totalSteps: 7,
                stepTitles: ['PAN Verification', 'Personal Details', 'Profile & Income', 'Photo & Liveness', 'DigiLocker KYC', 'Address Confirmation', 'Review & Submit'],
              ),
              const SizedBox(height: 24),
              const Text(
                'Live Photo Verification',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDarkPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Take a selfie in a well-lit environment without glasses or headgear.',
                style: TextStyle(fontSize: 14, color: AppTheme.textDarkSecondary),
              ),
              const SizedBox(height: 32),
              Center(
                child: Container(
                  width: 220,
                  height: 260,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceWhite,
                    borderRadius: BorderRadius.circular(120),
                    border: Border.all(
                      color: _isCompleted
                          ? AppTheme.successGreen
                          : AppTheme.primaryTeal,
                      width: 3,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(120),
                    child: _imageFile != null
                        ? Image.file(_imageFile!, fit: BoxFit.cover)
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.face_retouching_natural_outlined, size: 64, color: AppTheme.primaryTeal),
                              SizedBox(height: 12),
                              Text('Position Face Here', style: TextStyle(fontSize: 13, color: AppTheme.textMuted)),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (_isUploading)
                const AppLoader(message: 'Uploading photograph to secure vault...')
              else if (_isLivenessChecking)
                const AppLoader(message: 'Performing AI Face Liveness check...')
              else if (_isCompleted) ...[
                const Center(
                  child: Column(
                    children: [
                      AppStatusBadge(status: 'VERIFIED', label: 'Face Liveness Verified'),
                      SizedBox(height: 12),
                      Text('Your photograph has been verified successfully.', style: TextStyle(fontSize: 14, color: AppTheme.successGreen)),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                AppButton(
                  text: 'Proceed to DigiLocker KYC',
                  onPressed: () => context.push('/onboarding/digilocker'),
                  icon: Icons.arrow_forward_rounded,
                ),
              ] else ...[
                if (_errorMessage != null) ...[
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
                  const SizedBox(height: 16),
                ],
                AppButton(
                  text: _imageFile == null ? 'Open Camera & Capture' : 'Retake Selfie',
                  isOutlined: _imageFile != null,
                  onPressed: _capturePhoto,
                  icon: Icons.camera_alt_outlined,
                ),
                if (_imageFile != null) ...[
                  const SizedBox(height: 12),
                  AppButton(
                    text: 'Upload & Verify Photo',
                    onPressed: _uploadAndCheckLiveness,
                    icon: Icons.cloud_upload_outlined,
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
