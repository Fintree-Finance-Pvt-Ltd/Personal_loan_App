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
      await apiClient.post(
        '/customer/loans/${widget.lan}/kfs/generate',
        data: {'customerId': customerId},
      );
      await ref.read(journeyControllerProvider.notifier).syncCustomerState();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
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
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) setState(() => _isAccepting = false);
    }
  }

  void _openKfsViewer() {
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
            const Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('KEY FACT STATEMENT FOR PERSONAL LOAN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    SizedBox(height: 12),
                    Text(
                      '1. Loan Proposal Reference: PL-APP-2026-07\n'
                      '2. Sanctioned Amount: ₹50,000\n'
                      '3. Annualized Interest Rate: 18.0% per annum\n'
                      '4. Total Interest Chargeable: ₹1,479\n'
                      '5. Upfront Processing Fee: ₹998 (incl. GST)\n'
                      '6. Net Disbursal Amount: ₹49,002\n'
                      '7. Total Repayment Amount: ₹51,479\n'
                      '8. Penal Charges: 2% per month on overdue amount.\n\n'
                      'DECLARATION:\n'
                      'I have read, understood, and accept all parameters, repayment terms, and charges set out in this Key Fact Statement.',
                      style: TextStyle(fontSize: 13, height: 1.6, color: AppTheme.textDarkSecondary),
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
    final journey = ref.watch(journeyControllerProvider).postApproval;
    final offer = journey?.offer;
    final isAccepted = journey?.workflow.kfsAccepted == true;

    if (_isGenerating) {
      return Scaffold(
        appBar: AppBar(title: const Text('Key Fact Statement')),
        body: const AppLoader(message: 'Generating Key Fact Statement (KFS)...'),
      );
    }

    final amount = offer?.approvedAmount ?? 50000;
    final tenureDays = offer?.acceptedTenureDays ?? 60;
    final totalRepayment = offer?.acceptedTotalRepayment ?? (amount * 1.05);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Key Fact Statement (KFS)'),
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
                      _row('Sanctioned Amount', CurrencyUtils.formatAmount(amount)),
                      _row('Tenure', '$tenureDays Days'),
                      _row('Interest Rate', '18.0% p.a.'),
                      _row('Total Repayment Obligation', CurrencyUtils.formatAmount(totalRepayment, showDecimals: true), isBold: true),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _openKfsViewer,
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
