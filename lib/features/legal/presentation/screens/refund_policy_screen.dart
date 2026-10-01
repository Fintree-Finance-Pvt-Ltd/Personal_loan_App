import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../../app/theme.dart';
import '../../../../core/widgets/app_header.dart';

class RefundPolicyScreen extends StatefulWidget {
  const RefundPolicyScreen({super.key});

  @override
  State<RefundPolicyScreen> createState() => _RefundPolicyScreenState();
}

class _RefundPolicyScreenState extends State<RefundPolicyScreen> {
  static const String pdfUrl =
      'https://fintreefinance.com/assets/REFUND%20AND%20CANCELLATION%20TERMS%20(002)-BsS_J7QB.pdf';
  
  bool _showWebView = false;
  WebViewController? _webViewController;
  bool _isLoadingWeb = true;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    // Google Docs Viewer allows embedding PDFs cleanly in WebViews across iOS and Android
    final viewerUrl =
        'https://docs.google.com/gview?embedded=true&url=${Uri.encodeComponent(pdfUrl)}';

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            if (mounted) setState(() => _isLoadingWeb = true);
          },
          onPageFinished: (String url) {
            if (mounted) setState(() => _isLoadingWeb = false);
          },
          onWebResourceError: (WebResourceError error) {
            if (mounted) setState(() => _isLoadingWeb = false);
          },
        ),
      )
      ..loadRequest(Uri.parse(viewerUrl));
  }

  Future<void> _openInBrowser() async {
    final uri = Uri.parse(pdfUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open PDF in browser.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppHeader(
        title: 'Refund & Cancellation',
        actions: [
          IconButton(
            icon: Icon(
              _showWebView ? Icons.description_outlined : Icons.picture_as_pdf_rounded,
              color: AppTheme.primaryTeal,
            ),
            tooltip: _showWebView ? 'Switch to App Summary' : 'View PDF Document',
            onPressed: () {
              setState(() {
                _showWebView = !_showWebView;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.download_rounded, color: AppTheme.primaryTeal),
            tooltip: 'Open / Download PDF',
            onPressed: _openInBrowser,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Mode Selector Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      selected: !_showWebView,
                      label: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.article_rounded, size: 16),
                          SizedBox(width: 6),
                          Text('Policy Summary'),
                        ],
                      ),
                      selectedColor: AppTheme.primaryTeal,
                      labelStyle: TextStyle(
                        color: !_showWebView ? Colors.white : const Color(0xFF475569),
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                      ),
                      onSelected: (val) {
                        if (val) setState(() => _showWebView = false);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ChoiceChip(
                      selected: _showWebView,
                      label: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.picture_as_pdf_rounded, size: 16),
                          SizedBox(width: 6),
                          Text('PDF Document View'),
                        ],
                      ),
                      selectedColor: AppTheme.primaryTeal,
                      labelStyle: TextStyle(
                        color: _showWebView ? Colors.white : const Color(0xFF475569),
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                      ),
                      onSelected: (val) {
                        if (val) setState(() => _showWebView = true);
                      },
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),

            // Body
            Expanded(
              child: _showWebView
                  ? Stack(
                      children: [
                        if (_webViewController != null)
                          WebViewWidget(controller: _webViewController!),
                        if (_isLoadingWeb)
                          const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(color: AppTheme.primaryTeal),
                                SizedBox(height: 12),
                                Text(
                                  'Loading official PDF document...',
                                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                      ],
                    )
                  : SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Card
                          _buildHeaderCard(),
                          const SizedBox(height: 20),

                          // Policy Highlight Sections
                          _buildSectionCard(
                            icon: Icons.assignment_return_rounded,
                            iconColor: const Color(0xFF0F5A47),
                            title: '1. Application & Processing Fee Cancellation',
                            content:
                                'Applicants may cancel their loan application prior to signing the final loan agreement (eSign). Any processing fees paid during the application stage are evaluated as per regulatory guidelines and lender terms.',
                          ),
                          const SizedBox(height: 14),

                          _buildSectionCard(
                            icon: Icons.cancel_schedule_send_rounded,
                            iconColor: const Color(0xFFDC2626),
                            title: '2. Post-Sanction & Pre-Disbursal Cancellation',
                            content:
                                'If a loan application is cancelled post sanction but before loan disbursement to your bank account, no further liability or loan principal obligation will be incurred by the borrower.',
                          ),
                          const SizedBox(height: 14),

                          _buildSectionCard(
                            icon: Icons.replay_rounded,
                            iconColor: const Color(0xFF2563EB),
                            title: '3. Refund Eligibility & Duplicate Debits',
                            content:
                                'In the event of accidental excess EMI payments or duplicate account debits during online transactions, the excess debited amount will be refunded directly to the original bank account within 3 to 7 business days following verification.',
                          ),
                          const SizedBox(height: 14),

                          _buildSectionCard(
                            icon: Icons.schedule_rounded,
                            iconColor: const Color(0xFFD97706),
                            title: '4. Refund Processing Timelines',
                            content:
                                'All valid refunds are initiated by Fintree Finance Pvt. Ltd. promptly and credited through automated bank transfer (NEFT/RTGS/IMPS) within 5-7 working days.',
                          ),
                          const SizedBox(height: 14),

                          _buildSectionCard(
                            icon: Icons.support_agent_rounded,
                            iconColor: const Color(0xFF7C3AED),
                            title: '5. Grievance & Escalations',
                            content:
                                'For any payment or refund queries, customers can reach out to Customer Support at support@fintreelms.com or initiate a ticket directly within the app.',
                          ),
                          const SizedBox(height: 24),

                          // PDF Link Card
                          _buildPdfActionCard(),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Color(0x1A0284C7), blurRadius: 12, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fintree Finance Pvt. Ltd.',
                      style: TextStyle(color: Color(0xFFBAE6FD), fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Refund & Cancellation Terms',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Review our transparent terms governing application cancellations, loan agreement revocations, and transaction refund processing.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 8, offset: Offset(0, 3)),
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
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF334155),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPdfActionCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFDBEAFE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF1D4ED8), size: 26),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Original PDF Document',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                ),
                SizedBox(height: 2),
                Text(
                  'REFUND AND CANCELLATION TERMS (002)',
                  style: TextStyle(fontSize: 11.5, color: Color(0xFF3B82F6), fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _openInBrowser,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1D4ED8),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              elevation: 0,
            ),
            child: const Text('Open PDF', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
