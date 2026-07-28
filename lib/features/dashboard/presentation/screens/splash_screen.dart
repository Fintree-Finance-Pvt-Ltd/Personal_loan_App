import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme.dart';
import '../../../../core/widgets/app_loader.dart';
import '../journey_controller.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(journeyControllerProvider.notifier).syncCustomerState();
      if (!mounted) return;
      final target = ref.read(journeyControllerProvider).targetRoute;
      context.go(target);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet_rounded,
              size: 72,
              color: AppTheme.primaryTeal,
            ),
            SizedBox(height: 16),
            Text(
              'Personal Loan Platform',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDarkPrimary,
              ),
            ),
            SizedBox(height: 32),
            AppLoader(message: 'Restoring session & sync state...'),
          ],
        ),
      ),
    );
  }
}
