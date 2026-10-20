import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../providers/language_provider.dart';
import '../services/auth_service.dart';
import '../services/biometric_service.dart';
import '../widgets/onion_dialog.dart';
import '../widgets/server_config_dialog.dart';
import 'register_page.dart';
import 'home_page.dart';
import 'reset_password_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  final _biometricService = BiometricService();
  String _selectedUserType = 'Farmer';
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;

  final List<String> _userTypes = ['Farmer', 'Admin', 'Extension_Officer'];

  @override
  void initState() {
    super.initState();
    _checkBiometric();
  }

  Future<void> _checkBiometric() async {
    final available = await _biometricService.isBiometricAvailable();
    final enabled = await _biometricService.isBiometricEnabled();
    if (mounted) {
      setState(() {
        _biometricAvailable = available;
        _biometricEnabled = enabled;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.dns_outlined, color: Colors.white),
              tooltip: 'Server Settings',
              onPressed: () => ServerConfigDialog.show(context),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.language, color: Colors.white),
              tooltip: 'Select Language',
              onSelected: (code) => lang.setLanguage(code),
              itemBuilder: (ctx) => LanguageProvider.languages.entries.map((e) =>
                PopupMenuItem(value: e.key, child: Text(e.value))
              ).toList(),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildIcon(),
                    const SizedBox(height: 16),
                    Text(lang.t('app_title'), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5)),
                    const SizedBox(height: 24),
                    _buildInputField(lang.t('email'), _emailController, icon: Icons.email_outlined),
                    const SizedBox(height: 14),
                    _buildPasswordField(lang),
                    const SizedBox(height: 14),
                    _buildUserTypeDropdown(),
                    const SizedBox(height: 24),
                    _buildLoginButton(lang),
                    const SizedBox(height: 12),
                    _buildGuestLoginButton(lang),
                    if (_biometricAvailable && _biometricEnabled) ...[
                      const SizedBox(height: 14),
                      _buildBiometricButton(lang),
                    ],
                    const SizedBox(height: 20),
                    _buildRegisterLink(lang),
                    const SizedBox(height: 12),
                    _buildForgotPasswordLink(lang),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white.withOpacity(0.5), width: 2.5),
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, spreadRadius: 2)],
        color: Colors.white.withOpacity(0.2),
      ),
      child: const Icon(Icons.eco, size: 44, color: Colors.white),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, {IconData? icon}) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: AppTheme.inputDecoration(label, icon: icon),
    );
  }

  Widget _buildPasswordField(LanguageProvider lang) {
    return TextField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      style: const TextStyle(color: Colors.white),
      decoration: AppTheme.inputDecoration(lang.t('password'), icon: Icons.lock_outline).copyWith(
        suffixIcon: IconButton(
          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.white70),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
      ),
    );
  }

  Widget _buildUserTypeDropdown() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white),
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withOpacity(0.1),
      ),
      child: Row(
        children: [
          const Icon(Icons.person_outline, color: Colors.white70),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedUserType,
                isExpanded: true,
                dropdownColor: AppTheme.mediumGreen,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                items: _userTypes.map((type) => DropdownMenuItem(
                  value: type,
                  child: Text(type.replaceAll('_', ' '), style: const TextStyle(color: Colors.white), overflow: TextOverflow.ellipsis),
                )).toList(),
                onChanged: (val) => setState(() => _selectedUserType = val!),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginButton(LanguageProvider lang) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _login,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppTheme.primaryGreen,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: const StadiumBorder(),
        ),
        child: _isLoading
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : Text(lang.t('login'), style: const TextStyle(fontSize: 20)),
      ),
    );
  }

  Widget _buildGuestLoginButton(LanguageProvider lang) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _isLoading ? null : _loginAsGuest,
        icon: const Icon(Icons.offline_bolt_outlined, color: Colors.white, size: 20),
        label: const Text(
          'Continue Offline (Guest)',
          style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.white, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: const StadiumBorder(),
          backgroundColor: Colors.white.withOpacity(0.12),
        ),
      ),
    );
  }

  Future<void> _loginAsGuest() async {
    setState(() => _isLoading = true);
    try {
      final res = await _authService.loginAsGuest();
      if (res['success'] == true && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage(userEmail: 'farmer@oniq.app')),
        );
      }
    } catch (e) {
      if (mounted) {
        OnionDialog.showError(context, title: 'Guest Mode', message: 'Could not enter guest mode: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildBiometricButton(LanguageProvider lang) {
    return OutlinedButton.icon(
      onPressed: _authenticateWithBiometric,
      icon: const Icon(Icons.fingerprint, color: Colors.white, size: 28),
      label: Text(lang.t('login_biometric'), style: const TextStyle(color: Colors.white, fontSize: 16)),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Colors.white),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        shape: const StadiumBorder(),
      ),
    );
  }

  Widget _buildRegisterLink(LanguageProvider lang) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterPage())),
      child: Text(lang.t('no_account'),
          style: const TextStyle(fontSize: 16, color: Colors.white)),
    );
  }

  Widget _buildForgotPasswordLink(LanguageProvider lang) {
    return GestureDetector(
      onTap: _showForgotPasswordDialog,
      child: Text(lang.t('forgot_password'), style: const TextStyle(fontSize: 14, color: Colors.white70)),
    );
  }

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      OnionDialog.showError(context, title: 'Error', message: 'Please fill in all fields');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final result = await _authService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        userType: _selectedUserType,
      );
      if (result['success'] == true && mounted) {
        await _biometricService.setBiometricEnabled(true);
        if (result['offline'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Working in Offline Mode'),
              backgroundColor: AppTheme.primaryGreen,
              duration: Duration(seconds: 2),
            ),
          );
        }
        Navigator.pushReplacement(context, MaterialPageRoute(
          builder: (_) => HomePage(userEmail: _emailController.text.trim()),
        ));
      } else {
        if (mounted) OnionDialog.showError(context, title: 'Login Failed', message: result['detail'] ?? 'Invalid credentials');
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.wifi_off, color: Colors.orange),
                SizedBox(width: 8),
                Text('Server Unreachable'),
              ],
            ),
            content: const Text(
              'Could not connect to the backend server. Would you like to enter in Offline Mode or update the Server IP?',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  ServerConfigDialog.show(context);
                },
                child: const Text('Server Settings'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _loginAsGuest();
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
                child: const Text('Continue Offline', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _authenticateWithBiometric() async {
    final result = await _biometricService.authenticateDetailed();
    if (!mounted) return;
    if (result.success) {
      final email = await _authService.getSavedEmail() ?? '';
      if (!mounted) return;
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => HomePage(userEmail: email)));
    } else if (result.errorMessage != null) {
      OnionDialog.showError(context,
          title: 'Biometric Login', message: result.errorMessage!);
    }
  }

  void _showForgotPasswordDialog() {
    final lang = context.read<LanguageProvider>();
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        title: Text(lang.t('reset_password'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: lang.t('email'),
                  prefixIcon: const Icon(Icons.email_outlined),
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
                    final email = controller.text.trim();
                    if (email.isEmpty) return;
                    Navigator.pop(ctx);
                    await _authService.forgotPassword(email);
                    if (!mounted) return;
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => ResetPasswordPage(email: email)),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: Text(lang.t('send')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
