import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../providers/language_provider.dart';
import '../services/openrouter_service.dart';
import '../widgets/onion_dialog.dart';

class FreshnessPage extends StatefulWidget {
  const FreshnessPage({super.key});

  @override
  State<FreshnessPage> createState() => _FreshnessPageState();
}

class _FreshnessPageState extends State<FreshnessPage> {
  final _openRouterService = OpenRouterService();
  final _picker = ImagePicker();
  bool _isAnalyzing = false;
  File? _selectedImage;
  Map<String, dynamic>? _result;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    // If we have a result or are analyzing, show scrollable content
    if (_result != null || _isAnalyzing || _selectedImage != null || _error != null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isAnalyzing)
              Center(
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    const CircularProgressIndicator(color: AppTheme.primaryGreen),
                    const SizedBox(height: 16),
                    Text(lang.t('analyzing'), style: const TextStyle(fontSize: 16, color: Colors.grey)),
                  ],
                ),
              ),

            if (_selectedImage != null && !_isAnalyzing)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(_selectedImage!, width: double.infinity, height: 200, fit: BoxFit.cover),
              ),

            if (_selectedImage != null && !_isAnalyzing) const SizedBox(height: 16),

            if (_error != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(_error!, style: TextStyle(color: Colors.red.shade700)),
              ),

            if (_result != null) _buildResult(),

            const SizedBox(height: 20),
            // Scan again buttons
            if (!_isAnalyzing) ...[
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _captureFromCamera,
                  icon: const Icon(Icons.camera_alt),
                  label: Text(lang.t('freshness_check'), style: const TextStyle(fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen, foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _pickFromGallery,
                  icon: const Icon(Icons.photo_library),
                  label: Text(lang.t('gallery'), style: const TextStyle(fontSize: 16)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryGreen,
                    side: const BorderSide(color: AppTheme.primaryGreen, width: 2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    // Default: centered scan UI matching home page
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Header
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
                  Text(lang.t('freshness_check'),
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 8),
                  Text(lang.t('freshness_desc'),
                      style: const TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Big scan button
            SizedBox(
              width: double.infinity,
              height: 180,
              child: ElevatedButton(
                onPressed: _captureFromCamera,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  elevation: 6,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.spa, size: 56),
                    const SizedBox(height: 12),
                    Text(lang.t('freshness_check'), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text(lang.t('freshness_desc'), style: const TextStyle(fontSize: 12, color: Colors.white70), textAlign: TextAlign.center),
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
                onPressed: _pickFromGallery,
                icon: const Icon(Icons.photo_library),
                label: Text(lang.t('gallery'), style: const TextStyle(fontSize: 16)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryGreen,
                  side: const BorderSide(color: AppTheme.primaryGreen, width: 2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResult() {
    final freshness = _result!['freshness'] ?? 'Unknown';
    final confidence = (_result!['confidence'] ?? 0).toDouble();
    final description = _result!['description'] ?? '';
    final tips = _result!['tips'] ?? '';

    Color freshnessColor;
    IconData freshnessIcon;
    switch (freshness) {
      case 'Fresh':
        freshnessColor = Colors.green;
        freshnessIcon = Icons.check_circle;
        break;
      case 'Almost Spoilt':
        freshnessColor = Colors.orange;
        freshnessIcon = Icons.warning;
        break;
      case 'Rotten':
        freshnessColor = Colors.red;
        freshnessIcon = Icons.cancel;
        break;
      default:
        freshnessColor = Colors.grey;
        freshnessIcon = Icons.help;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, spreadRadius: 2)],
      ),
      child: Column(
        children: [
          Icon(freshnessIcon, size: 60, color: freshnessColor),
          const SizedBox(height: 12),
          Text(freshness,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: freshnessColor)),
          const SizedBox(height: 8),
          Text('${confidence.toStringAsFixed(0)}% confidence',
              style: const TextStyle(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 16),

          // Description
          Builder(builder: (ctx) {
            final lang = ctx.read<LanguageProvider>();
            return Column(children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: freshnessColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(lang.t('analysis'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(description, style: const TextStyle(fontSize: 14)),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Tips
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.lightbulb, size: 18, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(lang.t('tips'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(tips, style: const TextStyle(fontSize: 14)),
                  ],
                ),
              ),
            ]);
          }),
        ],
      ),
    );
  }

  Future<void> _captureFromCamera() async {
    final image = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (image == null) return;
    await _analyzeImage(File(image.path));
  }

  Future<void> _pickFromGallery() async {
    final image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (image == null) return;
    await _analyzeImage(File(image.path));
  }

  Future<void> _analyzeImage(File imageFile) async {
    setState(() {
      _isAnalyzing = true;
      _selectedImage = imageFile;
      _result = null;
      _error = null;
    });

    try {
      // Pre-check: verify the image is actually an onion before running freshness analysis.
      // Fail-CLOSED: any backend issue (Gemini overload, parse error, network) is
      // surfaced as a friendly "please retake" dialog — user never sees upstream details.
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
        setState(() {
          _isAnalyzing = false;
          _selectedImage = null;
        });
        return;
      }
      if (status == 'retake') {
        OnionDialog.showInfo(
          context,
          title: lang.t('retake_image_title'),
          message: lang.t('retake_image_message'),
        );
        setState(() {
          _isAnalyzing = false;
          _selectedImage = null;
        });
        return;
      }

      final result = await _openRouterService.analyzeFreshness(imageFile);
      if (mounted) setState(() => _result = result);
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not analyze image: $e');
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }
}
