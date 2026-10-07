import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme.dart';
import '../../../../core/models/customer_model.dart';
import '../../../../core/models/lender_offer_multiplier.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../dashboard/presentation/journey_controller.dart';

class AllLoansScreen extends ConsumerStatefulWidget {
  const AllLoansScreen({super.key});

  @override
  ConsumerState<AllLoansScreen> createState() => _AllLoansScreenState();
}

class _AllLoansScreenState extends ConsumerState<AllLoansScreen> {
  bool _isLoading = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _loansList = [];
  String _selectedFilter = 'ALL'; // ALL, ACTIVE, FULLY_PAID, IN_PROGRESS

  @override
  void initState() {
    super.initState();
    _fetchLoansHistory();
  }

  Future<void> _fetchLoansHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    List<Map<String, dynamic>> parsedLoans = [];

    // 1. Immediately extract active loan details from existing Riverpod JourneyState
    final initialJourney = ref.read(journeyControllerProvider);
    final initialCustomer = initialJourney.customer;
    final initialPost = initialJourney.postApproval;

    if (initialCustomer != null) {
      final String effectiveLan = initialPost?.loan.lan.isNotEmpty == true
          ? initialPost!.loan.lan
          : (initialCustomer.latestLan ?? initialCustomer.platformLan ?? '');

      if (effectiveLan.isNotEmpty) {
        final String status = initialPost?.loan.status.isNotEmpty == true
            ? initialPost!.loan.status.toUpperCase()
            : (initialCustomer.latestLoanStatus ?? initialCustomer.latestApplicationStatus ?? 'DISBURSED').toUpperCase();

        final num amount = initialPost?.loan.approvedAmount ??
            initialPost?.loan.disbursalAmount ??
            initialPost?.offer.approvedAmount ??
            (initialCustomer.assessmentFee?['totalAmount'] as num?) ??
            0;

        final String lenderName = initialPost?.lender.name.isNotEmpty == true
            ? initialPost!.lender.name
            : (initialCustomer.allocatedLenderName ?? 'N/A');

        final String dateStr = _formatDateStr(
          initialPost?.loan.disbursalCompletedAt ??
              initialPost?.loan.disbursalDate ??
              initialPost?.loan.approvedAt,
        );

        final String? utr = initialPost?.loan.disbursalUtr;

        parsedLoans.add({
          'lan': effectiveLan,
          'status': status,
          'amount': amount,
          'lenderName': lenderName,
          'disbursalDate': dateStr,
          'utr': utr,
          'isLatest': true,
        });
      }
    }

    // Populate initial state if available
    if (parsedLoans.isNotEmpty && mounted) {
      setState(() {
        _loansList = List.from(parsedLoans);
      });
    }

