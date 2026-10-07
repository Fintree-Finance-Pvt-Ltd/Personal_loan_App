import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../dashboard/presentation/journey_controller.dart';

class SupportScreen extends ConsumerStatefulWidget {
  const SupportScreen({super.key});

  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _selectedCategoryIndex = 0;

  final List<Map<String, dynamic>> _faqCategories = [
    {
      'title': 'Repayments & EMI',
      'icon': Icons.payment_rounded,
      'faqs': [
        {
          'q': 'How can I pay my loan EMI online?',
          'a': 'You can pay your EMI directly from the app by visiting the "All My Loans" tab or clicking "Pay EMI" on your active loan card. We support UPI, Net Banking, and Debit Cards.',
        },
        {
          'q': 'How long does eNACH auto-debit take to update?',
          'a': 'Auto-debit payments via eNACH usually reflect within 2 to 4 hours after your bank processes the transaction on your EMI due date.',
        },
        {
          'q': 'What if my repayment failed but money was deducted?',
          'a': 'Do not worry! If money was debited from your bank account, your bank will either refund it within 24-48 hours or automatically reconcile it with our system.',
        },
      ]
    },
    {
      'title': 'Disbursal & Loans',
      'icon': Icons.account_balance_wallet_rounded,
      'faqs': [
        {
          'q': 'When will the loan amount be credited to my bank account?',
          'a': 'Once your loan agreement is digitally signed via eSign, disbursal usually takes between 15 minutes to 2 hours depending on NEFT/IMPS bank clearance.',
        },
        {
          'q': 'Why is my loan application under review?',
          'a': 'Our risk & underwriting team verifies submitted bank statements and KYC credentials. This manual verification takes a maximum of 24 business hours.',
        },
        {
          'q': 'Can I apply for a repeat loan immediately?',
          'a': 'Yes! Once your current loan is fully repaid and closed, you become eligible for instant pre-approved repeat loan offers with higher sanction limits.',
        },
      ]
    },
    {
      'title': 'Referral & Fees',
      'icon': Icons.card_giftcard_rounded,
      'faqs': [
        {
          'q': 'How does the Refer & Earn discount work?',
          'a': 'When a friend registers using your referral link and their loan gets disbursed, you unlock an assessment & processing fee waiver discount for your next loan application.',
        },
        {
          'q': 'Where do I find my referral code?',
          'a': 'Go to the "Refer & Earn" section in the app sidebar or bottom menu to copy your code (e.g., FIN10025) or share your instant deep link.',
        },
      ]
    },
    {
      'title': 'Account & Security',
      'icon': Icons.security_rounded,
      'faqs': [
        {
          'q': 'Is my financial data safe with Fin-Tree Finance?',
          'a': 'Absolultely. All your personal data and bank credentials are encrypted using 256-bit AES SSL encryption in compliance with RBI guidelines.',
        },
        {
          'q': 'How can I update my registered mobile number or bank account?',
          'a': 'For security reasons, bank account or mobile number updates require human verification. Please raise a support ticket or call customer care.',
        },
      ]
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _faqCategories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      _showToast('Could not launch phone dialer for $phoneNumber');
    }
  }

