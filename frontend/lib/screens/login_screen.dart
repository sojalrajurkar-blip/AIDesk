import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController(text: 'requester@company.com');
  final _passwordCtrl = TextEditingController(text: 'RequesterPass123!');
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _handleManualLogin() async {
    final auth = context.read<AuthState>();
    final success = await auth.login(_emailCtrl.text.trim(), _passwordCtrl.text);
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Authentication failed'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  void _handleDemoLogin(String role, String email, String pass) async {
    setState(() {
      _emailCtrl.text = email;
      _passwordCtrl.text = pass;
    });
    final auth = context.read<AuthState>();
    final success = await auth.switchDemoRole(role);
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Failed to sign in as $role'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 850;

          if (isMobile) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 500),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Compact Hero Banner for Mobile
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: const BoxDecoration(
                          color: Color(0xFF1E1B4B),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.bolt, color: Colors.white, size: 20),
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  'DeskAI Operations',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Autonomous IT Help Desk • Gemini 2.5 Flash',
                              style: TextStyle(color: Color(0xFFC7D2FE), fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: _buildAuthForm(auth),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          // Desktop / Web 2-Column Split
          return Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1100, maxHeight: 720),
              margin: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Left Telemetry Bento Showcase
                  Expanded(
                    flex: 5,
                    child: Container(
                      padding: const EdgeInsets.all(40),
                      decoration: const BoxDecoration(
                        color: Color(0xFF1E1B4B),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16),
                          bottomLeft: Radius.circular(16),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.bolt, color: Colors.white, size: 24),
                              ),
                              const SizedBox(width: 12),
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'DeskAI Operations',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  Text(
                                    'Autonomous IT Help Desk',
                                    style: TextStyle(
                                      color: Color(0xFFC7D2FE),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 36),
                          const Text(
                            'Next-Gen IT Operations with Gemini 2.5 Flash',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Autonomous triage radar, duplicate deduplication, dual-stream communications, and immutable cryptographic WORM audit trails.',
                            style: TextStyle(
                              color: Color(0xFFC7D2FE),
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                          const Spacer(),

                          // Telemetry Cards
                          Row(
                            children: [
                              _buildTelemetryCard('94.2%', 'AI Triage Accuracy', Icons.auto_awesome),
                              const SizedBox(width: 12),
                              _buildTelemetryCard('18 min', 'Average MTTR', Icons.timer_outlined),
                              const SizedBox(width: 12),
                              _buildTelemetryCard('100%', 'WORM Audited', Icons.verified_user_outlined),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Right Authentication & 1-Click Role Switcher
                  Expanded(
                    flex: 6,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 36),
                      child: SingleChildScrollView(
                        child: _buildAuthForm(auth),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAuthForm(AuthState auth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sign In to DeskAI',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Select a demo persona or enter credentials below.',
          style: TextStyle(
            fontSize: 13,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 20),

        // 1-Click 5-Persona Quick Switcher
        const Text(
          '1-CLICK PERSONA ACCESS',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: AppTheme.textMuted,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildPersonaChip(
              'Requester (Alex Rivera)',
              'REQUESTER',
              'requester@company.com',
              'RequesterPass123!',
              Icons.person_outline,
              const Color(0xFF0284C7),
            ),
            _buildPersonaChip(
              'Operator (Priya N.)',
              'OPERATOR',
              'operator@company.com',
              'OperatorPass123!',
              Icons.headset_mic_outlined,
              const Color(0xFF2563EB),
            ),
            _buildPersonaChip(
              'Team Lead (Sarah J.)',
              'TEAM_LEAD',
              'teamlead@company.com',
              'TeamLeadPass123!',
              Icons.groups_outlined,
              const Color(0xFF7C3AED),
            ),
            _buildPersonaChip(
              'Manager (Marcus V.)',
              'MANAGER',
              'manager@company.com',
              'ManagerPass123!',
              Icons.insights_outlined,
              const Color(0xFF059669),
            ),
            _buildPersonaChip(
              'Super Admin (Elena R.)',
              'ADMIN',
              'admin@company.com',
              'AdminPass123!',
              Icons.admin_panel_settings_outlined,
              const Color(0xFFDC2626),
            ),
          ],
        ),

        const SizedBox(height: 24),
        const Row(
          children: [
            Expanded(child: Divider(color: AppTheme.border)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'OR ENTER CREDENTIALS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textMuted,
                ),
              ),
            ),
            Expanded(child: Divider(color: AppTheme.border)),
          ],
        ),
        const SizedBox(height: 18),

        // Form
        TextField(
          controller: _emailCtrl,
          decoration: const InputDecoration(
            labelText: 'Work Email Address',
            prefixIcon: Icon(Icons.email_outlined, size: 18),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _passwordCtrl,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: const Icon(Icons.lock_outline, size: 18),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 18,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
        ),
        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: auth.isLoading ? null : _handleManualLogin,
            child: auth.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Text('Sign In to Workspace'),
          ),
        ),
        const SizedBox(height: 16),

        // Downloadable Clients for Desktop & Mobile
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 44),
            side: const BorderSide(color: Color(0xFF5B63D3)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          icon: const Icon(Icons.download_for_offline_outlined, color: Color(0xFF4249B9), size: 18),
          label: const Text(
            'Download Desktop (EXE) & Mobile (APK)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4249B9),
            ),
          ),
          onPressed: _showDownloadModal,
        ),
      ],
    );
  }

  void _showDownloadModal() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.devices_other_outlined, color: Color(0xFF4249B9)),
            SizedBox(width: 8),
            Text('Get DeskAI Across All Devices', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose your platform below to download direct installers or install instantly via PWA:',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),

            // 1. Android APK
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFF059669).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.android, color: Color(0xFF059669), size: 24),
              ),
              title: const Text('Android Mobile App (.apk)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              subtitle: const Text('Direct installable standalone APK for Android phones and tablets (50.7 MB).', style: TextStyle(fontSize: 11)),
              trailing: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                icon: const Icon(Icons.download, size: 16),
                label: const Text('Download APK', style: TextStyle(fontSize: 11)),
                onPressed: () async {
                  final uri = Uri.parse('/downloads/DeskAI_Mobile_v1.0.apk');
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                },
              ),
            ),
            const Divider(height: 16),

            // 2. Windows Desktop Setup
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFF2563EB).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.desktop_windows, color: Color(0xFF2563EB), size: 24),
              ),
              title: const Text('Windows Desktop Setup (.zip / .bat)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              subtitle: const Text('1-Click desktop shortcut installer for Windows 10/11.', style: TextStyle(fontSize: 11)),
              trailing: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                icon: const Icon(Icons.download, size: 16),
                label: const Text('Download Setup', style: TextStyle(fontSize: 11)),
                onPressed: () async {
                  final uri = Uri.parse('/downloads/DeskAI_Windows_Setup.zip');
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                },
              ),
            ),
            const Divider(height: 16),

            // 3. Instant PWA
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFF7C3AED).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.install_mobile, color: Color(0xFF7C3AED), size: 24),
              ),
              title: const Text('Or Install Instantly (PWA)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              subtitle: const Text('In Chrome, tap Menu (⋮) > "Add to Home screen" or "Install App".', style: TextStyle(fontSize: 11)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryCard(String value, String label, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFFC7D2FE), size: 18),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonaChip(
    String label,
    String role,
    String email,
    String pass,
    IconData icon,
    Color color,
  ) {
    return ActionChip(
      avatar: Icon(icon, size: 14, color: color),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
      backgroundColor: color.withValues(alpha: 0.08),
      side: BorderSide(color: color.withValues(alpha: 0.3)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      onPressed: () => _handleDemoLogin(role, email, pass),
    );
  }
}
