import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../../core/api/api_exception.dart';
import '../../../../app/theme.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/services/push_notification_service.dart';
import '../../../dashboard/presentation/journey_controller.dart';

class LoanDetailsScreen extends ConsumerStatefulWidget {
  final String lan;
  const LoanDetailsScreen({super.key, required this.lan});

  @override
  ConsumerState<LoanDetailsScreen> createState() => _LoanDetailsScreenState();
}

class _LoanDetailsScreenState extends ConsumerState<LoanDetailsScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _loanDetailsData;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _fetchLoanDetails());
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _checkAndStartPolling() {
    _pollingTimer?.cancel();
    final apiLoan = _loanDetailsData?['loan'] as Map<String, dynamic>?;
    final status = apiLoan?['status']?.toString().toUpperCase() ?? '';
    final disbursalStatus = apiLoan?['disbursalStatus']?.toString().toUpperCase() ?? '';

    final isDisbursed = status == 'DISBURSED' || status == 'FULLY_PAID' || disbursalStatus == 'DISBURSED';

    if (!isDisbursed) {
      _pollingTimer = Timer.periodic(const Duration(seconds: 4), (timer) async {
        if (!mounted) {
          timer.cancel();
          return;
        }
        await _fetchLoanDetails(showLoading: false);
        final updatedLoan = _loanDetailsData?['loan'] as Map<String, dynamic>?;
        final updatedStatus = updatedLoan?['status']?.toString().toUpperCase() ?? '';
        final updatedDisbursalStatus = updatedLoan?['disbursalStatus']?.toString().toUpperCase() ?? '';
        if (updatedStatus == 'DISBURSED' || updatedStatus == 'FULLY_PAID' || updatedDisbursalStatus == 'DISBURSED') {
          timer.cancel();
          ref.read(journeyControllerProvider.notifier).syncCustomerState();
        }
      });
    }
  }

  Future<void> _fetchLoanDetails({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final customerApi = ref.read(customerApiProvider);
      final res = await customerApi.getCustomerLoanDetails(widget.lan);
      
      final data = res['data'] ?? res;
      if (mounted) {
        setState(() {
          _loanDetailsData = data is Map<String, dynamic> ? data : null;
        });

        // Schedule EMI Reminders (3 days before, 1 day before, and due date with Pay Now button)
        if (_loanDetailsData != null) {
          final loanMap = _loanDetailsData!['loan'] as Map<String, dynamic>?;
          final nextEmi = _loanDetailsData!['nextEmi'] as Map<String, dynamic>? ?? loanMap;
          if (nextEmi != null) {
            final rawAmount = nextEmi['amount'] ?? nextEmi['emiAmount'] ?? nextEmi['nextEmiAmount'];
            final rawDueDate = nextEmi['dueDate'] ?? nextEmi['nextEmiDueDate'];
            if (rawAmount != null && rawDueDate != null) {
              final amount = (rawAmount is num) ? rawAmount.toDouble() : double.tryParse(rawAmount.toString()) ?? 0.0;
              final dueDate = DateTime.tryParse(rawDueDate.toString());
              if (dueDate != null && amount > 0) {
                PushNotificationService().scheduleEmiReminders(
                  lan: widget.lan,
                  amount: amount,
                  dueDate: dueDate,
                );
              }
            }
          }
        }

        _checkAndStartPolling();
      }
    } catch (e) {
      if (mounted && showLoading) {
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
      }
    } finally {
      if (mounted && showLoading) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _initiateRepayment(
    int installmentNumber,
    num amount, {
    bool isMandateLocked = false,
    String? mandateDebitMessage,
  }) async {
    if (isMandateLocked) {
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
            mandateDebitMessage ??
                'Auto-debit mandate has already been presented for this installment. Manual payment is temporarily disabled on the due date to prevent double deduction. Please wait for bank clearing.',
            style: const TextStyle(fontSize: 13, height: 1.45, color: AppTheme.textDarkPrimary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Understood', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryTeal)),
            ),
          ],
        ),
      );
      return;
    }

    // Navigate to full Easebuzz Payment Gateway WebView screen for complete payment flow
    context.push('/loan/${widget.lan}/repay');
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(appLocalizationsProvider);
    final postApproval = ref.watch(journeyControllerProvider).postApproval;
    final fallbackLoan = postApproval?.loan;
    final fallbackOffer = postApproval?.offer;
    final bank = postApproval?.bank;
    final customer = ref.watch(journeyControllerProvider).customer;

    // Parsed API Data
    final apiLoan = _loanDetailsData?['loan'] as Map<String, dynamic>?;
    final summary = _loanDetailsData?['summary'] as Map<String, dynamic>?;
    final rpsList = (_loanDetailsData?['repaymentSchedule'] as List<dynamic>?) ?? [];
    final repaymentHistory = (_loanDetailsData?['repaymentHistory'] as List<dynamic>?) ?? [];

    final status = (apiLoan?['status']?.toString() ?? fallbackLoan?.status ?? 'PROCESSING').toUpperCase();
    final disbursalStatus = (apiLoan?['disbursalStatus']?.toString() ?? fallbackLoan?.disbursalStatus ?? '').toUpperCase();
    final isDisbursed = status == 'DISBURSED' || status == 'FULLY_PAID' || disbursalStatus == 'DISBURSED';

    final num? rawApproved = apiLoan?['approvedAmount'] ??
        apiLoan?['disbursedAmount'] ??
        apiLoan?['amount'] ??
        fallbackLoan?.approvedAmount ??
        fallbackLoan?.disbursalAmount ??
        fallbackOffer?.approvedAmount;

    final double? approvedAmount = (rawApproved != null && rawApproved.toDouble() > 0)
        ? rawApproved.toDouble()
        : null;

    final double rawDisbursed = (apiLoan?['disbursedAmount'] ?? fallbackLoan?.disbursalAmount ?? 0).toDouble();
    final double? disbursedAmount = rawDisbursed > 0 ? rawDisbursed : null;

    final double rawOutstanding = (summary?['totalOutstanding'] ?? 0).toDouble();
    final double? totalOutstanding = rawOutstanding > 0 ? rawOutstanding : null;

    final double rawPaid = (summary?['totalPaid'] ?? 0).toDouble();
    final double? totalPaid = rawPaid > 0 ? rawPaid : (summary?['totalPaid'] != null ? 0.0 : null);

    final double overdueAmount = (summary?['overdueAmount'] ?? 0).toDouble();

    final num? rawNextEmi = summary?['nextEmiAmount'] ?? fallbackOffer?.acceptedEmiAmount;
    final double? nextEmiAmount = (rawNextEmi != null && rawNextEmi.toDouble() > 0) ? rawNextEmi.toDouble() : null;
    final nextDueDate = summary?['nextDueDate']?.toString();

    // Construct effective RPS list if rawRpsList is empty but loan is disbursed or has approved amount
    List<Map<String, dynamic>> effectiveRpsList = rpsList.map((e) => Map<String, dynamic>.from(e as Map)).toList();

    if (effectiveRpsList.isEmpty && (isDisbursed || approvedAmount != null || disbursedAmount != null)) {
      final double baseAmt = (approvedAmount != null && approvedAmount > 0)
          ? approvedAmount
          : ((disbursedAmount != null && disbursedAmount > 0) ? disbursedAmount : 0.0);

      if (baseAmt > 0) {
        final num? tenureNum = apiLoan?['tenure'] ?? fallbackOffer?.acceptedTenureDays ?? 40;
        final int tenureDays = (tenureNum != null && tenureNum > 0) ? tenureNum.toInt() : 40;
        final num? interestNum = apiLoan?['interestRate'] ?? fallbackOffer?.acceptedInterestRate ?? 1;
        final double interestRatePercent = (interestNum != null && interestNum > 0) ? interestNum.toDouble() : 1.0;

        final double totalInterest = (baseAmt * interestRatePercent * tenureDays) / 3650.0;
        final double emiVal = (nextEmiAmount != null && nextEmiAmount > 0) ? nextEmiAmount : (baseAmt + totalInterest);

        final rawDisbursalDate = apiLoan?['disbursalDate'] ?? fallbackLoan?.disbursalCompletedAt ?? fallbackLoan?.disbursalDate;
        DateTime startDate = DateTime.now();
        if (rawDisbursalDate != null && rawDisbursalDate.toString().isNotEmpty) {
          final parsed = DateTime.tryParse(rawDisbursalDate.toString());
          if (parsed != null) startDate = parsed;
        }

        DateTime dueDt = startDate.add(Duration(days: tenureDays));
        if (nextDueDate != null && nextDueDate.isNotEmpty) {
          final parsedDue = DateTime.tryParse(nextDueDate.toString());
          if (parsedDue != null) dueDt = parsedDue;
        }

        final bool isPaid = totalOutstanding == 0 || (totalPaid != null && totalPaid >= emiVal);
        final bool isOverdue = !isPaid && DateTime.now().isAfter(dueDt);
        final String pStatus = isPaid ? 'PAID' : (isOverdue ? 'OVERDUE' : 'UNPAID');

        effectiveRpsList = [
          {
            'installmentNumber': 1,
            'emi': emiVal,
            'remainingAmount': totalOutstanding ?? (isPaid ? 0.0 : emiVal),
            'dueDate': dueDt.toIso8601String(),
            'paymentStatus': pStatus,
            'principalAmount': baseAmt,
            'interestAmount': totalInterest,
          }
        ];
      }
    }

    final bool isAllRpsPaid = effectiveRpsList.isNotEmpty &&
        effectiveRpsList.every((item) {
          final s = item['paymentStatus']?.toString().toUpperCase();
          final rem = ((item['remainingAmount'] ?? 0) as num).toDouble();
          return s == 'PAID' || rem <= 0;
        });

    final bool isFullyPaid = isAllRpsPaid ||
        status == 'FULLY_PAID' ||
        ((totalOutstanding == null || totalOutstanding == 0) && totalPaid != null && totalPaid > 0);

    String headerAmountText = tr.tr('pending_confirmation');
    String headerSubText = tr.tr('syncing_details');

    if (isFullyPaid) {
      headerAmountText = '₹0';
      headerSubText = 'Loan Fully Paid & Settled';
    } else if (totalOutstanding != null) {
      headerAmountText = CurrencyUtils.formatAmount(totalOutstanding);
      headerSubText = tr.tr('total_outstanding');
    } else if (disbursedAmount != null) {
      headerAmountText = CurrencyUtils.formatAmount(disbursedAmount);
      headerSubText = tr.tr('disbursed_loan_amount');
    } else if (approvedAmount != null) {
      headerAmountText = CurrencyUtils.formatAmount(approvedAmount);
      headerSubText = tr.tr('sanctioned_amount');
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: _isLoading
          ? const Center(child: AppLoader(message: 'Loading active loan & RPS details...'))
          : CustomScrollView(
              slivers: [
                // ── Header ─────────────────────────────────────────────
                SliverAppBar(
                  expandedHeight: 250,
                  pinned: true,
                  stretch: true,
                  backgroundColor: AppTheme.primaryDeepTeal,
                  leadingWidth: 56,
                  leading: const AppBackButton(isDark: true),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                      onPressed: _fetchLoanDetails,
                      tooltip: 'Refresh details',
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    stretchModes: const [StretchMode.zoomBackground],
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isFullyPaid
                              ? const [
                                  Color(0xFF064E3B),
                                  Color(0xFF047857),
                                  Color(0xFF059669),
                                ]
                              : const [
                                  AppTheme.primaryDeepTeal,
                                  AppTheme.primaryDarkTeal,
                                  AppTheme.primaryTeal,
                                ],
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            top: -40,
                            right: -40,
                            child: Container(
                              width: 160,
                              height: 160,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.06),
                              ),
                            ),
                          ),
                          SafeArea(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(24, 48, 24, 20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: isFullyPaid
                                              ? Colors.greenAccent.withValues(alpha: 0.3)
                                              : (isDisbursed
                                                  ? Colors.greenAccent.withValues(alpha: 0.25)
                                                  : Colors.orangeAccent.withValues(alpha: 0.25)),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: isFullyPaid
                                                ? Colors.greenAccent
                                                : (isDisbursed ? Colors.greenAccent : Colors.orangeAccent),
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          isFullyPaid
                                              ? '✓ LOAN FULLY PAID'
                                              : (isDisbursed ? tr.tr('active_loan_badge') : '⏳ ${tr.tr('processing')}'),
                                          style: TextStyle(
                                            color: isFullyPaid || isDisbursed ? Colors.greenAccent : Colors.orangeAccent,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    customer?.fullName ?? 'Loan Account',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Text(
                                        widget.lan,
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.75),
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      GestureDetector(
                                        onTap: () {
                                          Clipboard.setData(ClipboardData(text: widget.lan));
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(tr.tr('lan_copied')),
                                              duration: const Duration(seconds: 2),
                                            ),
                                          );
                                        },
                                        child: Icon(
                                          Icons.copy_rounded,
                                          color: Colors.white.withValues(alpha: 0.6),
                                          size: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    headerAmountText,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: headerAmountText.startsWith('₹') ? 32 : 24,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  Text(
                                    headerSubText,
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.7),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Body ───────────────────────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.all(18),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Processing / Disbursal Sync Banner if statement is generating or notice present
                      if (_errorMessage != null || rpsList.isEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF0F5A47).withValues(alpha: 0.2)),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0F5A47).withValues(alpha: 0.06),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  SvgPicture.asset(
                                    'lib/assets/images/illustrations/Loading-rafiki.svg',
                                    height: 80,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFEF3C7),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            '⏳ ${tr.tr('statement_sync_in_progress')}',
                                            style: const TextStyle(
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFFD97706),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          approvedAmount != null
                                              ? '${tr.tr('sanctioned_amount')}: ${CurrencyUtils.formatAmount(approvedAmount)}'
                                              : '${tr.tr('sanctioned_amount')}: ${tr.tr('pending_confirmation')}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF0F172A),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          tr.tr('statement_sync_desc'),
                                          style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), height: 1.3),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: _fetchLoanDetails,
                                  icon: const Icon(Icons.refresh_rounded, size: 18),
                                  label: Text(tr.tr('refresh_disbursal_details')),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF0F5A47),
                                    side: const BorderSide(color: Color(0xFF0F5A47)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Summary Overview Grid
                      Row(
                        children: [
                          Expanded(
                            child: _summaryBox(
                              title: tr.tr('next_due_emi'),
                              val: nextEmiAmount != null ? CurrencyUtils.formatAmount(nextEmiAmount) : '—',
                              sub: nextDueDate != null ? '${tr.tr("due_date")}: ${_formatDate(nextDueDate)}' : tr.tr('no_dues_pending'),
                              color: AppTheme.primaryTeal,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _summaryBox(
                              title: tr.tr('total_paid'),
                              val: totalPaid != null ? CurrencyUtils.formatAmount(totalPaid) : '—',
                              sub: overdueAmount > 0 ? '${tr.tr("overdue")}: ${CurrencyUtils.formatAmount(overdueAmount)}' : tr.tr('on_schedule'),
                              color: overdueAmount > 0 ? AppTheme.errorRed : AppTheme.successGreen,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Disbursal Banner or Fully Paid Celebration Banner
                      if (isFullyPaid) ...[
                        _fullyPaidBanner(),
                        const SizedBox(height: 16),
                      ] else if (isDisbursed && (disbursedAmount != null || approvedAmount != null)) ...[
                        _disbursalSuccessCard(
                          (disbursedAmount ?? approvedAmount)!,
                          apiLoan?['disbursalUtr'] ?? fallbackLoan?.disbursalUtr,
                          apiLoan?['disbursalDate'] ?? fallbackLoan?.disbursalCompletedAt,
                        ),
                        const SizedBox(height: 16),
                      ],

                      // ── Repayment Schedule (RPS) ────────────────────
                      _sectionCard(
                        title: tr.tr('repayment_schedule'),
                        icon: Icons.calendar_month_rounded,
                        children: [
                          if (effectiveRpsList.any((r) => r['isMandateLocked'] == true)) ...[
                            Container(
                              margin: const EdgeInsets.only(bottom: 14),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFFBEB),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFFDE68A)),
                              ),
                              child: const Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 20),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Auto-Debit Clearing In Progress:',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF78350F),
                                          ),
                                        ),
                                        SizedBox(height: 3),
                                        Text(
                                          'An auto-debit mandate has been presented to your bank account for due installment collection. Online manual payment for presented installments is temporarily paused on the due date to protect against duplicate deductions. (If overdue by 1 or more days, manual payment is re-enabled).',
                                          style: TextStyle(
                                            fontSize: 11,
                                            height: 1.35,
                                            color: Color(0xFF92400E),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (effectiveRpsList.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                              child: Row(
                                children: [
                                  const Icon(Icons.schedule_rounded, color: AppTheme.primaryTeal, size: 22),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      approvedAmount != null
                                          ? '${tr.tr('repayment_schedule_for')} ${CurrencyUtils.formatAmount(approvedAmount)} ${tr.tr('rps_populated_utr_synced')}'
                                          : tr.tr('repayment_schedule_populated_lender'),
                                      style: const TextStyle(fontSize: 12.5, color: AppTheme.textDarkSecondary, height: 1.35),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            ...effectiveRpsList.map((itemMap) {
                              final instNum = itemMap['installmentNumber'] ?? 1;
                              final emi = (itemMap['emi'] ?? 0).toDouble();
                              final remaining = (itemMap['remainingAmount'] ?? emi).toDouble();
                              final paidAmount = (itemMap['paidAmount'] ?? 0).toDouble();
                              final dueDateStr = itemMap['dueDate']?.toString();
                              final paymentDateStr = itemMap['paymentDate']?.toString();
                              final pStatus = itemMap['paymentStatus']?.toString().toUpperCase() ?? 'UNPAID';
                              final isPaid = pStatus == 'PAID' || remaining <= 0;
                              final isOverdue = pStatus == 'OVERDUE' || (itemMap['isOverdue'] == true);
                              final isMandateLocked = itemMap['isMandateLocked'] == true;
                              final mandateDebitMessage = itemMap['mandateDebitMessage']?.toString();

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isPaid
                                      ? const Color(0xFFF0FDF4)
                                      : (isMandateLocked
                                          ? const Color(0xFFFFFBEB)
                                          : (isOverdue ? AppTheme.errorBg : Colors.grey.shade50)),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isPaid
                                        ? const Color(0xFFBBF7D0)
                                        : (isMandateLocked
                                            ? const Color(0xFFFDE68A)
                                            : (isOverdue ? AppTheme.errorRed : AppTheme.borderLight)),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${tr.tr("installment")} #$instNum',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: isPaid
                                                ? const Color(0xFF065F46)
                                                : (isMandateLocked ? const Color(0xFF78350F) : AppTheme.textDarkPrimary),
                                          ),
                                        ),
                                        AppStatusBadge(
                                          status: isPaid ? 'PAID' : (isMandateLocked ? 'PRESENTED' : pStatus),
                                          label: isPaid
                                              ? tr.tr('paid')
                                              : (isMandateLocked
                                                  ? 'Auto-Debit Presented'
                                                  : (isOverdue ? tr.tr('overdue') : tr.tr('unpaid'))),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${tr.tr("due_date")}: ${_formatDate(dueDateStr)}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: isPaid ? const Color(0xFF047857) : AppTheme.textDarkSecondary,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              isPaid && paidAmount > 0
                                                  ? 'Paid: ${CurrencyUtils.formatAmount(paidAmount)}'
                                                  : '${tr.tr("emi_amount")}: ${CurrencyUtils.formatAmount(emi)}',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: isPaid ? AppTheme.successGreen : AppTheme.textDarkPrimary,
                                              ),
                                            ),
                                            if (isPaid && paymentDateStr != null)
                                              Text(
                                                'Paid on ${_formatDate(paymentDateStr)}',
                                                style: const TextStyle(fontSize: 11, color: Color(0xFF059669)),
                                              ),
                                          ],
                                        ),
                                        if (isPaid)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFECFDF5),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: const Color(0xFFA7F3D0)),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.check_circle_rounded, size: 14, color: AppTheme.successGreen),
                                                SizedBox(width: 4),
                                                Text(
                                                  'Payment completed',
                                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.successGreen),
                                                ),
                                              ],
                                            ),
                                          )
                                        else if (isMandateLocked)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFEF3C7),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: const Color(0xFFFCD34D)),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                SizedBox(
                                                  width: 12,
                                                  height: 12,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD97706)),
                                                  ),
                                                ),
                                                SizedBox(width: 6),
                                                Text(
                                                  'Clearing in progress',
                                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                                                ),
                                              ],
                                            ),
                                          )
                                        else
                                          ElevatedButton(
                                            onPressed: () => _initiateRepayment(
                                                  instNum,
                                                  remaining > 0 ? remaining : emi,
                                                  isMandateLocked: isMandateLocked,
                                                  mandateDebitMessage: mandateDebitMessage,
                                                ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: isOverdue ? AppTheme.errorRed : AppTheme.primaryTeal,
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            ),
                                            child: Text(
                                              isOverdue ? 'Pay Overdue' : tr.tr('pay_now'),
                                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                      ],
                                    ),
                                    if (isMandateLocked)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(
                                          mandateDebitMessage ??
                                              'Bank clearing in progress. Manual payment paused on due date.',
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF92400E)),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            }),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ── Loan Details ────────────────────────────────
                      _sectionCard(
                        title: tr.tr('loan_account_summary'),
                        icon: Icons.receipt_long_rounded,
                        children: [
                          _row(tr.tr('loan_account_no'), widget.lan),
                          _row(tr.tr('application_no'), apiLoan?['applicationNumber'] ?? fallbackLoan?.applicationNumber ?? '—'),
                          _row(tr.tr('lender'), apiLoan?['lenderName'] ?? postApproval?.lender.name ?? customer?.allocatedLenderName ?? 'Fintree Finance Private Limited'),
                          _row(
                            tr.tr('interest_rate'),
                            (apiLoan?['interestRate'] != null || fallbackOffer?.acceptedInterestRate != null)
                                ? '${apiLoan?['interestRate'] ?? fallbackOffer?.acceptedInterestRate}% p.a.'
                                : tr.tr('pending_confirmation'),
                          ),
                          _row(
                            tr.tr('tenure'),
                            (apiLoan?['tenure'] != null || fallbackOffer?.acceptedTenureDays != null)
                                ? '${apiLoan?['tenure'] ?? fallbackOffer?.acceptedTenureDays} ${tr.tr("days")}'
                                : tr.tr('pending_confirmation'),
                          ),
                          _row(tr.tr('repayment_frequency'), apiLoan?['repaymentFrequency'] ?? tr.tr('monthly')),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ── Bank Account ────────────────────────────────
                      _sectionCard(
                        title: tr.tr('disbursal_bank_account'),
                        icon: Icons.account_balance_rounded,
                        children: [
                          _row(tr.tr('bank_name'), bank?.bankName ?? '—'),
                          _row(tr.tr('account_holder'), bank?.accountHolderName ?? '—'),
                          _row('Account No.', _maskAcc(bank?.accountMasked)),
                          _row(tr.tr('ifsc_code'), bank?.ifsc ?? '—'),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ── Repayment History ───────────────────────────
                      if (repaymentHistory.isNotEmpty) ...[
                        _sectionCard(
                          title: 'Repayment History',
                          icon: Icons.history_rounded,
                          children: repaymentHistory.map((rep) {
                            final repMap = rep as Map<String, dynamic>;
                            final pDate = repMap['paymentDate']?.toString();
                            final pAmt = (repMap['amountReceived'] ?? 0).toDouble();
                            final refNum = repMap['referenceNumber']?.toString() ?? '—';
                            final mode = repMap['paymentMode']?.toString() ?? 'ONLINE';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppTheme.borderLight),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(_formatDate(pDate), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                      Text('Ref: $refNum ($mode)', style: const TextStyle(fontSize: 11, color: AppTheme.textDarkSecondary)),
                                    ],
                                  ),
                                  Text(
                                    '+ ${CurrencyUtils.formatAmount(pAmt)}',
                                    style: const TextStyle(color: AppTheme.successGreen, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Back to Dashboard
                      OutlinedButton.icon(
                        onPressed: () => context.go('/dashboard'),
                        icon: const Icon(Icons.home_rounded),
                        label: const Text('Back to Dashboard'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryTeal,
                          side: const BorderSide(color: AppTheme.primaryTeal),
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ]),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _summaryBox({
    required String title,
    required String val,
    required String sub,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, color: AppTheme.textDarkSecondary)),
          const SizedBox(height: 4),
          Text(val, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(sub, style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.8), fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _fullyPaidBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFECFDF5), Color(0xFFD1FAE5)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.successGreen, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.successGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.verified_rounded, color: AppTheme.successGreen, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Loan Fully Repaid & Closed!',
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.successDarkGreen, fontSize: 14),
                    ),
                    Text(
                      'All installments have been completed. No outstanding dues remain on this account.',
                      style: TextStyle(color: AppTheme.successDarkGreen, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.push('/loan/${widget.lan}/fully-paid-review'),
              icon: const Icon(Icons.assignment_turned_in_rounded, size: 16),
              label: const Text('View No Dues Certificate & Review', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryTeal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _disbursalSuccessCard(num amount, String? utr, String? completedAt) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFECFDF5), Color(0xFFD1FAE5)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.successGreen, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.successGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.check_circle_rounded, color: AppTheme.successGreen, size: 24),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Loan Disbursed Successfully!',
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.successDarkGreen, fontSize: 14),
                  ),
                  Text(
                    'Funds transferred to registered bank account',
                    style: TextStyle(color: AppTheme.successDarkGreen, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                _infoRow('Disbursed Net Amount', CurrencyUtils.formatAmount(amount), bold: true),
                if (utr != null && utr.isNotEmpty) _infoRow('UTR Reference', utr),
                if (completedAt != null) _infoRow('Value Date', _formatDate(completedAt)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String val, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textDarkSecondary)),
          Text(val, style: TextStyle(fontSize: 12, fontWeight: bold ? FontWeight.w800 : FontWeight.w600, color: AppTheme.successDarkGreen)),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Icon(icon, color: AppTheme.primaryTeal, size: 18),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textDarkPrimary),
                ),
              ],
            ),
          ),
          const Divider(height: 18, indent: 16, endIndent: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String val, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textDarkSecondary)),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              val,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 13,
                fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
                color: highlight ? AppTheme.primaryTeal : AppTheme.textDarkPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _maskAcc(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    if (raw.length <= 4) return raw;
    return 'XXXX XXXX ${raw.substring(raw.length - 4)}';
  }

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return '—';
    try {
      final dt = DateTime.parse(iso).toLocal();
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return iso;
    }
  }
}
