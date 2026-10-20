import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../config/app_theme.dart';
import '../providers/language_provider.dart';
import '../services/auth_service.dart';
import '../services/diagnosis_service.dart';
import '../services/openrouter_service.dart';
import '../models/user_model.dart';
import '../widgets/onion_dialog.dart';
import 'diagnosis_result_page.dart';
import 'analytics_page.dart';
import 'admin_dashboard_page.dart';
import 'officer_dashboard_page.dart';
import 'freshness_page.dart';
import 'settings_page.dart';
import 'login_page.dart';
import 'talk_to_us_page.dart';
import 'storage_page.dart';

class HomePage extends StatefulWidget {
  final String userEmail;
  const HomePage({super.key, required this.userEmail});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _authService = AuthService();
  final _diagnosisService = DiagnosisService();
  final _openRouterService = OpenRouterService();
  final _picker = ImagePicker();
  UserModel? _user;
  int _currentIndex = 0;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _diagnosisService.loadModel().catchError((_) {});
  }

  Future<void> _loadUser() async {
    final user = await _authService.getSavedUser();
    if (mounted) setState(() => _user = user);
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldLogout = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(lang.t('logout')),
            content: Text(lang.t('do_you_want_logout')),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(lang.t('no'))),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen, foregroundColor: Colors.white),
                child: Text(lang.t('yes')),
              ),
            ],
          ),
        );
        if (shouldLogout == true && mounted) {
          await _authService.logout();
          if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
        }
      },
      child: Scaffold(
      appBar: AppBar(
        title: Text(lang.t('app_title')),
        automaticallyImplyLeading: false,
        backgroundColor: AppTheme.primaryGreen,
        actions: [
          IconButton(
            icon: const Icon(Icons.warehouse_rounded),
            tooltip: "OniQ Storage Monitor",
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StoragePage(userEmail: widget.userEmail),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.person_rounded),
            tooltip: _user?.name ?? widget.userEmail,
            onPressed: _showProfileMenu,
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: AppTheme.primaryGreen,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (i) => setState(() => _currentIndex = i),
        items: _buildNavItems(lang),
      ),
    ));
  }

  String get _userType => _user?.userType ?? 'Farmer';

  void _showProfileMenu() {
    final lang = context.read<LanguageProvider>();
    final name = _user?.name ?? '';
    final email = widget.userEmail;
    final role = _user?.userType ?? 'Farmer';
    final initial = (name.isNotEmpty ? name[0] : email.isNotEmpty ? email[0] : '?').toUpperCase();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.15),
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: AppTheme.darkGreen, fontSize: 22, fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (name.isNotEmpty)
                          Text(name,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                              overflow: TextOverflow.ellipsis),
                        Text(email,
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            role.replaceAll('_', ' '),
                            style: const TextStyle(
                              fontSize: 11, color: AppTheme.darkGreen, fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.person_outline_rounded, color: AppTheme.primaryGreen),
              title: Text(lang.t('my_profile')),
              onTap: () {
                Navigator.pop(sheetCtx);
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => SettingsPage(userEmail: widget.userEmail),
                ));
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat_bubble_outline_rounded, color: AppTheme.primaryGreen),
              title: Text(lang.t('talk_to_us')),
              onTap: () {
                Navigator.pop(sheetCtx);
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => TalkToUsPage(user: _user, userEmail: widget.userEmail),
                ));
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              title: Text(lang.t('logout'),
                  style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
              onTap: () async {
                Navigator.pop(sheetCtx);
                await _confirmAndLogout();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmAndLogout() async {
    final lang = context.read<LanguageProvider>();
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(lang.t('logout')),
        content: Text(lang.t('do_you_want_logout')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(lang.t('no'))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen, foregroundColor: Colors.white,
            ),
            child: Text(lang.t('yes')),
          ),
        ],
      ),
    );
    if (shouldLogout == true && mounted) {
      await _authService.logout();
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
      }
    }
  }

  Widget _buildBody() {
    switch (_userType) {
      case 'Admin':
        return [_buildHome(), const FreshnessPage(), const AdminUsersPage(), const AdminAnalyticsPage()][_currentIndex];
      case 'Extension_Officer':
        return [_buildHome(), const FreshnessPage(), const OfficerScansPage(), const OfficerTrendsPage()][_currentIndex];
      default: // Farmer
        return [_buildHome(), const FreshnessPage(), _buildHistory(), const AnalyticsPage()][_currentIndex];
    }
  }

  List<BottomNavigationBarItem> _buildNavItems(LanguageProvider lang) {
    switch (_userType) {
      case 'Admin':
        return [
          BottomNavigationBarItem(icon: const Icon(Icons.home), label: lang.t('home')),
          BottomNavigationBarItem(icon: const Icon(Icons.spa), label: lang.t('freshness')),
          const BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Users'),
          BottomNavigationBarItem(icon: const Icon(Icons.analytics), label: lang.t('analytics')),
        ];
      case 'Extension_Officer':
        return [
          BottomNavigationBarItem(icon: const Icon(Icons.home), label: lang.t('home')),
          BottomNavigationBarItem(icon: const Icon(Icons.spa), label: lang.t('freshness')),
          const BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Scans'),
          const BottomNavigationBarItem(icon: Icon(Icons.trending_up), label: 'Trends'),
        ];
      default: // Farmer
        return [
          BottomNavigationBarItem(icon: const Icon(Icons.home), label: lang.t('home')),
          BottomNavigationBarItem(icon: const Icon(Icons.spa), label: lang.t('freshness')),
          BottomNavigationBarItem(icon: const Icon(Icons.history), label: lang.t('history')),
          BottomNavigationBarItem(icon: const Icon(Icons.analytics), label: lang.t('analytics')),
        ];
    }
  }

  Widget _buildHome() {
    final lang = context.read<LanguageProvider>();
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Welcome Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppTheme.backgroundGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${lang.t('welcome')}, ${_user?.name ?? 'Farmer'}!',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 8),
                  Text(lang.t('protect_crops'), style: const TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Big Scan Button
            SizedBox(
              width: double.infinity,
              height: 180,
              child: ElevatedButton(
                onPressed: _isScanning ? null : _scanDisease,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  elevation: 6,
                ),
                child: _isScanning
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.camera_alt, size: 56),
                          const SizedBox(height: 12),
                          Text(lang.t('scan_disease'), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Text(lang.t('take_photo'), style: const TextStyle(fontSize: 14, color: Colors.white70)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),

            // Gallery button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: _isScanning ? null : _pickFromGallery,
                icon: const Icon(Icons.photo_library),
                label: Text(lang.t('gallery'), style: const TextStyle(fontSize: 16)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryGreen,
                  side: const BorderSide(color: AppTheme.primaryGreen, width: 2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // OniQ Storage Monitoring Hub Banner Card
            InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StoragePage(userEmail: widget.userEmail),
                ),
              ),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.12),
                      child: const Icon(
                        Icons.warehouse_rounded,
                        color: AppTheme.primaryGreen,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "OniQ Storage Monitor",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            "Real-time sensors, spoilage index & AI advice",
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistory() {
    return _HistoryView(key: UniqueKey(), userEmail: widget.userEmail);
  }

  Future<void> _scanDisease() async {
    final image = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (image == null) return;
    await _processImage(File(image.path));
  }

  Future<void> _pickFromGallery() async {
    final image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (image == null) return;
    await _processImage(File(image.path));
  }

  Future<void> _processImage(File imageFile) async {
    setState(() => _isScanning = true);
    try {
      // Pre-check: verify the image is actually an onion before running disease ML.
      // Fail-CLOSED: any backend issue (Gemini overload, parse error, network) is
      // surfaced to the user as a friendly "please retake the photo" — they never
      // see Gemini/upstream details, and we never run disease ML on a non-onion.
      final check = await _openRouterService.checkIsOnion(imageFile);
      if (!mounted) return;
      final lang = context.read<LanguageProvider>();
      final status = check['status'];
      if (status == 'not_onion') {
        final detected = (check['detected_object'] as String?)?.trim();
        final detectedLabel = (detected == null || detected.isEmpty)
            ? lang.t('unknown_object')
            : detected;
        OnionDialog.showInfo(
          context,
          title: lang.t('not_an_onion_title'),
          message: lang.t('not_onion_retake_message').replaceAll('{object}', detectedLabel),
        );
        setState(() => _isScanning = false);
        return;
      }
      if (status == 'retake') {
        OnionDialog.showInfo(
          context,
          title: lang.t('retake_image_title'),
          message: lang.t('retake_image_message'),
        );
        setState(() => _isScanning = false);
        return;
      }

      final result = await _diagnosisService.classifyImage(imageFile);
      final disease = result['class_name'].toString();
      final confidence = (result['confidence'] as num).toDouble();
      final allPredictions = <String, dynamic>{};
      (result['all_predictions'] as Map).forEach((k, v) {
        allPredictions[k.toString()] = (v as num).toDouble();
      });

      // Navigate to result page (saving handled by DiagnosisResultPage)
      if (mounted) {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => DiagnosisResultPage(
            imagePath: imageFile.path,
            diseaseName: disease,
            confidence: confidence,
            allPredictions: allPredictions,
          ),
        ));
      }
    } catch (e) {
      if (mounted) OnionDialog.showError(context, title: 'Scan Failed', message: 'Could not analyze image: $e');
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

}

class _HistoryView extends StatefulWidget {
  final String userEmail;
  const _HistoryView({super.key, required this.userEmail});

  @override
  State<_HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<_HistoryView> {
  List<dynamic> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final resp = await http.get(Uri.parse(ApiConfig.diagnosisHistory(widget.userEmail))).timeout(const Duration(seconds: 3));
      final data = json.decode(resp.body);
      if (data['success'] == true && mounted) {
        setState(() { _history = data['history'] ?? []; _isLoading = false; });
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('oniq_local_history_${widget.userEmail}', json.encode(_history));
        return;
      }
    } catch (_) {}

    // Offline fallback: load from local cache
    try {
      final prefs = await SharedPreferences.getInstance();
      final local = prefs.getString('oniq_local_history_${widget.userEmail}');
      if (local != null && mounted) {
        setState(() {
          _history = json.decode(local);
          _isLoading = false;
        });
        return;
      }
    } catch (_) {}

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    if (_isLoading) return const Center(child: CircularProgressIndicator());

    if (_history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.history, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            Text(lang.t('scan_history_empty'), style: const TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadHistory,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _history.length,
        itemBuilder: (context, index) {
          final item = _history[index];
          final disease = item['disease'] ?? 'Unknown';
          final confidence = (item['confidence'] ?? 0).toDouble();
          final timestamp = item['timestamp'] ?? '';
          final isHealthy = disease == 'Healthy';

          String timeAgo = '';
          try {
            final dt = DateTime.parse(timestamp);
            final diff = DateTime.now().toUtc().difference(dt);
            if (diff.inMinutes < 60) {
              timeAgo = '${diff.inMinutes}m ago';
            } else if (diff.inHours < 24) {
              timeAgo = '${diff.inHours}h ago';
            } else {
              timeAgo = '${diff.inDays}d ago';
            }
          } catch (_) {
            timeAgo = timestamp;
          }

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: isHealthy ? Colors.green.shade100 : Colors.red.shade100,
                child: Icon(
                  isHealthy ? Icons.check_circle : Icons.warning,
                  color: isHealthy ? Colors.green : Colors.red,
                ),
              ),
              title: Text(disease.replaceAll('_', ' '), style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${confidence.toStringAsFixed(1)}% ${lang.t('confidence')}  •  $timeAgo'),
              trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => DiagnosisResultPage(
                    imagePath: '',
                    diseaseName: disease,
                    confidence: confidence,
                    allPredictions: Map<String, dynamic>.from(item['all_predictions'] ?? {}),
                  ),
                ));
              },
            ),
          );
        },
      ),
    );
  }
}