  Future<void> _sendEmail(String email) async {
    final Uri launchUri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {'subject': 'Support Request - Fin-Tree Customer App'},
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      _showToast('Could not open email client for $email');
    }
  }

  Future<void> _openWhatsApp(String phone) async {
    final Uri launchUri = Uri.parse('https://wa.me/$phone?text=Hello%20Fin-Tree%20Support,%20I%20need%20assistance');
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri, mode: LaunchMode.externalApplication);
    } else {
      _showToast('Could not launch WhatsApp');
    }
  }

  void _showToast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.primaryTeal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showRaiseTicketModal(BuildContext context) {
    final customer = ref.read(journeyControllerProvider).customer;
    final activeLan = customer?.latestLan ?? customer?.platformLan ?? '';
    
    String selectedCategory = 'Disbursal Issue';
    final categories = [
      'Disbursal Issue',
      'Repayment & EMI Failure',
      'Account Aggregator / KYC',
      'Fee Discount & Referral',
      'Other Queries',
    ];

    final messageController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.confirmation_number_rounded, color: AppTheme.primaryTeal, size: 24),
                            SizedBox(width: 10),
                            Text(
                              'Raise Support Ticket',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const Divider(height: 20, color: Color(0xFFF1F5F9)),
                    
                    const Text(
                      'Issue Category',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedCategory,
                          isExpanded: true,
                          items: categories.map((cat) {
                            return DropdownMenuItem(
                              value: cat,
                              child: Text(cat, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setModalState(() => selectedCategory = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    if (activeLan.isNotEmpty) ...[
                      const Text(
                        'Loan Account Number (LAN)',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          activeLan,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primaryTeal),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    const Text(
                      'Describe your issue in detail',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: messageController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Provide transaction details, date, or query...',
                        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppTheme.primaryTeal, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                final text = messageController.text.trim();
                                if (text.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Please describe your issue before submitting.')),
                                  );
                                  return;
                                }

                                setModalState(() => isSubmitting = true);
                                await Future.delayed(const Duration(milliseconds: 1200));

                                if (context.mounted) {
                                  Navigator.pop(ctx);
                                  _showTicketSuccessDialog(selectedCategory);
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryTeal,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: isSubmitting
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Submit Ticket', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showTicketSuccessDialog(String category) {
    final ticketId = '#TCK${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                color: Color(0xFFECFDF5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 42),
            ),
            const SizedBox(height: 12),
            const Text('Ticket Created!', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Your support request for "$category" has been registered.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Ticket ID: $ticketId',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.primaryTeal),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Our resolution executive will call or email you within 4-6 business hours.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryTeal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Got It', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const AppHeader(title: 'Help & Support'),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==========================================
            // 1. HERO BANNER & REAL-TIME SEARCH
            // ==========================================
            _buildHeroBanner(),
            const SizedBox(height: 20),

            // ==========================================
            // 2. QUICK CONTACT ACTION GRID (4 CARDS)
            // ==========================================
            const Text(
              'Reach Out To Us',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 12),
            _buildQuickContactGrid(),
            const SizedBox(height: 24),

            // ==========================================
            // 3. CATEGORIZED FREQUENTLY ASKED QUESTIONS
            // ==========================================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Frequently Asked Questions',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Text(
                  '${_faqCategories.fold<int>(0, (sum, cat) => sum + (cat['faqs'] as List).length)} Topics',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Search Bar Filter
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: const [
                  BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 3)),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                decoration: InputDecoration(
                  icon: const Icon(Icons.search_rounded, color: Color(0xFF94A3B8)),
                  hintText: 'Search queries (e.g. EMI, disbursal, refund)...',
                  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                  border: InputBorder.none,
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Category Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(_faqCategories.length, (idx) {
                  final cat = _faqCategories[idx];
                  final isSelected = _selectedCategoryIndex == idx && _searchQuery.isEmpty;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      selected: isSelected,
                      avatar: Icon(
                        cat['icon'] as IconData,
                        size: 16,
                        color: isSelected ? Colors.white : const Color(0xFF64748B),
                      ),
                      label: Text(cat['title'] as String),
                      labelStyle: TextStyle(
                        fontSize: 12.5,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        color: isSelected ? Colors.white : const Color(0xFF334155),
                      ),
                      selectedColor: AppTheme.primaryTeal,
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? AppTheme.primaryTeal : const Color(0xFFE2E8F0),
                        ),
                      ),
                      onSelected: (_) {
                        setState(() {
                          _selectedCategoryIndex = idx;
                          _searchQuery = '';
                          _searchController.clear();
                        });
                      },
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 16),

            // FAQ Accordion List
            _buildFaqAccordion(),

            const SizedBox(height: 28),

            // ==========================================
            // 4. LEGAL & POLICIES SECTION
            // ==========================================
            const Text(
              'Legal & Policies',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 12),
            _buildLegalPoliciesCard(),
            const SizedBox(height: 24),

            _buildGrievanceRedressalCard(),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildLegalPoliciesCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.privacy_tip_rounded, color: Color(0xFF047857), size: 22),
            ),
            title: const Text(
              'Privacy Policy',
              style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            subtitle: const Text(
              'Confidentiality & data protection terms',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
            onTap: () => context.push('/privacy-policy'),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFE0F2FE),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF0284C7), size: 22),
            ),
            title: const Text(
              'Refund & Cancellation Terms',
              style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            subtitle: const Text(
              'Application cancellation & refund rules',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
            onTap: () => context.push('/refund-policy'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF064E3B), Color(0xFF0F5A47), Color(0xFF047857)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF064E3B).withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: const Row(
                  children: [
                    CircleAvatar(radius: 4, backgroundColor: Color(0xFF34D399)),
                    SizedBox(width: 6),
                    Text(
                      'Live Support (Mon - Sat, 9 AM - 8 PM)',
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.headset_mic_rounded, color: Colors.white70, size: 28),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'How Can We Help You Today?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Get instant resolutions for loan disbursals, EMI repayments, or technical queries.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 13,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickContactGrid() {
    final items = [
      {
        'title': 'Call Customer Care',
        'sub': '+91 1800 123 4567',
        'icon': Icons.phone_in_talk_rounded,
        'color': const Color(0xFF0284C7),
        'bg': const Color(0xFFE0F2FE),
        'action': () => _makePhoneCall('18001234567'),
      },
      {
        'title': 'WhatsApp Support',
        'sub': 'Instant Chat Assist',
        'icon': Icons.chat_rounded,
        'color': const Color(0xFF16A34A),
        'bg': const Color(0xFFDCFCE7),
        'action': () => _openWhatsApp('9118001234567'),
      },
      {
        'title': 'Email Us',
        'sub': 'support@fintreelms.com',
        'icon': Icons.mark_email_read_rounded,
        'color': const Color(0xFF7C3AED),
        'bg': const Color(0xFFF3E8FF),
        'action': () => _sendEmail('support@fintreelms.com'),
      },
      {
        'title': 'Raise a Ticket',
        'sub': 'Track Issue Status',
        'icon': Icons.confirmation_number_rounded,
        'color': const Color(0xFFD97706),
        'bg': const Color(0xFFFEF3C7),
        'action': () => _showRaiseTicketModal(context),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.45,
      ),
      itemCount: items.length,
      itemBuilder: (context, idx) {
        final item = items[idx];
        return InkWell(
          onTap: item['action'] as VoidCallback,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: const [
                BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 3)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: item['bg'] as Color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(item['icon'] as IconData, color: item['color'] as Color, size: 20),
                ),
                const SizedBox(height: 10),
                Text(
                  item['title'] as String,
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 2),
                Text(
                  item['sub'] as String,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFaqAccordion() {
    List<Map<String, String>> displayedFaqs = [];

    if (_searchQuery.isNotEmpty) {
      for (var cat in _faqCategories) {
        for (var faq in (cat['faqs'] as List)) {
          final q = (faq['q'] ?? '').toString();
          final a = (faq['a'] ?? '').toString();
          if (q.toLowerCase().contains(_searchQuery) || a.toLowerCase().contains(_searchQuery)) {
            displayedFaqs.add({'q': q, 'a': a});
          }
        }
      }
    } else {
      final currentCat = _faqCategories[_selectedCategoryIndex];
      for (var faq in (currentCat['faqs'] as List)) {
        displayedFaqs.add({'q': faq['q'].toString(), 'a': faq['a'].toString()});
      }
    }

    if (displayedFaqs.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            const Icon(Icons.search_off_rounded, size: 40, color: Color(0xFF94A3B8)),
            const SizedBox(height: 10),
            Text(
              'No topics found for "$_searchQuery"',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 4),
            const Text(
              'Try searching with different keywords or raise a ticket.',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: displayedFaqs.length,
          separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
          itemBuilder: (context, idx) {
            final faq = displayedFaqs[idx];
            return ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
              childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
              title: Text(
                faq['q']!,
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
              ),
              trailing: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.primaryTeal),
              children: [
                Text(
                  faq['a']!,
                  style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569), height: 1.45),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Was this helpful?', style: TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8))),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => _showToast('Thanks for your feedback! 👍'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)),
                        child: const Text('👍 Yes', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () => _showToast('Thanks! We will refine this topic.'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)),
                        child: const Text('👎 No', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildGrievanceRedressalCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFCBD5E1)),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.gavel_rounded, color: Color(0xFFD97706), size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Grievance Redressal Mechanism',
                      style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                    ),
                    Text(
                      'RBI Compliant Nodal Escalation Officer',
                      style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24, color: Color(0xFFF1F5F9)),
          const Text(
            'If your query is unresolved within 48 hours, you can directly escalate to our Nodal Grievance Officer:',
            style: TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.35),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Officer Name: Mr. Rajesh Sharma', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                const SizedBox(height: 4),
                InkWell(
                  onTap: () => _sendEmail('grievance@fintreelms.com'),
                  child: const Text('Email: grievance@fintreelms.com', style: TextStyle(fontSize: 12, color: AppTheme.primaryTeal, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 4),
                const Text('Turnaround Time: 24 - 48 Business Hours', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
