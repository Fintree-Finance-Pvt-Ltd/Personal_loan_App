import 'package:flutter/material.dart';
import '../../app/theme.dart';

enum LoanJourneyStep {
  mobileVerification('Verification', 'Mobile Verified'),
  kyc('KYC & PAN', 'KYC Completed'),
  application('Application', 'Details Saved'),
  eligibility('Eligibility', 'Assessed'),
  offer('Loan Offer', 'Offer Selected'),
  creditReview('Credit Review', 'Review Done'),
  preApproval('Pre-Approval', 'Pre-Approved'),
  finalApproval('Final Approval', 'Approved'),
  postApproval('Bank & E-Sign', 'Verified & Signed'),
  disbursal('Disbursal', 'Funds Transferred');

  final String title;
  final String completedLabel;
  const LoanJourneyStep(this.title, this.completedLabel);
}

/// A fintech-style continuous loan journey progress indicator.
/// Completed: ✓ (Emerald Check)
/// Current: ● (Active Emerald with subtle glow/pulse)
/// Upcoming: ○ (Muted slate ring)
class JourneyProgress extends StatelessWidget {
  final LoanJourneyStep currentStep;
  final bool compact;

  const JourneyProgress({
    super.key,
    required this.currentStep,
    this.compact = false,
  });

  int get _currentIndex => currentStep.index;
  int get _totalSteps => LoanJourneyStep.values.length;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompact(context);
    }
    return _buildExpanded(context);
  }

  /// Compact header pill view for screens with dense content
  Widget _buildCompact(BuildContext context) {
    final percent = (_currentIndex + 1) / _totalSteps;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.primaryLightTeal,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primaryTeal.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryTeal,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Step ${_currentIndex + 1} of $_totalSteps: ${currentStep.title}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryDarkTeal,
                    ),
                  ),
                ],
              ),
              Text(
                '${(percent * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryTeal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: percent),
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return LinearProgressIndicator(
                  value: value,
                  minHeight: 5,
                  backgroundColor: AppTheme.primaryTeal.withValues(alpha: 0.15),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryTeal),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Expanded horizontal flow indicator with completed (✓), current (●), upcoming (○)
  Widget _buildExpanded(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'LOAN JOURNEY',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    color: AppTheme.textMuted,
                  ),
                ),
                Text(
                  '${_currentIndex + 1} of $_totalSteps Completed',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryTeal,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: List.generate(_totalSteps, (index) {
                final isCompleted = index < _currentIndex;
                final isCurrent = index == _currentIndex;

                return Row(
                  children: [
                    _buildStepNode(
                      index: index,
                      step: LoanJourneyStep.values[index],
                      isCompleted: isCompleted,
                      isCurrent: isCurrent,
                    ),
                    if (index < _totalSteps - 1)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        width: 24,
                        height: 2,
                        color: isCompleted
                            ? AppTheme.primaryTeal
                            : AppTheme.borderLight,
                      ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepNode({
    required int index,
    required LoanJourneyStep step,
    required bool isCompleted,
    required bool isCurrent,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isCurrent
            ? AppTheme.primaryLightTeal
            : (isCompleted ? const Color(0xFFF0FDF4) : Colors.transparent),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isCurrent
              ? AppTheme.primaryTeal
              : (isCompleted ? AppTheme.successGreen.withValues(alpha: 0.3) : Colors.transparent),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted
                  ? AppTheme.primaryTeal
                  : (isCurrent ? AppTheme.primaryTeal : Colors.transparent),
              border: Border.all(
                color: isCompleted || isCurrent
                    ? AppTheme.primaryTeal
                    : AppTheme.textMuted.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: Center(
              child: isCompleted
                  ? const Text(
                      '✓',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : (isCurrent
                      ? const Text(
                          '●',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        )
                      : const Text(
                          '○',
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 10,
                          ),
                        )),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            step.title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
              color: isCurrent
                  ? AppTheme.primaryDarkTeal
                  : (isCompleted ? AppTheme.textDarkPrimary : AppTheme.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}
