import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme.dart';
import '../../../../core/models/referral_model.dart';
import '../../../../core/providers/referral_provider.dart';
import '../../../../core/utils/currency_utils.dart';

class ReferralFeeDiscountWidget extends ConsumerStatefulWidget {
  final num baseProcessingFee;
  final int loanNumber;
  final ValueChanged<ReferralBenefitResult>? onBenefitApplied;

  const ReferralFeeDiscountWidget({
    super.key,
    required this.baseProcessingFee,
    this.loanNumber = 1,
    this.onBenefitApplied,
  });

  @override
  ConsumerState<ReferralFeeDiscountWidget> createState() =>
      _ReferralFeeDiscountWidgetState();
}

class _ReferralFeeDiscountWidgetState
    extends ConsumerState<ReferralFeeDiscountWidget> {
  bool _isApplying = true;
  ReferralBenefitResult? _benefitResult;

  @override
  void initState() {
    super.initState();
    _fetchBenefit();
  }

  @override
  void didUpdateWidget(covariant ReferralFeeDiscountWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.baseProcessingFee != widget.baseProcessingFee ||
        oldWidget.loanNumber != widget.loanNumber) {
      _fetchBenefit();
    }
  }

  Future<void> _fetchBenefit() async {
    setState(() => _isApplying = true);
    final result = await ref.read(referralProvider.notifier).applyBenefit(
          baseProcessingFee: widget.baseProcessingFee,
          loanNumber: widget.loanNumber,
        );
    if (mounted) {
      setState(() {
        _benefitResult = result;
        _isApplying = false;
      });
      if (result != null && widget.onBenefitApplied != null) {
        widget.onBenefitApplied!(result);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isApplying) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.primaryTeal,
              ),
            ),
            SizedBox(width: 8),
            Text(
              'Checking referral fee waiver benefits...',
              style: TextStyle(fontSize: 12, color: AppTheme.textDarkSecondary),
            ),
          ],
        ),
      );
    }

    final benefit = _benefitResult;
    final isApplied = benefit?.benefitApplied == true;

    if (!isApplied) {
      return const SizedBox.shrink();
    }

    final origFee = benefit!.originalProcessingFee;
    final discount = benefit.discountApplied;
    final finalFee = benefit.finalProcessingFee;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFA7F3D0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Color(0xFF059669),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.card_giftcard_rounded,
                  color: Colors.white,
                  size: 14,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Referral Fee Waiver Applied 🎉',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF065F46),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildRow('Original Processing Fee', CurrencyUtils.formatAmount(origFee), isCrossed: true),
          const SizedBox(height: 4),
          _buildRow(
            'Referral Fee Discount',
            '-${CurrencyUtils.formatAmount(discount)}',
            valueColor: const Color(0xFF059669),
            isBold: true,
          ),
          const Divider(height: 16, color: Color(0xFFA7F3D0)),
          _buildRow(
            'Payable Processing Fee',
            CurrencyUtils.formatAmount(finalFee),
            valueColor: const Color(0xFF064E3B),
            isBold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildRow(
    String label,
    String value, {
    bool isCrossed = false,
    Color? valueColor,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            color: Color(0xFF047857),
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.w900 : FontWeight.w600,
            color: valueColor ?? const Color(0xFF065F46),
            decoration: isCrossed ? TextDecoration.lineThrough : null,
            decorationColor: const Color(0xFF047857),
          ),
        ),
      ],
    );
  }
}
