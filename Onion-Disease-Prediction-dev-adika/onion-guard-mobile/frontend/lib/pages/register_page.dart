import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../providers/language_provider.dart';
import '../services/auth_service.dart';
import '../widgets/onion_dialog.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  String _selectedUserType = 'Farmer';
  String _selectedLanguage = 'en';
  bool _obscurePassword = true;
  bool _isLoading = false;

  final List<String> _userTypes = ['Farmer', 'Admin', 'Extension_Officer'];

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 72, height: 72,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white.withOpacity(0.5), width: 2.5),
                        shape: BoxShape.circle, color: Colors.white.withOpacity(0.2),
                      ),
                      child: const Icon(Icons.eco, size: 40, color: Colors.white),
                    ),
                    const SizedBox(height: 14),
                    Text(lang.t('create_account'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 20),
                    _input(lang.t('full_name'), _nameController, Icons.person),
                    const SizedBox(height: 12),
                    _input(lang.t('email'), _emailController, Icons.email),
                    const SizedBox(height: 12),
                    _input(lang.t('username'), _usernameController, Icons.person_outline),
                    const SizedBox(height: 12),
                    _input(lang.t('phone'), _phoneController, Icons.phone, keyboard: TextInputType.phone),
                    const SizedBox(height: 12),
                    _passwordField(lang),
                    const SizedBox(height: 12),
                    _dropdown(lang.t('user_type'), _selectedUserType, _userTypes.map((t) => MapEntry(t, t.replaceAll('_', ' '))).toList(),
                        (val) => setState(() => _selectedUserType = val!), Icons.badge),
                    const SizedBox(height: 12),
                    _dropdown(lang.t('language'), _selectedLanguage, LanguageProvider.languages.entries.map((e) => MapEntry(e.key, e.value)).toList(),
                        (val) => setState(() => _selectedLanguage = val!), Icons.language),
                    const SizedBox(height: 24),
                    _registerButton(lang),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage())),
                      child: Text(lang.t('have_account'), style: const TextStyle(color: Colors.white, fontSize: 15)),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _input(String label, TextEditingController controller, IconData icon, {TextInputType keyboard = TextInputType.text}) {
    return TextField(
      controller: controller, style: const TextStyle(color: Colors.white),
      keyboardType: keyboard,
      decoration: AppTheme.inputDecoration(label, icon: icon),
    );
  }

  Widget _passwordField(LanguageProvider lang) {
    return TextField(
      controller: _passwordController, obscureText: _obscurePassword,
      style: const TextStyle(color: Colors.white),
      decoration: AppTheme.inputDecoration(lang.t('password'), icon: Icons.lock).copyWith(
        suffixIcon: IconButton(
          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.white70),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
      ),
    );
  }

  Widget _dropdown(String label, String value, List<MapEntry<String, String>> items, ValueChanged<String?> onChanged, IconData icon) {
    return Container(
      height: 56, padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(border: Border.all(color: Colors.white), borderRadius: BorderRadius.circular(18), color: Colors.white.withOpacity(0.1)),
      child: Row(children: [
        Icon(icon, color: Colors.white70), const SizedBox(width: 10),
        Expanded(child: DropdownButtonHideUnderline(child: DropdownButton<String>(
          value: value, isExpanded: true, dropdownColor: AppTheme.mediumGreen,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          items: items.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, style: const TextStyle(color: Colors.white), overflow: TextOverflow.ellipsis))).toList(),
          onChanged: onChanged,
        ))),
      ]),
    );
  }

  Widget _registerButton(LanguageProvider lang) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _register,
        style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppTheme.primaryGreen, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
        child: _isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Text(lang.t('register'), style: const TextStyle(fontSize: 20)),
      ),
    );
  }

  Future<void> _register() async {
    if ([_nameController, _emailController, _usernameController, _phoneController, _passwordController].any((c) => c.text.isEmpty)) {
      OnionDialog.showError(context, title: 'Error', message: 'Please fill in all fields');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final result = await _authService.register(
        name: _nameController.text.trim(), email: _emailController.text.trim(),
        username: _usernameController.text.trim(), phone: _phoneController.text.trim(),
        password: _passwordController.text.trim(), userType: _selectedUserType,
        languagePreference: _selectedLanguage,
      );
      if (mounted) {
        if (result['success'] == true) {
          OnionDialog.showSuccess(context, title: 'Success', message: 'Account successfully created.',
              onDismiss: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage())));
        } else {
          OnionDialog.showError(context, title: 'Failed', message: result['detail'] ?? 'Registration failed');
        }
      }
    } catch (e) {
      if (mounted) OnionDialog.showError(context, title: 'Error', message: 'Failed to connect to server');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
