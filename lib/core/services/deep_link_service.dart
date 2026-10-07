import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import '../api/api_client.dart';
import '../models/referral_model.dart';

class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;

  String? _pendingReferralCode;
  String? _referrerName;

  String? get pendingReferralCode => _pendingReferralCode;
  String? get referrerName => _referrerName;

  void setReferralCode(String code, {String? name}) {
    _pendingReferralCode = code;
    _referrerName = name;
  }

  void clearReferralCode() {
    _pendingReferralCode = null;
    _referrerName = null;
  }

  Future<void> init(ApiClient apiClient) async {
    try {
      // 1. Handle initial link if app was launched via deep link
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        await _handleUri(initialUri, apiClient);
      }

      // 2. Listen to subsequent link stream when app is in background/foreground
      _sub = _appLinks.uriLinkStream.listen(
        (uri) async {
          await _handleUri(uri, apiClient);
        },
        onError: (err) {
          debugPrint('[DeepLinkService] Link stream error: $err');
        },
      );
    } catch (e) {
      debugPrint('[DeepLinkService] Initialization error: $e');
    }
  }

  Future<void> _handleUri(Uri uri, ApiClient apiClient) async {
    debugPrint('[DeepLinkService] Received URI: $uri');
    final refCode = uri.queryParameters['ref'] ?? uri.queryParameters['referralCode'];

    if (refCode != null && refCode.trim().isNotEmpty) {
      final code = refCode.trim().toUpperCase();
      debugPrint('[DeepLinkService] Extracted referral code: $code');
      _pendingReferralCode = code;

      // Validate code via public API
      try {
        final res = await apiClient.post(
          '/referral/validate',
          data: {'referralCode': code},
        );

        final data = res['data'] ?? res;
        if (data is Map<String, dynamic>) {
          final result = ReferralValidationResult.fromJson(data);
          if (result.valid) {
            _referrerName = result.referrerName;
            debugPrint('[DeepLinkService] Code valid! Referrer: ${result.referrerName}');
          }
        }
      } catch (e) {
        debugPrint('[DeepLinkService] Validation failed: $e');
      }
    }
  }

  void dispose() {
    _sub?.cancel();
  }
}
