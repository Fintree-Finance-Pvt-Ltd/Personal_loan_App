import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../../app/theme.dart';
import '../../../../core/widgets/app_header.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  static const String privacyPolicyUrl = 'https://fintreefinance.com/privacy-policy';
  
  bool _showWebView = false;
  WebViewController? _webViewController;
  bool _isLoadingWeb = true;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
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
      ..loadRequest(Uri.parse(privacyPolicyUrl));
  }

  Future<void> _openInBrowser() async {
    final uri = Uri.parse(privacyPolicyUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open browser.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppHeader(
        title: 'Privacy Policy',
        actions: [
          IconButton(
            icon: Icon(
              _showWebView ? Icons.article_outlined : Icons.language_rounded,
              color: AppTheme.primaryTeal,
            ),
            tooltip: _showWebView ? 'Switch to App View' : 'Switch to Web View',
            onPressed: () {
              setState(() {
                _showWebView = !_showWebView;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.open_in_new_rounded, color: AppTheme.primaryTeal),
            tooltip: 'Open in Browser',
            onPressed: _openInBrowser,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Mode Selector Banner
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
                          Icon(Icons.feed_rounded, size: 16),
                          SizedBox(width: 6),
                          Text('Document View'),
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
                          Icon(Icons.public_rounded, size: 16),
                          SizedBox(width: 6),
                          Text('Live Website View'),
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

            // Main Body Content
            Expanded(
              child: _showWebView
                  ? Stack(
                      children: [
                        if (_webViewController != null)
                          WebViewWidget(controller: _webViewController!),
                        if (_isLoadingWeb)
                          const Center(
                            child: CircularProgressIndicator(color: AppTheme.primaryTeal),
                          ),
                      ],
                    )
                  : SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Banner
                          _buildHeaderCard(),
                          const SizedBox(height: 20),

                          // Policy Paragraph Cards
                          _buildPolicySection(
                            icon: Icons.security_rounded,
                            iconColor: const Color(0xFF0F5A47),
                            title: '1. Strict Confidentiality & Ownership',
                            content:
                                'We, Fintree Finance Pvt. Ltd., are the sole owners of the information collected on our website. We acknowledge and accept that the personal details that you impart to us are to be kept in strict confidentiality. We shall use this information only in a manner beneficial to our customers. We consider our relationship with you as invaluable and strive to respect and safeguard your right to privacy.',
                          ),
                          const SizedBox(height: 14),

                          _buildPolicySection(
                            icon: Icons.shield_rounded,
                            iconColor: const Color(0xFF0284C7),
                            title: '2. Protection of Personal Details & Scope',
                            content:
                                'We shall protect the personal details received from you with the same degree of care—no less than a reasonable degree—to prevent unauthorized use, dissemination, or publication, just as we protect our own confidential information. The information we collect is limited to what you provide via applications or web forms, including name, business name, contact details, and business location. This data helps us understand your needs and provide excellent customer service, maintain internal records, and improve our products, services, and satisfaction.',
                          ),
                          const SizedBox(height: 14),

                          _buildPolicySection(
                            icon: Icons.lock_clock_rounded,
                            iconColor: const Color(0xFFD97706),
                            title: '3. Security Standards & Retention',
                            content:
                                'We do not compromise on security and take your privacy seriously. We implement various security measures to prevent unauthorized access and ensure the safety of your personal data. Your information will be retained for a minimum of one year or as statutorily required.',
                          ),
                          const SizedBox(height: 14),

                          _buildPolicySection(
                            icon: Icons.insights_rounded,
                            iconColor: const Color(0xFF7C3AED),
                            title: '4. Utilization of Information',
                            content:
                                'Your personal information will help us improve our services and inform you about new offerings or updates that may interest you. It will only be used in the appropriate context and to fulfill your requests and obligations.',
                          ),
                          const SizedBox(height: 14),

                          _buildPolicySection(
                            icon: Icons.gavel_rounded,
                            iconColor: const Color(0xFF059669),
                            title: '5. Regulatory Compliance (Indian Laws)',
                            content:
                                'We collect only necessary personal data required for administering our services effectively and complying with Indian regulations. To enhance service quality, we may combine your data submitted through various channels.',
                          ),
                          const SizedBox(height: 14),

                          _buildPolicySection(
                            icon: Icons.handshake_rounded,
                            iconColor: const Color(0xFFEA580C),
                            title: '6. Third-Party Sharing & Data Security',
                            content:
                                'Under specific circumstances, we may share your data with trusted third parties to add value to our services or when required by governmental or regulatory authorities. All such data is secured on protected sections of our website.',
                          ),
                          const SizedBox(height: 14),

                          _buildPolicySection(
                            icon: Icons.link_rounded,
                            iconColor: const Color(0xFF2563EB),
                            title: '7. Links to External Websites',
                            content:
                                'While we may offer links to external websites, we do not control their privacy practices. We advise you to review the privacy statements of any linked sites before sharing information.',
                          ),
                          const SizedBox(height: 14),

                          _buildPolicySection(
                            icon: Icons.fact_check_rounded,
                            iconColor: const Color(0xFF16A34A),
                            title: '8. Accuracy & Data Maintenance',
                            content:
                                'To ensure better service, it is important that your personal information with us remains updated and accurate.',
                          ),
                          const SizedBox(height: 24),

                          // External Link Banner Card
                          _buildOfficialLinkFooter(),
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
          colors: [Color(0xFF064E3B), Color(0xFF0F5A47)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Color(0x1A0F5A47), blurRadius: 12, offset: Offset(0, 6)),
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
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.privacy_tip_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fintree Finance Pvt. Ltd.',
                      style: TextStyle(color: Color(0xFF34D399), fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Privacy Policy',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'We value your trust and are committed to safeguarding your personal and financial information under strict confidentiality standard.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicySection({
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

  Widget _buildOfficialLinkFooter() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_user_rounded, color: AppTheme.primaryTeal, size: 24),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Official Privacy Document',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                SizedBox(height: 2),
                Text(
                  privacyPolicyUrl,
                  style: TextStyle(fontSize: 11.5, color: AppTheme.primaryTeal, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_rounded, color: AppTheme.primaryTeal),
            onPressed: _openInBrowser,
          ),
        ],
      ),
    );
  }
}
