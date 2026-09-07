import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../../core/api/api_exception.dart';
import '../../../../app/theme.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../dashboard/presentation/journey_controller.dart';

class KfsScreen extends ConsumerStatefulWidget {
  final String lan;

  const KfsScreen({super.key, required this.lan});

  @override
  ConsumerState<KfsScreen> createState() => _KfsScreenState();
}

class _KfsScreenState extends ConsumerState<KfsScreen> {
  bool _isGenerating = false;
  bool _isAccepting = false;
  bool _termsAccepted = false;
  String? _errorMessage;
  Map<String, dynamic>? _kfsData;

  @override
  void initState() {
    super.initState();
    _generateKfs();
  }

  void _generateKfs() async {
    final customerId = ref.read(journeyControllerProvider).customer?.id;
    if (customerId == null) return;

    setState(() {
      _isGenerating = true;
      _errorMessage = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      final res = await apiClient.post(
        '/customer/loans/${widget.lan}/kfs/generate',
        data: {'customerId': customerId},
      );

      dynamic data = res;
      if (data is Map<String, dynamic> && data['data'] != null) {
        data = data['data'];
      }

      await ref.read(journeyControllerProvider.notifier).syncCustomerState();

      if (mounted) {
        setState(() {
          _kfsData = data is Map<String, dynamic> ? data : null;
        });
      }
    } catch (e) {
      String msg = e.toString();
      if (e is DioException) {
        final apiClient = ref.read(apiClientProvider);
        msg = apiClient.handleError(e).message;
      } else if (e is AppException) {
        msg = e.message;
      } else if (msg.startsWith('Exception: ')) {
        msg = msg.substring(11);
      }
      setState(() {
        _errorMessage = msg;
      });
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  void _acceptKfs() async {
    if (!_termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please accept the Key Fact Statement terms.')),
      );
      return;
    }

    final customerId = ref.read(journeyControllerProvider).customer?.id;
    if (customerId == null) return;

    setState(() {
      _isAccepting = true;
      _errorMessage = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.post(
        '/customer/loans/${widget.lan}/kfs/accept',
        data: {'customerId': customerId},
      );

      await ref.read(journeyControllerProvider.notifier).syncCustomerState();

      if (mounted) {
        context.push('/loan/${widget.lan}/mandate');
      }
    } catch (e) {
      String msg = e.toString();
      if (e is DioException) {
        final apiClient = ref.read(apiClientProvider);
        msg = apiClient.handleError(e).message;
      } else if (e is AppException) {
        msg = e.message;
      } else if (msg.startsWith('Exception: ')) {
        msg = msg.substring(11);
      }
      setState(() {
        _errorMessage = msg;
      });
    } finally {
      if (mounted) setState(() => _isAccepting = false);
    }
  }

  void _openKfsViewer({
    required String lan,
    required String borrowerName,
    required String borrowerPan,
    required String bankInfo,
    required double loanAmount,
    required double interestRate,
    required double totalInterest,
    required double totalCharges,
    required double netDisbursalAmount,
    required double totalRepaymentAmount,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.85,
        decoration: const BoxDecoration(
          color: AppTheme.surfaceWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Key Fact Statement (KFS)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('KEY FACT STATEMENT FOR PERSONAL LOAN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 12),
                    Text(
                      '1. Borrower Name: ${borrowerName.toUpperCase()}\n'
                      '2. PAN Number: ${borrowerPan.toUpperCase()}\n'
                      '3. Disbursal Account: $bankInfo\n'
                      '4. Loan Proposal / LAN: $lan\n'
                      '5. Sanctioned Amount: ${CurrencyUtils.formatAmount(loanAmount)}\n'
                      '6. Annualized Interest Rate: ${interestRate.toStringAsFixed(1)}% per annum\n'
                      '7. Total Interest Chargeable: ${CurrencyUtils.formatAmount(totalInterest, showDecimals: true)}\n'
                      '8. Upfront Processing Fee (incl. GST): ${CurrencyUtils.formatAmount(totalCharges, showDecimals: true)}\n'
                      '9. Net Disbursal Amount: ${CurrencyUtils.formatAmount(netDisbursalAmount, showDecimals: true)}\n'
                      '10. Total Repayment Amount: ${CurrencyUtils.formatAmount(totalRepaymentAmount, showDecimals: true)}\n'
                      '11. Penal Charges: 2% per month on overdue amount.\n\n'
                      'DECLARATION:\n'
                      'I have read, understood, and accept all parameters, repayment terms, and charges set out in this Key Fact Statement.',
                      style: const TextStyle(fontSize: 13, height: 1.6, color: AppTheme.textDarkSecondary),
                    ),
                  ],
                ),
              ),
            ),
            AppButton(
              text: 'I Have Reviewed KFS',
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customer = ref.watch(journeyControllerProvider).customer;
    final journey = ref.watch(journeyControllerProvider).postApproval;
    final offer = journey?.offer;
    final bank = journey?.bank;
    final isAccepted = journey?.workflow.kfsAccepted == true;

    if (_isGenerating) {
      return Scaffold(
        appBar: const AppHeader(title: 'Key Fact Statement'),
        body: const AppLoader(message: 'Generating Key Fact Statement (KFS)...'),
      );
    }

    final num rawLoanAmount = _kfsData?['loanAmount'] ?? offer?.approvedAmount ?? 50000;
    final double loanAmount = rawLoanAmount.toDouble();

    final int tenureDays = _kfsData?['tenureDays'] ?? offer?.acceptedTenureDays ?? 60;
    final double interestRate = (_kfsData?['interestRate'] ?? offer?.acceptedInterestRate ?? 18.0).toDouble();

    final double processingFee = (_kfsData?['processingFee'] ?? offer?.acceptedProcessingFee ?? (loanAmount * 0.02)).toDouble();
    final double processingFeeGst = (_kfsData?['processingFeeGst'] ?? (processingFee * 0.18)).toDouble();
    final double totalCharges = (_kfsData?['totalCharges'] ?? (processingFee + processingFeeGst)).toDouble();

    final double netDisbursalAmount = (_kfsData?['netDisbursalAmount'] ?? (loanAmount - totalCharges)).toDouble();
    final double totalInterest = (_kfsData?['totalInterest'] ?? (loanAmount * (interestRate / 100) * (tenureDays / 365))).toDouble();
    final double totalRepayment = (_kfsData?['totalRepaymentAmount'] ?? offer?.acceptedTotalRepayment ?? (loanAmount + totalInterest)).toDouble();

    final String borrowerName = customer?.fullName ?? _kfsData?['borrowerName'] ?? 'Valued Customer';
    final String borrowerPan = customer?.panNumber ?? _kfsData?['borrowerPan'] ?? 'N/A';

    final String bankName = _kfsData?['bankName'] ?? bank?.bankName ?? 'Bank Account';
    final String accountMasked = _kfsData?['accountMasked'] ?? bank?.accountMasked ?? 'Saved Account';
    final String bankInfo = '$bankName ($accountMasked)';

    return Scaffold(
      appBar: AppHeader(
        title: 'Key Fact Statement (KFS)',
        fallbackRoute: widget.lan.isNotEmpty ? '/loan/${widget.lan}/bank' : '/dashboard',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              const Text(
                'Key Fact Statement Summary',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textDarkPrimary),
              ),
              const SizedBox(height: 6),
              const Text(
                'Review regulatory loan summary and key terms before e-NACH mandate.',
                style: TextStyle(fontSize: 14, color: AppTheme.textDarkSecondary),
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('KFS Document Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          AppStatusBadge(status: isAccepted ? 'ACCEPTED' : 'GENERATED'),
                        ],
                      ),
                      const Divider(height: 20),
                      _row('Borrower Name', borrowerName),
                      _row('Sanctioned Amount', CurrencyUtils.formatAmount(loanAmount)),
                      _row('Tenure', '$tenureDays Days'),
                      _row('Interest Rate', '${interestRate.toStringAsFixed(1)}% p.a.'),
                      _row('Upfront Charges (Fee + GST)', CurrencyUtils.formatAmount(totalCharges, showDecimals: true)),
                      _row('Net Disbursal Amount', CurrencyUtils.formatAmount(netDisbursalAmount, showDecimals: true)),
                      _row('Total Repayment Obligation', CurrencyUtils.formatAmount(totalRepayment, showDecimals: true), isBold: true),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => _openKfsViewer(
                  lan: widget.lan,
                  borrowerName: borrowerName,
                  borrowerPan: borrowerPan,
                  bankInfo: bankInfo,
                  loanAmount: loanAmount,
                  interestRate: interestRate,
                  totalInterest: totalInterest,
                  totalCharges: totalCharges,
                  netDisbursalAmount: netDisbursalAmount,
                  totalRepaymentAmount: totalRepayment,
                ),
                icon: const Icon(Icons.picture_as_pdf_outlined, color: AppTheme.primaryTeal),
                label: const Text('View Complete KFS Document PDF'),
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: _termsAccepted,
                    activeColor: AppTheme.primaryTeal,
                    onChanged: (v) => setState(() => _termsAccepted = v == true),
                  ),
                  const Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(top: 10.0),
                      child: Text(
                        'I have read and accept the KFS, charges, repayment obligation and penal charge terms.',
                        style: TextStyle(fontSize: 13, color: AppTheme.textDarkSecondary, height: 1.4),
                      ),
                    ),
                  ),
                ],
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
                  text: 'KFS Accepted - Proceed to Mandate',
                  onPressed: () => context.push('/loan/${widget.lan}/mandate'),
                  icon: Icons.arrow_forward_rounded,
                )
              else
                AppButton(
                  text: 'Accept KFS Terms',
                  isLoading: _isAccepting,
                  onPressed: _acceptKfs,
                  icon: Icons.check_circle_outline,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String val, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textDarkSecondary)),
          Text(val, style: TextStyle(fontSize: 13, fontWeight: isBold ? FontWeight.bold : FontWeight.w600, color: AppTheme.textDarkPrimary)),
        ],
      ),
    );
  }
}
