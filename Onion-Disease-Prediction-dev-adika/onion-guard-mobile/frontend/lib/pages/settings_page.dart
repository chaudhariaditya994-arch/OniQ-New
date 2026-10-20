import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/api_config.dart';
import '../config/app_theme.dart';
import '../providers/language_provider.dart';
import '../services/auth_service.dart';
import '../services/biometric_service.dart';
import '../widgets/onion_dialog.dart';
import '../widgets/server_config_dialog.dart';
import 'login_page.dart';
import 'reviews_list_page.dart';

class SettingsPage extends StatefulWidget {
  final String userEmail;
  const SettingsPage({super.key, required this.userEmail});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _authService = AuthService();
  final _biometricService = BiometricService();
  bool _biometricEnabled = false;
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _showChangePasswordDialog() {
    final lang = context.read<LanguageProvider>();
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        title: Text(lang.t('change_password'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              TextField(
                controller: oldPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: lang.t('old_password'),
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: lang.t('new_password'),
                  prefixIcon: const Icon(Icons.lock),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: Text(lang.t('cancel')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    if (oldPasswordController.text.isEmpty || newPasswordController.text.isEmpty) return;
                    Navigator.pop(ctx);
                    try {
                      final result = await _authService.changePassword(
                        email: widget.userEmail,
                        oldPassword: oldPasswordController.text.trim(),
                        newPassword: newPasswordController.text.trim(),
                      );
                      if (mounted) {
                        if (result['success'] == true) {
                          OnionDialog.showSuccess(context, title: 'Success', message: result['message'] ?? 'Password changed successfully.');
                        } else {
                          OnionDialog.showError(context, title: 'Failed', message: result['detail'] ?? 'Could not change password.');
                        }
                      }
                    } catch (_) {
                      if (mounted) OnionDialog.showError(context, title: 'Error', message: 'Failed to connect to server');
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: Text(lang.t('save')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _loadSettings() async {
    final bioAvail = await _biometricService.isBiometricAvailable();
    final bioEnabled = await _biometricService.isBiometricEnabled();
    if (mounted) {
      setState(() {
        _biometricAvailable = bioAvail;
        _biometricEnabled = bioEnabled;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    return Scaffold(
      appBar: AppBar(title: Text(lang.t('settings')), backgroundColor: AppTheme.primaryGreen),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Language
          Text(lang.t('language'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.darkGreen)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.lightGreen),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(child: DropdownButton<String>(
              value: lang.code, isExpanded: true,
              items: LanguageProvider.languages.entries.map((e) =>
                DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
              onChanged: (val) {
                if (val != null) lang.setLanguage(val);
              },
            )),
          ),
          const SizedBox(height: 24),

          // Biometric
          if (_biometricAvailable) ...[
            Text(lang.t('security'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.darkGreen)),
            SwitchListTile(
              title: Text(lang.t('biometric_login')),
              subtitle: Text(lang.t('biometric_desc')),
              value: _biometricEnabled,
              activeColor: AppTheme.primaryGreen,
              onChanged: (val) async {
                await _biometricService.setBiometricEnabled(val);
                setState(() => _biometricEnabled = val);
              },
            ),
            const Divider(),
          ],

          // Change Password
          const SizedBox(height: 16),
          Text(lang.t('security'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.darkGreen)),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _showChangePasswordDialog,
              icon: const Icon(Icons.lock_outline, color: AppTheme.primaryGreen),
              label: Text(lang.t('change_password'), style: const TextStyle(fontSize: 16, color: AppTheme.primaryGreen)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.primaryGreen),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReviewsListPage()),
              ),
              icon: const Icon(Icons.rate_review_outlined, color: AppTheme.primaryGreen),
              label: const Text('My Reviews', style: TextStyle(fontSize: 16, color: AppTheme.primaryGreen)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.primaryGreen),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Server Configuration
          const Text('Network & Server', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.darkGreen)),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                await ServerConfigDialog.show(context);
                if (mounted) setState(() {});
              },
              icon: const Icon(Icons.dns_outlined, color: AppTheme.primaryGreen),
              label: Text('Server URL: ${ApiConfig.baseUrl}', style: const TextStyle(fontSize: 13, color: AppTheme.primaryGreen), overflow: TextOverflow.ellipsis),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.primaryGreen),
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Logout
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                await _authService.logout();
                if (mounted) {
                  Navigator.pushAndRemoveUntil(context,
                    MaterialPageRoute(builder: (_) => const LoginPage()), (_) => false);
                }
              },
              icon: const Icon(Icons.logout),
              label: Text(lang.t('logout'), style: const TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
