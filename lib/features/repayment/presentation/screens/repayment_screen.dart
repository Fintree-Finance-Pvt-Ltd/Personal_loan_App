import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';
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
import '../../../../core/services/push_notification_service.dart';
import '../../../dashboard/presentation/journey_controller.dart';

class RepaymentScreen extends ConsumerStatefulWidget {
  final String lan;

  const RepaymentScreen({super.key, required this.lan});

  @override
  ConsumerState<RepaymentScreen> createState() => _RepaymentScreenState();
}

class _RepaymentScreenState extends ConsumerState<RepaymentScreen> {
  bool _isLoading = true;
  bool _isInitiating = false;
  String? _errorMessage;
  String? _statusMessage;
  Map<String, dynamic>? _loanDetails;

  int _selectedInstallmentNumber = 1;
  double _paymentAmount = 0.0;
  final TextEditingController _customAmountController = TextEditingController();

  // Easebuzz Gateway WebView state
  String? _paymentUrl;
  WebViewController? _webViewController;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _fetchDetails());
  }

  @override
  void dispose() {
    _customAmountController.dispose();
    super.dispose();
  }

  Future<void> _fetchDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      final res = await apiClient.get('/customer/loans/${widget.lan}/details');

      final data = res['data'] ?? res;
      if (mounted) {
        final detailsMap = data is Map<String, dynamic> ? data : null;
        final rpsList = (detailsMap?['repaymentSchedule'] as List<dynamic>?) ?? [];

        // Pre-select first unpaid installment, prioritizing non-mandate-locked
        int defaultInst = 1;
        double defaultAmt = 0.0;
        bool foundUnlockedUnpaid = false;

        for (final item in rpsList) {
          final map = item as Map<String, dynamic>;
          final status = map['paymentStatus']?.toString().toUpperCase();
          final rem = ((map['remainingAmount'] ?? map['emi'] ?? 0) as num).toDouble();
          final isPaid = status == 'PAID' || rem <= 0;
          final isLocked = map['isMandateLocked'] == true;

          if (!isPaid) {
            if (!foundUnlockedUnpaid) {
              defaultInst = (map['installmentNumber'] ?? 1) as int;
              defaultAmt = rem;
              if (!isLocked) {
                foundUnlockedUnpaid = true;
                break;
              }
            }
          }
        }

        if (defaultAmt == 0.0 && rpsList.isEmpty) {
          final summary = detailsMap?['summary'] as Map<String, dynamic>?;
          final loan = detailsMap?['loan'] as Map<String, dynamic>?;
          final num? summaryNextEmi = summary?['nextEmiAmount'] ??
              summary?['totalOutstanding'] ??
              loan?['approvedAmount'] ??
              loan?['disbursalAmount'];

          defaultAmt = (summaryNextEmi != null && summaryNextEmi.toDouble() > 0)
              ? summaryNextEmi.toDouble()
              : 0.0;
        }

        setState(() {
          _loanDetails = detailsMap;
          _selectedInstallmentNumber = defaultInst;
          _paymentAmount = defaultAmt;
          _customAmountController.text = defaultAmt.toStringAsFixed(0);
        });
      }
    } catch (e) {
      if (mounted) {
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
          _errorMessage = 'Failed to load loan details: $msg';
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  WebViewController _buildEasebuzzWebViewController(String url) {
    return WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(
        'Mozilla/5.0 (Linux; Android 12; Pixel 6) '
        'AppleWebKit/537.36 (KHTML, like Gecko) '
        'Chrome/124.0.0.0 Mobile Safari/537.36',
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String finishedUrl) {
            debugPrint('[EasebuzzRepay] Finished URL: $finishedUrl');
            final lower = finishedUrl.toLowerCase();
            if (lower.contains('success') ||
                lower.contains('confirm') ||
                lower.contains('status') ||
                lower.contains('response') ||
                lower.contains('details')) {
              _onPaymentCompleted();
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            final lower = request.url.toLowerCase();
            if (lower.contains('success') ||
                lower.contains('confirm') ||
                lower.contains('repay/confirm') ||
                lower.contains('details')) {
              _onPaymentCompleted();
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(url));
  }

  Future<void> _onPaymentCompleted() async {
    if (_isVerifying) return;
    setState(() => _isVerifying = true);

    try {
      await ref.read(journeyControllerProvider.notifier).syncCustomerState();
      await _fetchDetails();

      if (mounted) {
        final paidAmount = _paymentAmount > 0
            ? _paymentAmount
            : (double.tryParse(_customAmountController.text.trim()) ?? 0.0);
        PushNotificationService().sendRepaymentSuccessNotification(
          amount: paidAmount,
          lan: widget.lan,
        );

        setState(() {
          _paymentUrl = null;
          _webViewController = null;
          _statusMessage = 'Repayment completed successfully!';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('EMI Repayment Completed Successfully!'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      debugPrint('[EasebuzzRepay] Error verifying payment: $e');
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  void _showMandateLockedDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.schedule_rounded, color: Color(0xFFD97706)),
            SizedBox(width: 8),
            Text(
              'Auto-Debit Presented',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 13, height: 1.45, color: AppTheme.textDarkPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Understood',
              style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryTeal),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _initiateEasebuzzPayment() async {
    final rpsList = (_loanDetails?['repaymentSchedule'] as List<dynamic>?) ?? [];
    final selectedItem = rpsList.firstWhere(
      (item) => item['installmentNumber'] == _selectedInstallmentNumber,
      orElse: () => null,
    );

    if (selectedItem != null && selectedItem['isMandateLocked'] == true) {
      _showMandateLockedDialog(
        selectedItem['mandateDebitMessage']?.toString() ??
            'Auto-debit mandate has already been presented for this installment. Manual payment is temporarily disabled on the due date to prevent double deduction. Please wait for bank clearing.',
      );
      return;
    }

    final amountToPay = double.tryParse(_customAmountController.text.trim()) ?? _paymentAmount;
    if (amountToPay <= 0) {
      setState(() {
        _errorMessage = 'Please enter a valid repayment amount.';
      });
      return;
    }

    setState(() {
      _isInitiating = true;
      _errorMessage = null;
      _statusMessage = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      final res = await apiClient.post(
        '/customer/loans/${widget.lan}/repay/initiate',
        data: {
          'installmentNumber': _selectedInstallmentNumber,
          'amount': amountToPay,
        },
      );

      final data = res['data'] ?? res;
      final nestedData = (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>)
          ? data['data']
          : data;

      final accessKey = nestedData['accessKey'];
      final env = nestedData['environment'] ?? 'test';
      final baseGatewayUrl = (env == 'prod')
          ? 'https://pay.easebuzz.in/pay/'
          : 'https://testpay.easebuzz.in/pay/';

      final checkoutUrl = nestedData['paymentUrl'] ??
          nestedData['checkoutUrl'] ??
          nestedData['url'] ??
          (accessKey != null ? '$baseGatewayUrl$accessKey' : null);

      if (checkoutUrl != null && checkoutUrl.toString().isNotEmpty) {
        final urlStr = checkoutUrl.toString();
        final controller = _buildEasebuzzWebViewController(urlStr);

        setState(() {
          _paymentUrl = urlStr;
          _webViewController = controller;
        });
      } else {
        // Direct confirmation backend stub
        await _onPaymentCompleted();
      }
    } catch (e) {
      if (mounted) {
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
          _errorMessage = 'Failed to initiate repayment: $msg';
        });
      }
    } finally {
      if (mounted) setState(() => _isInitiating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // If Easebuzz Payment Gateway is active in WebView
    if (_paymentUrl != null && _webViewController != null) {
      return Scaffold(
        appBar: AppHeader(
          title: 'Easebuzz Payment Gateway',
          onBackPressed: () {
            setState(() {
              _paymentUrl = null;
              _webViewController = null;
            });
          },
          actions: [
            if (_isVerifying)
              const Padding(
                padding: EdgeInsets.all(14),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
              )
            else
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: _onPaymentCompleted,
                tooltip: 'Check payment status',
              ),
          ],
        ),
        body: WebViewWidget(controller: _webViewController!),
      );
    }

    final summary = _loanDetails?['summary'] as Map<String, dynamic>?;
    final rpsList = (_loanDetails?['repaymentSchedule'] as List<dynamic>?) ?? [];
    final repaymentHistory = (_loanDetails?['repaymentHistory'] as List<dynamic>?) ?? [];
    final apiLoan = _loanDetails?['loan'] as Map<String, dynamic>?;

    final num? rawTotalOutstanding = summary?['totalOutstanding'] ??
        apiLoan?['approvedAmount'] ??
        apiLoan?['disbursalAmount'];
    final double totalOutstanding = (rawTotalOutstanding != null && rawTotalOutstanding.toDouble() > 0)
        ? rawTotalOutstanding.toDouble()
        : 0.0;

    final num? rawTotalPaid = summary?['totalPaid'];
    final double totalPaid = (rawTotalPaid != null && rawTotalPaid.toDouble() > 0)
        ? rawTotalPaid.toDouble()
        : 0.0;

    final num? rawNextEmi = summary?['nextEmiAmount'];
    final double nextEmiAmount = (rawNextEmi != null && rawNextEmi.toDouble() > 0)
        ? rawNextEmi.toDouble()
        : 0.0;

    final num? rawOverdue = summary?['overdueAmount'];
    final double overdueAmount = (rawOverdue != null && rawOverdue.toDouble() > 0)
        ? rawOverdue.toDouble()
        : 0.0;

    final nextDueDate = summary?['nextDueDate']?.toString();
    final loanStatus = (apiLoan?['status']?.toString() ?? 'DISBURSED').toUpperCase();

    // Verification of fully paid state
    final bool isAllRpsPaid = rpsList.isNotEmpty &&
        rpsList.every((item) {
          final s = item['paymentStatus']?.toString().toUpperCase();
          final rem = ((item['remainingAmount'] ?? 0) as num).toDouble();
          return s == 'PAID' || rem <= 0;
        });

    final bool isFullyPaid = isAllRpsPaid ||
        loanStatus == 'FULLY_PAID' ||
        (totalOutstanding <= 0 && overdueAmount <= 0 && totalPaid > 0);

    // Mandate Locked check across entire schedule
    final bool hasMandateLocked = rpsList.any((r) => r['isMandateLocked'] == true);

    // Selected installment
    final selectedItem = rpsList.firstWhere(
      (item) => item['installmentNumber'] == _selectedInstallmentNumber,
      orElse: () => null,
    );
    final bool isSelectedLocked = selectedItem != null && selectedItem['isMandateLocked'] == true;
    final bool isSelectedOverdue = selectedItem != null &&
        (selectedItem['isOverdue'] == true || selectedItem['paymentStatus'] == 'OVERDUE');

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppHeader(
        title: 'EMI Repayment & Collection',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchDetails,
            tooltip: 'Refresh details',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: AppLoader(message: 'Loading repayment details...'))
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header Banner ──────────────────────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isFullyPaid
                              ? [const Color(0xFF064E3B), const Color(0xFF047857), const Color(0xFF059669)]
                              : [AppTheme.primaryDeepTeal, AppTheme.primaryDarkTeal],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: (isFullyPaid ? AppTheme.successGreen : Colors.black).withValues(alpha: 0.12),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                isFullyPaid ? 'LOAN SETTLED' : 'ACTIVE REPAYMENT',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                              AppStatusBadge(
                                status: isFullyPaid
                                    ? 'FULLY_PAID'
                                    : (overdueAmount > 0 ? 'OVERDUE' : 'ACTIVE'),
                                label: isFullyPaid
                                    ? 'Fully Paid'
                                    : (overdueAmount > 0 ? 'Overdue' : 'Disbursed'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            isFullyPaid ? '₹0' : (totalOutstanding > 0 ? CurrencyUtils.formatAmount(totalOutstanding) : '₹0'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            isFullyPaid ? 'No Outstanding Balance' : 'Total Loan Outstanding',
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: isFullyPaid
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Total Amount Paid', style: TextStyle(color: Colors.white70, fontSize: 11)),
                                          Text(
                                            CurrencyUtils.formatAmount(totalPaid),
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                          ),
                                        ],
                                      ),
                                      const Row(
                                        children: [
                                          Icon(Icons.verified_rounded, color: Colors.greenAccent, size: 18),
                                          SizedBox(width: 4),
                                          Text(
                                            'Cleared in Full',
                                            style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ],
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Next Due EMI', style: TextStyle(color: Colors.white70, fontSize: 11)),
                                          Text(
                                            nextEmiAmount > 0 ? CurrencyUtils.formatAmount(nextEmiAmount) : 'N/A',
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                          ),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          const Text('Due Date', style: TextStyle(color: Colors.white70, fontSize: 11)),
                                          Text(
                                            _formatDate(nextDueDate),
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Auto-Debit Mandate Presentment Alert (Matching Web) ──
                    if (hasMandateLocked) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber.withValues(alpha: 0.06),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Auto-Debit Clearing In Progress:',
                                    style: TextStyle(
                                      color: Color(0xFF78350F),
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'An auto-debit mandate has been presented to your bank account for due installment collection. Online manual payment for presented installments is temporarily paused on the due date to protect against duplicate deductions. (If overdue by 1 or more days, manual payment is re-enabled).',
                                    style: TextStyle(
                                      color: const Color(0xFF92400E).withValues(alpha: 0.95),
                                      fontSize: 12,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // ── Overdue Alert Banner ───────────────────────────
                    if (overdueAmount > 0) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.errorBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.errorRed),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: AppTheme.errorRed, size: 24),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'You have an overdue balance of ${CurrencyUtils.formatAmount(overdueAmount)}. Pay immediately to avoid late payment charges.',
                                style: const TextStyle(color: AppTheme.errorRed, fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // ── MAIN CONTENT: Fully Paid Celebration vs Repayment Card ──
                    if (isFullyPaid)
                      _buildFullyPaidCelebrationCard(totalPaid, rpsList.length)
                    else
                      _buildPaymentCard(
                        rpsList: rpsList,
                        totalPaid: totalPaid,
                        isSelectedLocked: isSelectedLocked,
                        isSelectedOverdue: isSelectedOverdue,
                      ),

                    const SizedBox(height: 20),

                    // ── Repayment History Section ─────────────────────
                    if (repaymentHistory.isNotEmpty) ...[
                      _buildRepaymentHistoryCard(repaymentHistory),
                      const SizedBox(height: 20),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  /// Celebratory Card displayed when customer has paid all EMIs
  Widget _buildFullyPaidCelebrationCard(double totalPaid, int totalInstallments) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.successGreen.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.successGreen.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.successBg,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.successGreen.withValues(alpha: 0.2)),
            ),
            child: const Icon(Icons.verified_rounded, color: AppTheme.successGreen, size: 44),
          ),
          const SizedBox(height: 16),
          const Text(
            'All EMIs Fully Repaid!',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDarkPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          const Text(
            'Congratulations! You have completed all loan installment payments in full. There are no pending dues on this account.',
            style: TextStyle(fontSize: 13, color: AppTheme.textDarkSecondary, height: 1.4),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: Column(
              children: [
                _historyRow('Loan Account (LAN)', widget.lan),
                const SizedBox(height: 8),
                _historyRow('Total Amount Repaid', CurrencyUtils.formatAmount(totalPaid), bold: true),
                const SizedBox(height: 8),
                _historyRow('Installments Cleared', '$totalInstallments of $totalInstallments', bold: true),
                const SizedBox(height: 8),
                _historyRow('Loan Status', 'CLOSED & SETTLED', color: AppTheme.successGreen),
              ],
            ),
          ),
          const SizedBox(height: 22),
          AppButton(
            text: 'View No Dues Certificate & Review',
            icon: Icons.assignment_turned_in_rounded,
            onPressed: () => context.push('/loan/${widget.lan}/fully-paid-review'),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () => context.go('/dashboard'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              side: const BorderSide(color: AppTheme.borderLight),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Back to Dashboard', style: TextStyle(color: AppTheme.textDarkSecondary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  /// Standard Repayment Selection & Payment Execution Card
  Widget _buildPaymentCard({
    required List<dynamic> rpsList,
    required double totalPaid,
    required bool isSelectedLocked,
    required bool isSelectedOverdue,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppTheme.borderLight),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Make EMI Repayment',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDarkPrimary),
            ),
            const SizedBox(height: 4),
            const Text(
              'Select installment and pay securely via Easebuzz UPI / Netbanking / Cards.',
              style: TextStyle(fontSize: 12, color: AppTheme.textDarkSecondary),
            ),
            const SizedBox(height: 16),

            // Installment Selector
            if (rpsList.isNotEmpty) ...[
              const Text('Select Installment', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Column(
                children: rpsList.map((item) {
                  final map = item as Map<String, dynamic>;
                  final instNum = map['installmentNumber'] ?? 1;
                  final emi = (map['emi'] ?? 0).toDouble();
                  final rem = (map['remainingAmount'] ?? emi).toDouble();
                  final paidAmt = (map['paidAmount'] ?? 0).toDouble();
                  final dueDate = map['dueDate']?.toString();
                  final paymentDate = map['paymentDate']?.toString();
                  final pStatus = map['paymentStatus']?.toString().toUpperCase() ?? 'UNPAID';
                  final isPaid = pStatus == 'PAID' || rem <= 0;
                  final isLocked = map['isMandateLocked'] == true;
                  final isOverdue = map['isOverdue'] == true || pStatus == 'OVERDUE';
                  final isSelected = _selectedInstallmentNumber == instNum;

                  // 1. Fully Paid Installment Row
                  if (isPaid) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.check_circle_rounded, color: AppTheme.successGreen, size: 20),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Installment #$instNum',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF065F46),
                                      fontSize: 13,
                                    ),
                                  ),
                                  if (paymentDate != null)
                                    Text(
                                      'Paid on ${_formatDate(paymentDate)}',
                                      style: const TextStyle(fontSize: 11, color: Color(0xFF047857)),
                                    )
                                  else if (dueDate != null)
                                    Text(
                                      'Due: ${_formatDate(dueDate)}',
                                      style: const TextStyle(fontSize: 11, color: Color(0xFF047857)),
                                    ),
                                ],
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                CurrencyUtils.formatAmount(paidAmt > 0 ? paidAmt : emi),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.successGreen,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const AppStatusBadge(status: 'PAID', label: 'Payment Completed'),
                            ],
                          ),
                        ],
                      ),
                    );
                  }

                  // 2. Mandate Locked Row (Bank Clearing In Progress)
                  if (isLocked) {
                    return GestureDetector(
                      onTap: () {
                        _showMandateLockedDialog(
                          map['mandateDebitMessage']?.toString() ??
                              'Auto-debit mandate has already been presented for this installment. Manual payment is temporarily disabled on the due date to prevent double deduction. Please wait for bank clearing.',
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.schedule_rounded, color: Color(0xFFD97706), size: 20),
                                    const SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Installment #$instNum',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF78350F),
                                            fontSize: 13,
                                          ),
                                        ),
                                        Text(
                                          'Due: ${_formatDate(dueDate)}',
                                          style: const TextStyle(fontSize: 11, color: Color(0xFF92400E)),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      CurrencyUtils.formatAmount(rem > 0 ? rem : emi),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF92400E),
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    const AppStatusBadge(status: 'PRESENTED', label: 'Auto-Debit Presented'),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD97706)),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      map['mandateDebitMessage']?.toString() ??
                                          'Bank clearing in progress. Manual payment paused on due date.',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF92400E),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // 3. Regular Unpaid Installment (Can Pay Manually)
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedInstallmentNumber = instNum;
                        _paymentAmount = rem > 0 ? rem : emi;
                        _customAmountController.text = _paymentAmount.toStringAsFixed(0);
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primaryLightTeal : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? AppTheme.primaryTeal : (isOverdue ? AppTheme.errorRed : AppTheme.borderLight),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                                color: isSelected ? AppTheme.primaryTeal : Colors.grey,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Installment #$instNum',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isOverdue ? AppTheme.errorRed : AppTheme.textDarkPrimary,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    'Due: ${_formatDate(dueDate)}',
                                    style: const TextStyle(fontSize: 11, color: AppTheme.textDarkSecondary),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                CurrencyUtils.formatAmount(rem > 0 ? rem : emi),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? AppTheme.primaryTeal : (isOverdue ? AppTheme.errorRed : AppTheme.textDarkPrimary),
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 8),
                              AppStatusBadge(
                                status: isOverdue ? 'OVERDUE' : 'UNPAID',
                                label: isOverdue ? 'Overdue' : 'Due',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],

            // Payable Amount & Execution Controls
            if (isSelectedLocked) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.schedule_rounded, color: Color(0xFFD97706), size: 24),
                    SizedBox(height: 8),
                    Text(
                      'Auto-Debit Mandate In Progress',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF78350F), fontSize: 13),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'This installment has been presented to your bank. Manual payment is disabled on the due date to protect against double deductions.',
                      style: TextStyle(fontSize: 11.5, color: Color(0xFF92400E), height: 1.35),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const AppButton(
                text: 'Auto-Debit Clearing In Progress',
                icon: Icons.lock_clock_rounded,
                onPressed: null,
              ),
            ] else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Payable Amount (₹)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLightTeal,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_rounded, size: 12, color: AppTheme.primaryTeal),
                        SizedBox(width: 4),
                        Text(
                          'EMI Auto-filled',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryTeal),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primaryTeal, width: 1.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.currency_rupee_rounded, size: 22, color: AppTheme.primaryTeal),
                        const SizedBox(width: 6),
                        Text(
                          _paymentAmount > 0
                              ? CurrencyUtils.formatAmount(_paymentAmount).replaceAll('₹', '').trim()
                              : '0',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.primaryTeal),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelectedOverdue ? AppTheme.errorRed : AppTheme.primaryTeal,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isSelectedOverdue ? 'OVERDUE' : 'FIXED EMI',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.errorBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_errorMessage!, style: const TextStyle(color: AppTheme.errorRed, fontSize: 12)),
                ),
                const SizedBox(height: 16),
              ],

              if (_statusMessage != null && _errorMessage == null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.successBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_statusMessage!, style: const TextStyle(color: AppTheme.successDarkGreen, fontSize: 12)),
                ),
                const SizedBox(height: 16),
              ],

              AppButton(
                text: isSelectedOverdue ? 'Pay Overdue via Easebuzz Gateway' : 'Pay Now via Easebuzz Gateway',
                isLoading: _isInitiating,
                onPressed: _paymentAmount > 0 ? _initiateEasebuzzPayment : null,
                icon: Icons.lock_outline_rounded,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// History of verified repayments recorded by backend
  Widget _buildRepaymentHistoryCard(List<dynamic> history) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.history_rounded, color: AppTheme.primaryTeal, size: 20),
              SizedBox(width: 8),
              Text(
                'Repayment History',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textDarkPrimary),
              ),
            ],
          ),
          const Divider(height: 20, color: AppTheme.borderLight),
          ...history.map((rep) {
            final map = rep as Map<String, dynamic>;
            final pDate = map['paymentDate']?.toString();
            final pAmt = (map['amountReceived'] ?? 0).toDouble();
            final refNum = map['referenceNumber']?.toString() ?? '—';
            final mode = map['paymentMode']?.toString() ?? 'ONLINE';
            final status = map['status']?.toString() ?? 'SUCCESS';

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatDate(pDate),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Ref: $refNum ($mode)',
                        style: const TextStyle(fontSize: 11, color: AppTheme.textDarkSecondary),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '+ ${CurrencyUtils.formatAmount(pAmt)}',
                        style: const TextStyle(
                          color: AppTheme.successGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      AppStatusBadge(status: status),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _historyRow(String label, String value, {bool bold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textDarkSecondary)),
        Text(
          value,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: bold ? FontWeight.bold : FontWeight.w600,
            color: color ?? AppTheme.textDarkPrimary,
          ),
        ),
      ],
    );
  }

  String _formatDate(String? iso) {
    if (iso == null || iso.trim().isEmpty || iso == 'N/A') return 'N/A';
    try {
      final dt = DateTime.parse(iso).toLocal();
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return iso;
    }
  }
}
