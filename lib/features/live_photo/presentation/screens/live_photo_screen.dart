import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:camera/camera.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:http_parser/http_parser.dart';
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
  XFile? _imageFile;
  bool _isUploading = false;
  bool _isLivenessChecking = false;
  bool _isCompleted = false;
  String? _errorMessage;
  final ImagePicker _picker = ImagePicker();

  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _capturePhoto() async {
    setState(() {
      _errorMessage = null;
    });

    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        throw Exception('No camera available on this device.');
      }

      final frontCamera = _cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      setState(() {
        _isCameraInitialized = true;
      });
    } catch (e) {
      print('Camera initialization failed: $e');
      setState(() {
        _errorMessage = 'Failed to open camera: $e. \n\n'
            'Note: Web browsers require a secure context (localhost or HTTPS) to access the camera.';
      });
      _pickFromGallery();
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (photo != null) {
        setState(() {
          _imageFile = photo;
          _isCameraInitialized = false;
          _errorMessage = null;
        });
      }
    } catch (ex) {
      print('Gallery fallback failed: $ex');
    }
  }

  Future<void> _takePhoto() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    try {
      final XFile photo = await _cameraController!.takePicture();
      setState(() {
        _imageFile = photo;
        _isCameraInitialized = false;
      });
      await _cameraController!.dispose();
      _cameraController = null;
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to capture photograph: $e';
      });
    }
  }

  Future<Uint8List> _addWatermark({
    required Uint8List imageBytes,
    required String latitude,
    required String longitude,
    required String address,
    required String time,
  }) async {
    final codec = await ui.instantiateImageCodec(imageBytes);
    final frameInfo = await codec.getNextFrame();
    final image = frameInfo.image;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    canvas.drawImage(image, Offset.zero, Paint());

    final watermarkText = 'Lat: $latitude, Lon: $longitude\nAddress: $address\nTime: $time';
    final double fontSize = (image.width / 35).clamp(10.0, 24.0);

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );
    
    textPainter.text = TextSpan(
      text: watermarkText,
      style: TextStyle(
        color: Colors.yellowAccent,
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        shadows: const [
          Shadow(
            offset: Offset(1.0, 1.0),
            blurRadius: 2.0,
            color: Colors.black,
          ),
        ],
      ),
    );

    textPainter.layout(maxWidth: image.width - 20.0);
    
    final rectHeight = textPainter.height + 12.0;
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;
    
    canvas.drawRect(
      Rect.fromLTWH(0, image.height - rectHeight, image.width.toDouble(), rectHeight),
      paint,
    );

    textPainter.paint(
      canvas,
      Offset(10.0, image.height - rectHeight + 6.0),
    );

    final picture = recorder.endRecording();
    final watermarkedImage = await picture.toImage(image.width, image.height);
    final byteData = await watermarkedImage.toByteData(format: ui.ImageByteFormat.png);
    
    return byteData!.buffer.asUint8List();
  }

  Future<void> _uploadAndCheckLiveness() async {
    if (_imageFile == null) return;
    final customerId = ref.read(journeyControllerProvider).customer?.id;
    final applicationId = ref.read(journeyControllerProvider).customer?.latestApplicationId;
    if (customerId == null || applicationId == null) {
      setState(() {
        _errorMessage = 'Session missing Customer ID or Application ID.';
      });
      return;
    }

    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      final customerApi = ref.read(customerApiProvider);

      // 1. Get current geolocation details
      double lat = 19.0760;
      double lon = 72.8777;
      double accuracy = 10.0;
      String formattedAddress = 'Mumbai, Maharashtra';
      String city = 'Mumbai';
      String state = 'Maharashtra';
      String country = 'India';
      String postalCode = '400001';

      try {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 8),
        );
        lat = position.latitude;
        lon = position.longitude;
        accuracy = position.accuracy;

        final geocodeRes = await customerApi.reverseGeocode(lat, lon);
        final gd = geocodeRes['data'] ?? geocodeRes;
        if (gd != null) {
          formattedAddress = gd['formattedAddress'] ?? formattedAddress;
          city = gd['city'] ?? city;
          state = gd['state'] ?? state;
          country = gd['country'] ?? country;
          postalCode = gd['postalCode'] ?? postalCode;
        }
      } catch (ge) {
        print('Geolocation fetch failed: $ge');
      }

      // 2. Load bytes and apply watermark
      final originalBytes = await _imageFile!.readAsBytes();
      final timeStr = DateTime.now().toLocal().toString().split('.')[0];
      final watermarkedBytes = await _addWatermark(
        imageBytes: originalBytes,
        latitude: lat.toStringAsFixed(6),
        longitude: lon.toStringAsFixed(6),
        address: formattedAddress,
        time: timeStr,
      );

      setState(() {
        _isUploading = false;
        _isLivenessChecking = true;
      });

      // 3. Verify face liveness via base64 data URL
      final base64Image = 'data:image/jpeg;base64,${base64.encode(watermarkedBytes)}';
      final livenessRes = await apiClient.post(
        '/external-api/face-liveness',
        data: {
          'applicationId': applicationId.toString(),
          'inputImage': base64Image,
        },
      );

      Map<String, dynamic> innerData = {};
      if (livenessRes['data'] is Map) {
        final d1 = livenessRes['data'];
        if (d1['data'] is Map) {
          innerData = Map<String, dynamic>.from(d1['data']);
        } else {
          innerData = Map<String, dynamic>.from(d1);
        }
      } else {
        innerData = Map<String, dynamic>.from(livenessRes);
      }

      final livenessResult = innerData['livenessResult'] ?? innerData;
      final livenessVerificationId = innerData['livenessVerificationId'] ?? '';

      final passed = livenessRes['success'] == true || 
                     innerData['success'] == true || 
                     livenessResult['is_live'] == true || 
                     livenessResult['passed'] == true;

      if (!passed || livenessVerificationId.toString().isEmpty) {
        throw Exception('Face liveness verification failed. Please retake photo in clear lighting.');
      }

      setState(() {
        _isLivenessChecking = false;
        _isUploading = true;
      });

      // 4. Upload watermarked file to the documents endpoint
      final multipartFile = MultipartFile.fromBytes(
        watermarkedBytes,
        filename: 'live_photo.jpg',
        contentType: MediaType('image', 'jpeg'),
      );

      final formData = FormData.fromMap({
        'file': multipartFile,
        'applicationId': applicationId.toString(),
        'livenessVerificationId': livenessVerificationId.toString(),
        'latitude': lat.toString(),
        'longitude': lon.toString(),
        'accuracy': accuracy.toString(),
        'formattedAddress': formattedAddress,
        'city': city,
        'state': state,
        'country': country,
        'postalCode': postalCode,
        'capturedAt': DateTime.now().toUtc().toIso8601String(),
        'documentType': 'CUSTOMER_LIVE_PHOTO',
        'source': 'PROFILE_DETAILS',
        'applicantType': 'BORROWER',
      });

      await apiClient.post(
        '/documents/customer-live-photo',
        data: formData,
      );

      setState(() {
        _isCompleted = true;
      });

      if (!kIsWeb) {
        try {
          final file = File(_imageFile!.path);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (_) {}
      }

      await ref.read(journeyControllerProvider.notifier).syncCustomerState();

    } catch (e) {
      print('Liveness & Upload failed: $e');
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
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
                    child: _isCameraInitialized && _cameraController != null
                        ? CameraPreview(_cameraController!)
                        : _imageFile != null
                            ? (kIsWeb 
                                ? Image.network(_imageFile!.path, fit: BoxFit.cover)
                                : Image.file(File(_imageFile!.path), fit: BoxFit.cover))
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
                if (_isCameraInitialized) ...[
                  AppButton(
                    text: 'Capture Photograph',
                    onPressed: _takePhoto,
                    icon: Icons.camera_rounded,
                  ),
                  const SizedBox(height: 12),
                  AppButton(
                    text: 'Cancel & Choose File',
                    isOutlined: true,
                    onPressed: () async {
                      if (_cameraController != null) {
                        await _cameraController!.dispose();
                        _cameraController = null;
                      }
                      setState(() {
                        _isCameraInitialized = false;
                      });
                      _pickFromGallery();
                    },
                    icon: Icons.photo_library_outlined,
                  ),
                ] else ...[
                  AppButton(
                    text: _imageFile == null ? 'Open Camera & Capture' : 'Retake Selfie',
                    isOutlined: _imageFile != null,
                    onPressed: _capturePhoto,
                    icon: Icons.camera_alt_outlined,
                  ),
                  if (_imageFile == null) ...[
                    const SizedBox(height: 12),
                    AppButton(
                      text: 'Choose File from Computer',
                      isOutlined: true,
                      onPressed: _pickFromGallery,
                      icon: Icons.upload_file_outlined,
                    ),
                  ],
                ],
                if (_imageFile != null && !_isCameraInitialized) ...[
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
