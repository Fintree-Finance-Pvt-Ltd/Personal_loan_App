import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'app/env.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  currentEnvironment = Environment.fromDartDefine();

  runApp(
    const ProviderScope(
      child: PlCustomerApp(),
    ),
  );
}
