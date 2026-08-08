import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import '../../../../app/theme.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_stepper.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../dashboard/presentation/journey_controller.dart';

class BasicDetailsScreen extends ConsumerStatefulWidget {
  const BasicDetailsScreen({super.key});

  @override
  ConsumerState<BasicDetailsScreen> createState() => _BasicDetailsScreenState();
}

class _BasicDetailsScreenState extends ConsumerState<BasicDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _panController = TextEditingController();
  final _fatherNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _emailOtpController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();

  bool _isLoading = false;
  bool _isManualVerifying = false;
  String? _errorMessage;
  String? _panOcrResult;
  bool _isScanningPan = false;
  final ImagePicker _imagePicker = ImagePicker();

  bool _isOtpSent = false;
  bool _isSendingOtp = false;
  bool _isVerifyingOtp = false;

  @override
  void initState() {
    super.initState();
    final customer = ref.read(journeyControllerProvider).customer;
    if (customer != null) {
      if (customer.fullName != null) _nameController.text = customer.fullName!;
      if (customer.panNumber != null) _panController.text = customer.panNumber!;
      if (customer.fatherName != null) _fatherNameController.text = customer.fatherName!;
      if (customer.email != null) _emailController.text = customer.email!;
      if (customer.residentialPincode != null) _pincodeController.text = customer.residentialPincode!;
      if (customer.residentialCity != null) _cityController.text = customer.residentialCity!;
      if (customer.residentialState != null) _stateController.text = customer.residentialState!;
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await ref.read(journeyControllerProvider.notifier).syncCustomerState();
        final updatedCustomer = ref.read(journeyControllerProvider).customer;
        if (updatedCustomer != null && mounted) {
          setState(() {
            if (updatedCustomer.fullName != null) _nameController.text = updatedCustomer.fullName!;
            if (updatedCustomer.panNumber != null) _panController.text = updatedCustomer.panNumber!;
            if (updatedCustomer.fatherName != null) _fatherNameController.text = updatedCustomer.fatherName!;
            if (updatedCustomer.email != null) _emailController.text = updatedCustomer.email!;
            if (updatedCustomer.residentialPincode != null) _pincodeController.text = updatedCustomer.residentialPincode!;
            if (updatedCustomer.residentialCity != null) _cityController.text = updatedCustomer.residentialCity!;
            if (updatedCustomer.residentialState != null) _stateController.text = updatedCustomer.residentialState!;
          });
        }
      });
    }

    _pincodeController.addListener(() {
      final pincode = _pincodeController.text.trim();
      if (pincode.length == 6) {
        _lookupPincode(pincode);
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _panController.dispose();
    _fatherNameController.dispose();
    _emailController.dispose();
    _emailOtpController.dispose();
    _pincodeController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  Future<void> _scanPanOcr(ImageSource source) async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: source,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 85,
      );

      if (photo == null) return;

      setState(() {
        _isScanningPan = true;
        _errorMessage = null;
        _panOcrResult = null;
      });

      final bytes = await photo.readAsBytes();
      final apiClient = ref.read(apiClientProvider);
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: photo.name,
          contentType: MediaType('image', 'jpeg'),
        ),
      });

      print('[PAN OCR] Sending request to UAT /external-api/pan-ocr...');
      final res = await apiClient.post(
        '/external-api/pan-ocr',
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );
      print('[PAN OCR] Response received: $res');

      var data = res['data'] ?? res;
      if (data is Map<String, dynamic> && data['data'] != null) {
        data = data['data'];
      }
      final extractedPan = data['panNumber'] as String?;
      final extractedFather = data['fatherName'] as String?;
      final extractedName = data['fullName'] as String?;

      if (extractedName != null && extractedName.isNotEmpty) {
        _nameController.text = extractedName;
      }

      if (extractedFather != null && extractedFather.isNotEmpty) {
        _fatherNameController.text = extractedFather;
      }

      if (extractedPan != null && extractedPan.isNotEmpty) {
        _panController.text = extractedPan.toUpperCase();
      }

      setState(() {
        _panOcrResult = 'PAN details parsed successfully. Please verify to proceed.';
      });
    } catch (e) {
      print('[PAN OCR] Error occurred: $e');
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isScanningPan = false;
        });
      }
    }
  }

  Future<void> _verifyManualPan() async {
    final pan = _panController.text.trim().toUpperCase();
    if (pan.length != 10) {
      setState(() {
        _errorMessage = 'Please enter a valid 10-digit PAN number';
      });
      return;
    }

    setState(() {
      _isManualVerifying = true;
      _errorMessage = null;
    });

    try {
      var customerId = ref.read(journeyControllerProvider).customer?.id;
      if (customerId == null || customerId.isEmpty) {
        customerId = await ref.read(secureStorageProvider).getCustomerId();
      }
      print('[PAN VERIFY] Initiating verify-pan API call for customerId: $customerId, panNumber: $pan');
      if (customerId != null && customerId.isNotEmpty) {
        final apiClient = ref.read(apiClientProvider);
        final res = await apiClient.post(
          '/external-api/verify-pan',
          data: {
            'customerId': customerId,
            'panNumber': pan,
          },
        );
        print('[PAN VERIFY] API Response: $res');
        await ref.read(journeyControllerProvider.notifier).syncCustomerState();
        setState(() {
          _panOcrResult = 'PAN verified successfully: $pan';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Verification failed: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isManualVerifying = false;
        });
      }
    }
  }

  Future<void> _lookupPincode(String pincode) async {
    try {
      final dio = Dio();
      final response = await dio.get('https://api.postalpincode.in/pincode/$pincode');
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List && data.isNotEmpty) {
          final status = data[0]['Status'];
          if (status == 'Success') {
            final postOffices = data[0]['PostOffice'];
            if (postOffices is List && postOffices.isNotEmpty) {
              final district = postOffices[0]['District'];
              final state = postOffices[0]['State'];
              setState(() {
                _cityController.text = district ?? '';
                _stateController.text = state ?? '';
              });
            }
          }
        }
      }
    } catch (e) {
      // Ignore lookup error silently
    }
  }

  Future<void> _sendEmailOtp() async {
    final email = _emailController.text.trim();
    if (Validators.validateEmail(email) != null) {
      setState(() {
        _errorMessage = 'Please enter a valid email address';
      });
      return;
    }
    setState(() {
      _isSendingOtp = true;
      _errorMessage = null;
    });
    try {
      final customerId = ref.read(journeyControllerProvider).customer?.id;
      final apiClient = ref.read(apiClientProvider);
      await apiClient.post(
        '/otp/email/send',
        data: {
          'customerId': customerId,
          'email': email,
        },
      );
      setState(() {
        _isOtpSent = true;
        _panOcrResult = 'OTP sent to your email address.';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to send OTP: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSendingOtp = false;
        });
      }
    }
  }

  Future<void> _verifyEmailOtp() async {
    final otp = _emailOtpController.text.trim();
    if (otp.length != 6) {
      setState(() {
        _errorMessage = 'Please enter a 6-digit OTP';
      });
      return;
    }
    setState(() {
      _isVerifyingOtp = true;
      _errorMessage = null;
    });
    try {
      final customerId = ref.read(journeyControllerProvider).customer?.id;
      final email = _emailController.text.trim();
      final apiClient = ref.read(apiClientProvider);
      await apiClient.post(
        '/otp/email/verify',
        data: {
          'customerId': customerId,
          'email': email,
          'otp': otp,
        },
      );
      await ref.read(journeyControllerProvider.notifier).syncCustomerState();
      setState(() {
        _panOcrResult = 'Email verified successfully!';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Invalid OTP. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isVerifyingOtp = false;
        });
      }
    }
  }

  void _submit() async {
    final customer = ref.read(journeyControllerProvider).customer;
    if (customer?.emailVerified != true) {
      setState(() {
        _errorMessage = 'Please verify your email address to continue';
      });
      return;
    }

    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final customerId = customer?.id;
      final apiClient = ref.read(apiClientProvider);

      if (customerId != null) {
        // Update basic details
        await apiClient.patch(
          '/customer/$customerId/basic-details',
          data: {
            'fatherName': _fatherNameController.text.trim(),
            'email': _emailController.text.trim(),
            'residentialPincode': _pincodeController.text.trim(),
          },
        );

        // Update pincode & city info
        await apiClient.patch(
          '/customer/$customerId/pincode',
          data: {
            'pincode': _pincodeController.text.trim(),
            'city': _cityController.text.trim(),
            'state': _stateController.text.trim(),
          },
        );

        // Resume/Create application to ensure active application exists
        print('[BASIC DETAILS SUBMIT] Resuming/creating application for customerId: $customerId');
        await apiClient.post(
          '/customer/resume-application',
          data: const {},
        );

        // Run eligibility
        print('[BASIC DETAILS SUBMIT] Running eligibility for customerId: $customerId');
        final eligibilityRes = await apiClient.post(
          '/customer/$customerId/run-eligibility',
          data: const {},
        );

        await ref.read(journeyControllerProvider.notifier).syncCustomerState();
        if (mounted) {
          final updatedCustomer = ref.read(journeyControllerProvider).customer;
          if (updatedCustomer?.assessmentFeePaid == true) {
            context.go('/dashboard');
          } else {
            context.push('/payment/processing-fee', extra: eligibilityRes);
          }
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
    final customer = ref.watch(journeyControllerProvider).customer;
    final isPanVerified = customer?.panVerified == true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Details'),
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
                  currentStep: 2,
                  totalSteps: 5,
                  stepTitles: ['PAN Verification', 'Personal Details', 'Profile & Income', 'Photo & Liveness', 'Submit'],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Basic Information',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDarkPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Please provide your personal details to complete your profile.',
                  style: TextStyle(fontSize: 14, color: AppTheme.textDarkSecondary),
                ),
                const SizedBox(height: 24),
                AppTextField(
                  label: 'Full Name (As per PAN)',
                  controller: _nameController,
                  readOnly: true,
                  prefix: const Icon(Icons.person_outline, size: 20),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'PAN Number',
                  hint: 'ABCDE1234F',
                  controller: _panController,
                  readOnly: isPanVerified,
                  textCapitalization: TextCapitalization.characters,
                  prefix: const Icon(Icons.credit_card_outlined, size: 20),
                  validator: Validators.validatePan,
                ),
                const SizedBox(height: 16),
                if (!isPanVerified) ...[
                  if (_isScanningPan)
                    const AppButton(
                      text: 'Scanning PAN Card...',
                      isLoading: true,
                      onPressed: null,
                    )
                  else ...[
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            text: 'Take Photo',
                            isOutlined: true,
                            onPressed: () => _scanPanOcr(ImageSource.camera),
                            icon: Icons.camera_alt_outlined,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppButton(
                            text: 'Upload Photo',
                            isOutlined: true,
                            onPressed: () => _scanPanOcr(ImageSource.gallery),
                            icon: Icons.photo_library_outlined,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    AppButton(
                      text: 'Verify PAN',
                      isLoading: _isManualVerifying,
                      onPressed: _verifyManualPan,
                      icon: Icons.check_circle_outline,
                    ),
                  ],
                ] else ...[
                  AppTextField(
                    label: "Father's Full Name",
                    hint: "Enter father's full name",
                    controller: _fatherNameController,
                    validator: (v) => Validators.validateRequired(v, "Father's name"),
                    textCapitalization: TextCapitalization.words,
                    prefix: const Icon(Icons.people_outline, size: 20),
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Email Address',
                    hint: 'example@domain.com',
                    controller: _emailController,
                    readOnly: customer?.emailVerified == true,
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.validateEmail,
                    prefix: const Icon(Icons.email_outlined, size: 20),
                  ),
                  if (customer?.emailVerified != true) ...[
                    const SizedBox(height: 8),
                    if (!_isOtpSent)
                      AppButton(
                        text: 'Send OTP',
                        isLoading: _isSendingOtp,
                        onPressed: _sendEmailOtp,
                        icon: Icons.send,
                      )
                    else ...[
                      AppTextField(
                        label: 'Enter Email OTP',
                        hint: '6-digit OTP',
                        controller: _emailOtpController,
                        keyboardType: TextInputType.number,
                        prefix: const Icon(Icons.lock_outline, size: 20),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: AppButton(
                              text: 'Verify OTP',
                              isLoading: _isVerifyingOtp,
                              onPressed: _verifyEmailOtp,
                              icon: Icons.check,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppButton(
                              text: 'Resend OTP',
                              isOutlined: true,
                              onPressed: _sendEmailOtp,
                              icon: Icons.refresh,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ] else ...[
                    const SizedBox(height: 8),
                    const Row(
                      children: [
                        Icon(Icons.check_circle, color: AppTheme.successGreen, size: 18),
                        SizedBox(width: 6),
                        Text(
                          'Email address verified successfully',
                          style: TextStyle(color: AppTheme.successGreen, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Residential PIN Code',
                    hint: '6-digit PIN code',
                    controller: _pincodeController,
                    keyboardType: TextInputType.number,
                    validator: Validators.validatePincode,
                    prefix: const Icon(Icons.pin_drop_outlined, size: 20),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          label: 'City',
                          hint: 'City',
                          controller: _cityController,
                          readOnly: true,
                          validator: (v) => Validators.validateRequired(v, 'City'),
                          prefix: const Icon(Icons.location_city_outlined, size: 20),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppTextField(
                          label: 'State',
                          hint: 'State',
                          controller: _stateController,
                          readOnly: true,
                          validator: (v) => Validators.validateRequired(v, 'State'),
                          prefix: const Icon(Icons.map_outlined, size: 20),
                        ),
                      ),
                    ],
                  ),
                ],
                if (_panOcrResult != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.successBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline, color: AppTheme.successGreen, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _panOcrResult!,
                            style: const TextStyle(color: AppTheme.successGreen, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
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
                if (isPanVerified) ...[
                  const SizedBox(height: 32),
                  AppButton(
                    text: 'Save & Continue',
                    isLoading: _isLoading,
                    onPressed: _submit,
                    icon: Icons.arrow_forward_rounded,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
