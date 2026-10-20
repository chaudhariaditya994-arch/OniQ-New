import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:shared_preferences/shared_preferences.dart';

class BiometricAuthResult {
  final bool success;
  final String? errorMessage;
  const BiometricAuthResult(this.success, [this.errorMessage]);
}

class BiometricService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  static const String _biometricEnabledKey = 'biometric_enabled';

  Future<bool> isBiometricAvailable() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      return canCheck && isSupported;
    } catch (_) {
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  /// Detailed authenticate. Returns success + a human-readable reason on failure.
  Future<BiometricAuthResult> authenticateDetailed() async {
    try {
      final ok = await _localAuth.authenticate(
        localizedReason: 'Authenticate to access OniQ',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      return BiometricAuthResult(ok, ok ? null : 'Authentication cancelled');
    } on PlatformException catch (e) {
      String msg;
      switch (e.code) {
        case auth_error.notAvailable:
          msg = 'Biometric authentication is not available on this device.';
          break;
        case auth_error.notEnrolled:
          msg = 'No fingerprint enrolled. Add one in your phone settings, then try again.';
          break;
        case auth_error.lockedOut:
          msg = 'Too many failed attempts. Try again later.';
          break;
        case auth_error.permanentlyLockedOut:
          msg = 'Biometrics permanently locked. Unlock the device with your PIN, then try again.';
          break;
        case auth_error.passcodeNotSet:
          msg = 'Set a screen lock on the device first.';
          break;
        default:
          msg = 'Biometric error: ${e.message ?? e.code}';
      }
      return BiometricAuthResult(false, msg);
    } catch (e) {
      return BiometricAuthResult(false, 'Unexpected error: $e');
    }
  }

  /// Backwards-compatible boolean variant (callers that don't need the reason).
  Future<bool> authenticate() async {
    final r = await authenticateDetailed();
    return r.success;
  }

  Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricEnabledKey) ?? false;
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricEnabledKey, enabled);
  }
}