    // 2. Sync state & fetch backend customer details gracefully
    try {
      try {
        await ref.read(journeyControllerProvider.notifier).syncCustomerState();
      } catch (e) {
        debugPrint('[AllLoansScreen] Sync state warning: $e');
      }

      final updatedJourney = ref.read(journeyControllerProvider);
      final updatedCustomer = updatedJourney.customer;
      final updatedPost = updatedJourney.postApproval;

      final storage = ref.read(secureStorageProvider);
      final apiClient = ref.read(apiClientProvider);

      final customerId = await storage.getCustomerId();
      if (customerId != null && customerId.isNotEmpty) {
        dynamic res;
        try {
          res = await apiClient.get('/customer/$customerId');
        } catch (e) {
          debugPrint('[AllLoansScreen] API /customer/$customerId warning: $e');
        }

        if (res != null) {
          dynamic rawData = res;
          if (rawData is Map<String, dynamic> && rawData['data'] != null) {
            rawData = rawData['data'];
          }
          if (rawData is Map<String, dynamic> && rawData['data'] != null) {
            rawData = rawData['data'];
          }

          final Map<String, dynamic> customerData =
              rawData is Map<String, dynamic> ? rawData : {};

          if (customerData['loans'] is List && (customerData['loans'] as List).isNotEmpty) {
            for (var item in (customerData['loans'] as List)) {
              if (item is Map<String, dynamic>) {
                final formatted = _formatLoanItem(item);
                if (!parsedLoans.any((l) => l['lan'] == formatted['lan'])) {
                  parsedLoans.add(formatted);
                }
              }
            }
          } else if (customerData['applications'] is List && (customerData['applications'] as List).isNotEmpty) {
            for (var item in (customerData['applications'] as List)) {
              if (item is Map<String, dynamic>) {
                final formatted = _formatLoanItem(item);
                if (!parsedLoans.any((l) => l['lan'] == formatted['lan'])) {
                  parsedLoans.add(formatted);
                }
              }
            }
          }
        }
      }

      // Re-check updated journey state for live numbers
      if (updatedCustomer != null) {
        final String effectiveLan = updatedPost?.loan.lan.isNotEmpty == true
            ? updatedPost!.loan.lan
            : (updatedCustomer.latestLan ?? updatedCustomer.platformLan ?? '');

        if (effectiveLan.isNotEmpty) {
          final String status = updatedPost?.loan.status.isNotEmpty == true
              ? updatedPost!.loan.status.toUpperCase()
              : (updatedCustomer.latestLoanStatus ?? updatedCustomer.latestApplicationStatus ?? 'DISBURSED').toUpperCase();

          final num amount = updatedPost?.loan.approvedAmount ??
              updatedPost?.loan.disbursalAmount ??
              updatedPost?.offer.approvedAmount ??
              (updatedCustomer.assessmentFee?['totalAmount'] as num?) ??
              0;

          final String lenderName = updatedPost?.lender.name.isNotEmpty == true
              ? updatedPost!.lender.name
              : (updatedCustomer.allocatedLenderName ?? 'N/A');

          final String dateStr = _formatDateStr(
            updatedPost?.loan.disbursalCompletedAt ??
                updatedPost?.loan.disbursalDate ??
                updatedPost?.loan.approvedAt,
          );

          final String? utr = updatedPost?.loan.disbursalUtr;

          final liveItem = {
            'lan': effectiveLan,
            'status': status,
            'amount': amount,
            'lenderName': lenderName,
            'disbursalDate': dateStr,
            'utr': utr,
            'isLatest': true,
          };

          final existingIdx = parsedLoans.indexWhere((l) => l['lan'] == effectiveLan);
          if (existingIdx >= 0) {
            parsedLoans[existingIdx] = liveItem;
          } else {
            parsedLoans.insert(0, liveItem);
          }
        }
      }

      if (mounted) {
        setState(() {
          _loansList = parsedLoans;
          _errorMessage = null;
        });
      }
    } catch (e) {
      debugPrint('[AllLoansScreen] Error fetching loans history: $e');
      if (parsedLoans.isEmpty && mounted) {
        setState(() {
          _errorMessage = 'Unable to fetch loan history. Pull to refresh.';
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Map<String, dynamic> _formatLoanItem(Map<String, dynamic> raw) {
    final lan = raw['lan']?.toString() ?? raw['loanNumber']?.toString() ?? raw['id']?.toString() ?? 'N/A';
    final status = (raw['status']?.toString() ?? raw['applicationStatus']?.toString() ?? 'N/A').toUpperCase();
    final amount = raw['approvedAmount'] as num? ?? raw['amount'] as num? ?? raw['sanctionedAmount'] as num? ?? 0;
    final lender = raw['lenderName']?.toString() ?? raw['lender']?['name']?.toString() ?? 'N/A';
    final dateStr = _formatDateStr(raw['disbursedAt']?.toString() ?? raw['createdAt']?.toString());
    final utr = raw['disbursalUtr']?.toString() ?? raw['utr']?.toString();

    return {
      'lan': lan,
      'status': status,
      'amount': amount,
      'lenderName': lender,
      'disbursalDate': dateStr,
      'utr': utr,
    };
  }

  String _formatDateStr(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '';
    try {
      final dt = DateTime.parse(raw.trim());
      return DateFormat('dd/MM/yyyy').format(dt);
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final customer = ref.watch(journeyControllerProvider).customer;

    final filteredLoans = _loansList.where((item) {
      final status = (item['status'] ?? '').toString().toUpperCase();
      if (_selectedFilter == 'ACTIVE') {
        return status == 'DISBURSED' || status == 'ACTIVE' || status == 'SANCTIONED';
      }
      if (_selectedFilter == 'FULLY_PAID') {
        return status == 'FULLY_PAID' || status == 'CLOSED';
      }
      if (_selectedFilter == 'IN_PROGRESS') {
        return status != 'DISBURSED' && status != 'FULLY_PAID' && status != 'CLOSED';
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const AppHeader(
        title: 'All My Loans',
      ),
      body: RefreshIndicator(
        onRefresh: _fetchLoansHistory,
        color: AppTheme.primaryTeal,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==========================================
              // 1. TOP REPEAT LOAN PROMO BANNER (IF APPLICABLE)
              // ==========================================
              if ((customer?.completedLoansCount ?? 0) > 0)
                _buildRepeatLoanBanner(customer!),

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppTheme.errorRed, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: AppTheme.errorRed, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // ==========================================
              // 2. HEADER & FILTER CHIPS
              // ==========================================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Loan Applications & History',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    '${_loansList.length} Loan(s)',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('ALL', 'All (${_loansList.length})'),
                    _buildFilterChip(
                      'ACTIVE',
                      'Active (${_loansList.where((i) => ['DISBURSED', 'ACTIVE', 'SANCTIONED'].contains((i['status'] ?? '').toString().toUpperCase())).length})',
                    ),
                    _buildFilterChip(
                      'FULLY_PAID',
                      'Fully Paid (${_loansList.where((i) => ['FULLY_PAID', 'CLOSED'].contains((i['status'] ?? '').toString().toUpperCase())).length})',
                    ),
                    _buildFilterChip(
                      'IN_PROGRESS',
                      'In Progress (${_loansList.where((i) => !['DISBURSED', 'ACTIVE', 'SANCTIONED', 'FULLY_PAID', 'CLOSED'].contains((i['status'] ?? '').toString().toUpperCase())).length})',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // ==========================================
              // 3. LOANS LIST CONTENT
              // ==========================================
              if (_isLoading && _loansList.isEmpty)
                const SizedBox(
                  height: 300,
                  child: Center(
                    child: AppLoader(message: 'Loading your dynamic loan records...'),
                  ),
                )
              else if (filteredLoans.isEmpty)
                _buildEmptyState()
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredLoans.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final loanItem = filteredLoans[index];
                    return _buildLoanCard(loanItem);
                  },
                ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRepeatLoanBanner(CustomerModel customer) {
    final int count = customer.completedLoansCount > 0 ? customer.completedLoansCount : 1;
    final double mult = LenderMultiplierCalculator.getMultiplier(count);
    final num? baseLimit = customer.approvedLimit ?? customer.assessmentFee?['totalAmount'] ?? customer.assessmentFee?['amount'];
    final double initialLimit = (baseLimit != null && baseLimit.toDouble() > 0) ? baseLimit.toDouble() : 0.0;
    final double revisedLimit = initialLimit > 0 ? LenderMultiplierCalculator.calculateRevisedLimit(initialLimit, count) : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF064E3B), Color(0xFF0F5A47)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF064E3B).withValues(alpha: 0.3),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.stars_rounded, color: Colors.amber, size: 26),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Repeat Loan Pre-Approved (${mult}x Multiplier)',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            revisedLimit > 0
                ? 'Congratulations! You are eligible for a pre-approved repeat loan up to ${CurrencyUtils.formatAmount(revisedLimit)} with instant 1-click disbursal.'
                : 'Congratulations! You are eligible for a pre-approved repeat loan with instant 1-click disbursal.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 12.5,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: () => context.push('/onboarding/basic-details'),
            icon: const Icon(Icons.flash_on_rounded, size: 16),
            label: const Text('Apply Repeat Loan Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF065F46),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Text(label),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFF475569),
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
        ),
        selectedColor: const Color(0xFF0F172A),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        onSelected: (_) {
          setState(() => _selectedFilter = value);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.account_balance_wallet_outlined, size: 36, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 14),
          const Text(
            'No Loans Found',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 6),
          const Text(
            'No loan records match the selected filter.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildLoanCard(Map<String, dynamic> loan) {
    final String lan = (loan['lan'] != null && loan['lan'].toString().isNotEmpty) ? loan['lan'].toString() : 'N/A';
    final String status = (loan['status']?.toString() ?? 'N/A').toUpperCase();
    final num amount = loan['amount'] as num? ?? 0;
    final String lenderName = (loan['lenderName'] != null && loan['lenderName'].toString().isNotEmpty) ? loan['lenderName'].toString() : 'N/A';
    final String dateStr = loan['disbursalDate']?.toString() ?? '';
    final String? utr = loan['utr']?.toString();

    final bool isDisbursed = status == 'DISBURSED' || status == 'ACTIVE';
    final bool isFullyPaid = status == 'FULLY_PAID' || status == 'CLOSED';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: LAN & Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isFullyPaid
                            ? const Color(0xFFE0F2FE)
                            : isDisbursed
                                ? const Color(0xFFECFDF5)
                                : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isFullyPaid
                            ? Icons.verified_rounded
                            : isDisbursed
                                ? Icons.receipt_long_rounded
                                : Icons.hourglass_top_rounded,
                        color: isFullyPaid
                            ? const Color(0xFF0284C7)
                            : isDisbursed
                                ? const Color(0xFF059669)
                                : const Color(0xFFD97706),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'LOAN ACCOUNT NUMBER',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF94A3B8),
                              letterSpacing: 0.8,
                            ),
                          ),
                          Text(
                            lan,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                decoration: BoxDecoration(
                  color: isFullyPaid
                      ? const Color(0xFFE0F2FE)
                      : isDisbursed
                          ? const Color(0xFFDCFCE7)
                          : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isFullyPaid
                        ? const Color(0xFFBAE6FD)
                        : isDisbursed
                            ? const Color(0xFF86EFAC)
                            : const Color(0xFFFDE68A),
                  ),
                ),
                child: Text(
                  isFullyPaid
                      ? 'FULLY PAID ✓'
                      : isDisbursed
                          ? 'DISBURSED'
                          : status,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isFullyPaid
                        ? const Color(0xFF0369A1)
                        : isDisbursed
                            ? const Color(0xFF15803D)
                            : const Color(0xFFB45309),
                  ),
                ),
              ),
            ],
          ),

          const Divider(height: 24, color: Color(0xFFF1F5F9)),

          // Loan Amount & Lender Details
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sanctioned Amount',
                    style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    amount > 0 ? CurrencyUtils.formatAmount(amount) : 'N/A',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.primaryTeal,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Disbursal Date',
                    style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateStr.isNotEmpty ? dateStr : 'N/A',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.account_balance_rounded, size: 14, color: Color(0xFF94A3B8)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Lender: $lenderName',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ),
            ],
          ),

          if (utr != null && utr.trim().isNotEmpty && utr.toUpperCase() != 'N/A') ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.numbers_rounded, size: 14, color: Color(0xFF94A3B8)),
                const SizedBox(width: 6),
                Text(
                  'UTR: $utr',
                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ],

          const SizedBox(height: 16),

          // Action Buttons - Fully Responsive & Overflow-Proof
          if (isFullyPaid)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/loan/$lan/fully-paid-review'),
                    icon: const Icon(Icons.verified_user_rounded, size: 16),
                    label: const Text('View RPS Schedule', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryTeal,
                      side: const BorderSide(color: AppTheme.primaryTeal),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    ),
                  ),
                ),
              ],
            )
          else if (isDisbursed)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => context.push('/loan/$lan/repay'),
                    icon: const Icon(Icons.payment_rounded, size: 16),
                    label: const Text('Pay EMI / Repay', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryTeal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/loan/$lan/loan-details'),
                    icon: const Icon(Icons.info_outline_rounded, size: 16),
                    label: const Text('Full Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryTeal,
                      side: const BorderSide(color: AppTheme.primaryTeal),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                    ),
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => context.push('/loan/$lan/loan-details'),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                    label: const Text('Resume Application', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryTeal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
