import 'package:flutter/material.dart';
import '../../app/theme.dart';

/// Lightweight, high-performance shimmer effect for API loading states.
class AppSkeleton extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;

  const AppSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
    this.margin,
  });

  @override
  State<AppSkeleton> createState() => _AppSkeletonState();
}

class _AppSkeletonState extends State<AppSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    if (disableAnimations) {
      return Container(
        width: widget.width,
        height: widget.height,
        margin: widget.margin,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          margin: widget.margin,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: [
                (_controller.value - 0.3).clamp(0.0, 1.0),
                _controller.value.clamp(0.0, 1.0),
                (_controller.value + 0.3).clamp(0.0, 1.0),
              ],
              colors: const [
                Color(0xFFF1F5F9),
                Color(0xFFE2E8F0),
                Color(0xFFF1F5F9),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Pre-styled Skeleton card for loan offers (Sanction amount, EMI, tenure chips)
class OfferSkeletonCard extends StatelessWidget {
  const OfferSkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppSkeleton(width: 120, height: 16),
              AppSkeleton(width: 80, height: 24, borderRadius: 12),
            ],
          ),
          SizedBox(height: 14),
          AppSkeleton(width: 180, height: 36, borderRadius: 10),
          SizedBox(height: 12),
          AppSkeleton(width: double.infinity, height: 50, borderRadius: 12),
          SizedBox(height: 18),
          AppSkeleton(width: 140, height: 16),
          SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: AppSkeleton(width: 70, height: 42, borderRadius: 10)),
              SizedBox(width: 8),
              Expanded(child: AppSkeleton(width: 70, height: 42, borderRadius: 10)),
              SizedBox(width: 8),
              Expanded(child: AppSkeleton(width: 70, height: 42, borderRadius: 10)),
            ],
          ),
          SizedBox(height: 20),
          AppSkeleton(width: double.infinity, height: 52, borderRadius: 12),
        ],
      ),
    );
  }
}

/// Pre-styled Skeleton card for Customer Application / Profile information
class CustomerInfoSkeleton extends StatelessWidget {
  const CustomerInfoSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: const Column(
        children: [
          Row(
            children: [
              AppSkeleton(width: 44, height: 44, borderRadius: 22),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppSkeleton(width: 140, height: 16),
                  SizedBox(height: 6),
                  AppSkeleton(width: 100, height: 12),
                ],
              ),
            ],
          ),
          SizedBox(height: 16),
          Divider(height: 1, color: AppTheme.borderLight),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppSkeleton(width: 100, height: 14),
              AppSkeleton(width: 120, height: 14),
            ],
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppSkeleton(width: 80, height: 14),
              AppSkeleton(width: 140, height: 14),
            ],
          ),
        ],
      ),
    );
  }
}

/// Pre-styled Skeleton for Bank Account Verification
class BankInfoSkeleton extends StatelessWidget {
  const BankInfoSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: const Column(
        children: [
          Row(
            children: [
              AppSkeleton(width: 36, height: 36, borderRadius: 10),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppSkeleton(width: 130, height: 15),
                  SizedBox(height: 6),
                  AppSkeleton(width: 90, height: 12),
                ],
              ),
            ],
          ),
          SizedBox(height: 14),
          AppSkeleton(width: double.infinity, height: 44, borderRadius: 10),
        ],
      ),
    );
  }
}
