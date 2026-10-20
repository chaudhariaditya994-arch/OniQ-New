import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  static const String defaultUrl = 'http://127.0.0.1:8000';
  static const String _prefKey = 'oniq_server_url';
  static String _baseUrl = defaultUrl;

  static String get baseUrl => _baseUrl;

  /// Loads persisted custom server URL on app startup
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefKey);
      if (saved != null && saved.trim().isNotEmpty) {
        _baseUrl = _normalize(saved);
      }
    } catch (_) {}
  }

  /// Sets and persists a new server URL
  static Future<void> setBaseUrl(String url) async {
    final cleaned = _normalize(url);
    _baseUrl = cleaned;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, cleaned);
    } catch (_) {}
  }

  /// Resets to default server URL
  static Future<void> resetBaseUrl() async {
    _baseUrl = defaultUrl;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefKey);
    } catch (_) {}
  }

  static String _normalize(String url) {
    var u = url.trim();
    if (!u.startsWith('http://') && !u.startsWith('https://')) {
      u = 'http://$u';
    }
    if (u.endsWith('/')) {
      u = u.substring(0, u.length - 1);
    }
    return u;
  }

  // Auth endpoints
  static String get register => '$baseUrl/api/v1/auth/register';
  static String get login => '$baseUrl/api/v1/auth/login';
  static String profile(String email) => '$baseUrl/api/v1/auth/profile/$email';
  static String get changePassword => '$baseUrl/api/v1/auth/change-password';
  static String forgotPassword(String email) =>
      '$baseUrl/api/v1/auth/forgot-password/$email';
  static String get resetPassword => '$baseUrl/api/v1/auth/reset-password';
  static String get feedback => '$baseUrl/api/v1/feedback';

  // Diagnosis endpoints
  static String get predict => '$baseUrl/api/v1/diagnosis/predict';
  static String diagnosisHistory(String email) =>
      '$baseUrl/api/v1/diagnosis/history/$email';

  // LLM endpoints
  static String get llmFreshness => '$baseUrl/api/v1/llm/freshness';
  static String get llmTranslate => '$baseUrl/api/v1/llm/translate';
  static String get llmIdentifyObject => '$baseUrl/api/v1/llm/identify-object';

  // Treatment endpoints
  static String treatment(String disease) =>
      '$baseUrl/api/v1/treatment/$disease';
  static String treatmentVoice(String disease, String lang) =>
      '$baseUrl/api/v1/treatment/$disease/voice/$lang';

  // Analytics endpoints
  static String get analyticsLog => '$baseUrl/api/v1/analytics/log';
  static String analyticsSummary(String email) =>
      '$baseUrl/api/v1/analytics/summary/$email';
  static String get analyticsRegional => '$baseUrl/api/v1/analytics/regional';
  static String get analyticsSummaryAll => '$baseUrl/api/v1/analytics/summary-all';
  static String get analyticsAllScans => '$baseUrl/api/v1/analytics/all-scans';
  static String analyticsTimeseries(String email, {int days = 30}) =>
      '$baseUrl/api/v1/analytics/timeseries/$email?days=$days';

  // Admin endpoints
  static String get usersList => '$baseUrl/api/v1/auth/users';
  static String toggleUserStatus(String email) =>
      '$baseUrl/api/v1/auth/users/$email/toggle-status';

  // Review / Correction endpoints
  static String get reviews => '$baseUrl/api/v1/reviews';
  static String reviewById(String id) => '$baseUrl/api/v1/reviews/$id';
  static String reviewsByUser(String email) =>
      '$baseUrl/api/v1/reviews/by-user/$email';
  static String get reviewsExport => '$baseUrl/api/v1/reviews/export.zip';

  // OniQ Storage Monitoring endpoints
  static String get storageBatches => '$baseUrl/api/v1/storage/batches';
  static String storageBatchesByUser(String email) =>
      '$baseUrl/api/v1/storage/batches?user_email=$email';
  static String storageBatchById(String id) =>
      '$baseUrl/api/v1/storage/batches/$id';
  static String storageCurrentStatus(String id) =>
      '$baseUrl/api/v1/storage/batches/$id/current';
  static String storageHistory(String id, {int limit = 50}) =>
      '$baseUrl/api/v1/storage/batches/$id/history?limit=$limit';
  static String storageAdvisory(String id) =>
      '$baseUrl/api/v1/storage/batches/$id/advisory';
  static String storageAlerts(String email) =>
      '$baseUrl/api/v1/storage/alerts/$email';
  static String get storageTelemetry => '$baseUrl/api/v1/storage/telemetry';
}
