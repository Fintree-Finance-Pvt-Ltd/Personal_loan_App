import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../../dashboard/presentation/journey_controller.dart';

class DisbursalScreen extends ConsumerStatefulWidget {
  final String lan;

  const DisbursalScreen({super.key, required this.lan});

  @override
  ConsumerState<DisbursalScreen> createState() => _DisbursalScreenState();
}

class _DisbursalScreenState extends ConsumerState<DisbursalScreen> {
  bool _isRequesting = false;
  String? _errorMessage;

  void _requestDisbursal() async {
    final customerId = ref.read(journeyControllerProvider).customer?.id;
    if (customerId == null) return;

    setState(() {
      _isRequesting = true;
      _errorMessage = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.post(
        '/customer/loans/${widget.lan}/disbursal/request',
        data: {'customerId': customerId},
      );

      await ref.read(journeyControllerProvider.notifier).syncCustomerState();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) setState(() => _isRequesting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final postApproval = ref.watch(journeyControllerProvider).postApproval;
    final loan = postApproval?.loan;
    final bank = postApproval?.bank;
    final disbursalStatus = postApproval?.workflow.disbursalStatus ?? 'NOT_STARTED';
    final isDisbursed = disbursalStatus == 'DISBURSED';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Disbursal Request'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: AppTheme.surfaceWhite,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 4),
                    ],
                  ),
                  child: Icon(
                    isDisbursed ? Icons.check_circle_rounded : Icons.account_balance_rounded,
                    size: 64,
                    color: isDisbursed ? AppTheme.successGreen : AppTheme.primaryTeal,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  isDisbursed ? 'Loan Disbursed Successfully!' : 'Ready for Disbursal',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textDarkPrimary),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  isDisbursed
                      ? 'Funds have been transferred to your verified bank account.'
                      : 'All post-approval milestones complete. Request instant transfer to your bank.',
                  style: const TextStyle(fontSize: 14, color: AppTheme.textDarkSecondary),
                  textAlign: TextAlign.center,
                ),
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
                          const Text('Disbursal Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          AppStatusBadge(status: disbursalStatus),
                        ],
                      ),
                      const Divider(height: 20),
                      _row('Loan Account No. (LAN)', loan?.lan ?? widget.lan),
                      _row('Approved Amount', CurrencyUtils.formatAmount(loan?.approvedAmount ?? 50000)),
                      _row('Destination Bank Account', Formatters.maskBankAccount(bank?.accountMasked)),
                      if (isDisbursed) ...[
                        _row('UTR Reference', 'UTR20260728987654'),
                        _row('Disbursal Date', '28 Jul 2026'),
                      ],
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
              const Spacer(),
              if (isDisbursed)
                AppButton(
                  text: 'Go to Dashboard',
                  onPressed: () => context.go('/dashboard'),
                  icon: Icons.dashboard_rounded,
                )
              else if (_isRequesting)
                const AppLoader(message: 'Requesting disbursal with payment system...')
              else
                AppButton(
                  text: 'Request Instant Disbursal',
                  onPressed: _requestDisbursal,
                  icon: Icons.flash_on_rounded,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String val) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textDarkSecondary)),
          Text(val, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textDarkPrimary)),
        ],
      ),
    );
  }
}
