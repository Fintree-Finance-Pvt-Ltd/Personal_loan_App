import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app/app.dart';
import 'app/env.dart';
import 'app/router.dart';
import 'core/services/push_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  currentEnvironment = Environment.fromDartDefine();

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
  } catch (e) {
    debugPrint('Firebase initialization warning (config missing?): $e');
  }

  // Initialize Push Notifications Service and route callback
  try {
    await PushNotificationService().initialize(
      onNavigate: (route) {
        debugPrint('Deep link navigating to route: $route');
        appRouter.push(route);
      },
    );
  } catch (e) {
    debugPrint('Push Notification Service init error: $e');
  }

  runApp(
    const ProviderScope(
      child: PlCustomerApp(),
    ),
  );
}

