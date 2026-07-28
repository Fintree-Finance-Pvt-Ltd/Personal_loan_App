import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../../dashboard/presentation/journey_controller.dart';

class LoanOfferScreen extends ConsumerStatefulWidget {
  final String lan;

  const LoanOfferScreen({super.key, required this.lan});

  @override
  ConsumerState<LoanOfferScreen> createState() => _LoanOfferScreenState();
}

class _LoanOfferScreenState extends ConsumerState<LoanOfferScreen> {
  int _selectedTenureDays = 60;
  bool _isAccepting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final offer = ref.read(journeyControllerProvider).postApproval?.offer;
      if (offer != null && offer.allowedTenures.isNotEmpty) {
        setState(() {
          _selectedTenureDays = offer.acceptedTenureDays ?? offer.allowedTenures.first;
        });
      }
    });
  }

  void _acceptOffer() async {
    final customerId = ref.read(journeyControllerProvider).customer?.id;
    if (customerId == null) return;

    setState(() {
      _isAccepting = true;
      _errorMessage = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.post(
        '/customer/loans/${widget.lan}/offer/accept',
        data: {
          'customerId': customerId,
          'tenureDays': _selectedTenureDays,
        },
      );

      await ref.read(journeyControllerProvider.notifier).syncCustomerState();

      if (mounted) {
        context.push('/loan/${widget.lan}/digilocker');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) setState(() => _isAccepting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final journey = ref.watch(journeyControllerProvider).postApproval;
    final offer = journey?.offer;
    final isAccepted = offer?.acceptedTenureDays != null;

    if (journey == null || offer == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loan Offer')),
        body: const AppLoader(message: 'Loading approved loan offer...'),
      );
    }

    final amount = offer.approvedAmount ?? 50000;
    final interestRate = offer.acceptedInterestRate ?? 18.0;
    final processingFee = offer.acceptedProcessingFee ?? (amount * 0.02);
    final gst = processingFee * 0.18;
    final netDisbursal = amount - (processingFee + gst);
    final totalRepayment = offer.acceptedTotalRepayment ?? (amount + (amount * (interestRate / 100) * (_selectedTenureDays / 365)));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Loan Offer Summary'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                color: AppTheme.primaryLightTeal,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Sanctioned Loan Amount', style: TextStyle(fontSize: 13, color: AppTheme.textDarkSecondary)),
                          AppStatusBadge(status: 'APPROVED', label: 'Offer Available'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        CurrencyUtils.formatAmount(amount),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryDarkTeal,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('Lender: ${journey.lender.name}', style: const TextStyle(fontSize: 12, color: AppTheme.textDarkSecondary)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Select Repayment Tenure', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDarkPrimary)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                children: offer.allowedTenures.map((tenure) {
                  final isSelected = _selectedTenureDays == tenure;
                  return ChoiceChip(
                    label: Text('$tenure Days'),
                    selected: isSelected,
                    selectedColor: AppTheme.primaryTeal,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.textDarkPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: isAccepted
                        ? null
                        : (selected) {
                            if (selected) {
                              setState(() => _selectedTenureDays = tenure);
                            }
                          },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _row('Interest Rate', '$interestRate% p.a.'),
                      _row('Processing Fee', CurrencyUtils.formatAmount(processingFee)),
                      _row('GST on Processing Fee (18%)', CurrencyUtils.formatAmount(gst, showDecimals: true)),
                      _row('Net Disbursal Amount', CurrencyUtils.formatAmount(netDisbursal, showDecimals: true), isHighlight: true),
                      const Divider(height: 20),
                      _row('Total Repayment Obligation', CurrencyUtils.formatAmount(totalRepayment, showDecimals: true), isHighlight: true),
                    ],
                  ),
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.errorBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_errorMessage!, style: const TextStyle(color: AppTheme.errorRed, fontSize: 13)),
                ),
              ],
              const SizedBox(height: 32),
              if (isAccepted)
                AppButton(
                  text: 'Offer Accepted - Continue to KYC',
                  onPressed: () => context.push('/loan/${widget.lan}/digilocker'),
                  icon: Icons.arrow_forward_rounded,
                )
              else
                AppButton(
                  text: 'Accept Loan Offer',
                  isLoading: _isAccepting,
                  onPressed: _acceptOffer,
                  icon: Icons.check_circle_outline,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String val, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textDarkSecondary)),
          Text(
            val,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
              color: isHighlight ? AppTheme.primaryTeal : AppTheme.textDarkPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
