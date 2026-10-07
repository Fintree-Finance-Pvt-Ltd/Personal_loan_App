import 'package:flutter/material.dart';
import '../../app/theme.dart';
import 'app_button.dart';

enum StatusCardType {
  underReview,
  preApproved,
  approved,
  rejected,
  info,
}

/// A reusable fintech-grade status card used across credit review,
/// pre-approval, and final loan decision states.
class StatusCard extends StatefulWidget {
  final StatusCardType type;
  final String title;
  final String description;
  final String? badgeText;
  final Widget? extraContent;
  final String? primaryActionText;
  final VoidCallback? onPrimaryAction;
  final String? secondaryActionText;
  final VoidCallback? onSecondaryAction;
  final bool isProcessing;

  const StatusCard({
    super.key,
    required this.type,
    required this.title,
    required this.description,
    this.badgeText,
    this.extraContent,
    this.primaryActionText,
    this.onPrimaryAction,
    this.secondaryActionText,
    this.onSecondaryAction,
    this.isProcessing = false,
  });

  /// Factory for PENDING_CREDIT_REVIEW & Lender Underwriting states
  factory StatusCard.underReview({
    Key? key,
    String title = 'Under Review',
    String description = 'Your application is being reviewed by our credit team.',
    Widget? extraContent,
    VoidCallback? onRefresh,
  }) {
    return StatusCard(
      key: key,
      type: StatusCardType.underReview,
      title: title,
      description: description,
      badgeText: 'CREDIT REVIEW',
      isProcessing: true,
      extraContent: extraContent,
      secondaryActionText: onRefresh != null ? 'Refresh Status' : null,
      onSecondaryAction: onRefresh,
    );
  }

  /// Factory for LENDER_PRE_APPROVED state
  factory StatusCard.preApproved({
    Key? key,
    String title = "You're Pre-Approved",
    String description = 'Your offer is ready.',
    Widget? extraContent,
    required VoidCallback onViewOffer,
  }) {
    return StatusCard(
      key: key,
      type: StatusCardType.preApproved,
      title: title,
      description: description,
      badgeText: 'PRE-APPROVED',
      extraContent: extraContent,
      primaryActionText: 'View Pre-Approved Offer',
      onPrimaryAction: onViewOffer,
    );
  }

  /// Factory for LENDER_APPROVED state
  factory StatusCard.approved({
    Key? key,
    String title = 'Application Approved!',
    String description = 'Congratulations! Your loan has received lender approval.',
    Widget? extraContent,
    required VoidCallback onContinue,
    String actionText = 'Continue to Next Step',
  }) {
    return StatusCard(
      key: key,
      type: StatusCardType.approved,
      title: title,
      description: description,
      badgeText: 'SANCTIONED',
      extraContent: extraContent,
      primaryActionText: actionText,
      onPrimaryAction: onContinue,
    );
  }

  @override
  State<StatusCard> createState() => _StatusCardState();
}

class _StatusCardState extends State<StatusCard> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.isProcessing) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant StatusCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isProcessing && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isProcessing && _pulseController.isAnimating) {
      _pulseController.stop();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Color get _accentColor {
    switch (widget.type) {
      case StatusCardType.underReview:
        return const Color(0xFFD97706); // amber-600
      case StatusCardType.preApproved:
      case StatusCardType.approved:
        return AppTheme.primaryTeal;
      case StatusCardType.rejected:
        return AppTheme.errorRed;
      case StatusCardType.info:
        return const Color(0xFF2563EB); // blue-600
    }
  }

  Color get _bgColor {
    switch (widget.type) {
      case StatusCardType.underReview:
        return const Color(0xFFFFFBEB); // amber-50
      case StatusCardType.preApproved:
      case StatusCardType.approved:
        return const Color(0xFFECFDF5); // emerald-50
      case StatusCardType.rejected:
        return AppTheme.errorBg;
      case StatusCardType.info:
        return const Color(0xFFEFF6FF); // blue-50
    }
  }

  IconData get _icon {
    switch (widget.type) {
      case StatusCardType.underReview:
        return Icons.hourglass_top_rounded;
      case StatusCardType.preApproved:
        return Icons.verified_rounded;
      case StatusCardType.approved:
        return Icons.check_circle_rounded;
      case StatusCardType.rejected:
        return Icons.cancel_rounded;
      case StatusCardType.info:
        return Icons.info_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _accentColor.withValues(alpha: 0.22),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _accentColor.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top status banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: _bgColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
            ),
            child: Row(
              children: [
                if (widget.isProcessing && !disableAnimations)
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: _buildIconCircle(),
                  )
                else
                  _buildIconCircle(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.badgeText != null)
                        Text(
                          widget.badgeText!,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                            color: _accentColor,
                          ),
                        ),
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textDarkPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Body text & custom content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.description,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: AppTheme.textDarkSecondary,
                    height: 1.45,
                  ),
                ),
                if (widget.isProcessing) ...[
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: const LinearProgressIndicator(
                      minHeight: 4,
                      backgroundColor: Color(0xFFFDE68A),
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD97706)),
                    ),
                  ),
                ],
                if (widget.extraContent != null) ...[
                  const SizedBox(height: 16),
                  widget.extraContent!,
                ],
                if (widget.primaryActionText != null || widget.secondaryActionText != null) ...[
                  const SizedBox(height: 20),
                  if (widget.primaryActionText != null)
                    AppButton(
                      text: widget.primaryActionText!,
                      onPressed: widget.onPrimaryAction,
                      icon: Icons.arrow_forward_rounded,
                    ),
                  if (widget.secondaryActionText != null) ...[
                    if (widget.primaryActionText != null) const SizedBox(height: 10),
                    AppButton(
                      text: widget.secondaryActionText!,
                      isOutlined: true,
                      onPressed: widget.onSecondaryAction,
                      icon: Icons.refresh_rounded,
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconCircle() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: _accentColor.withValues(alpha: 0.14),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(_icon, color: _accentColor, size: 22),
      ),
    );
  }
}
