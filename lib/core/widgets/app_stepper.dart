import 'package:flutter/material.dart';
import '../../app/theme.dart';

class AppStepper extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final List<String>? stepTitles;

  const AppStepper({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    this.stepTitles,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Step $currentStep of $totalSteps',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryTeal,
              ),
            ),
            if (stepTitles != null && currentStep <= stepTitles!.length)
              Text(
                stepTitles![currentStep - 1],
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textDarkSecondary,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: currentStep / totalSteps,
            minHeight: 6,
            backgroundColor: AppTheme.borderLight,
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryTeal),
          ),
        ),
      ],
    );
  }
}
