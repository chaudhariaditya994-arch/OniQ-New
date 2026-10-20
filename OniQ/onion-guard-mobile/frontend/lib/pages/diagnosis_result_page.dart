import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../config/app_theme.dart';
import '../providers/language_provider.dart';
import 'treatment_page.dart';
import 'review_page.dart';

class DiagnosisResultPage extends StatefulWidget {
  final String imagePath;
  final String diseaseName;
  final double confidence;
  final Map<String, dynamic> allPredictions;

  const DiagnosisResultPage({
    super.key,
    required this.imagePath,
    required this.diseaseName,
    required this.confidence,
    required this.allPredictions,
  });

  @override
  State<DiagnosisResultPage> createState() => _DiagnosisResultPageState();
}

class _DiagnosisResultPageState extends State<DiagnosisResultPage> {
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _saveToBackend();
  }

  Future<void> _saveToBackend() async {
    if (_saved || widget.imagePath.isEmpty) return; // Skip if from history
    _saved = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('user_email') ?? '';
      if (email.isEmpty) return;

      // Cache locally so it is immediately visible in scan history even when completely offline
      try {
        final key = 'oniq_local_history_$email';
        final existing = prefs.getString(key);
        List<dynamic> list = existing != null ? json.decode(existing) : [];
        list.insert(0, {
          'disease': widget.diseaseName,
          'confidence': widget.confidence,
          'all_predictions': widget.allPredictions,
          'timestamp': DateTime.now().toUtc().toIso8601String(),
        });
        if (list.length > 50) list = list.sublist(0, 50);
        await prefs.setString(key, json.encode(list));
      } catch (_) {}

      await Future.wait([
        http.post(
          Uri.parse('${ApiConfig.baseUrl}/api/v1/diagnosis/save'),
          headers: {"Content-Type": "application/json"},
          body: json.encode({
            'email': email,
            'disease': widget.diseaseName,
            'confidence': widget.confidence,
            'all_predictions': widget.allPredictions,
          }),
        ).timeout(const Duration(seconds: 3)),
        http.post(
          Uri.parse(ApiConfig.analyticsLog),
          headers: {"Content-Type": "application/json"},
          body: json.encode({
            'email': email,
            'disease': widget.diseaseName,
            'confidence': widget.confidence,
          }),
        ).timeout(const Duration(seconds: 3)),
      ]);
    } catch (_) {}
  }

  String get imagePath => widget.imagePath;
  String get diseaseName => widget.diseaseName;
  double get confidence => widget.confidence;
  Map<String, dynamic> get allPredictions => widget.allPredictions;

  Color get _severityColor {
    if (diseaseName == 'Healthy') return Colors.green;
    if (confidence > 90) return Colors.red;
    if (confidence > 70) return Colors.orange;
    return Colors.yellow.shade700;
  }

  String get _severityLabel {
    if (diseaseName == 'Healthy') return 'No Disease Detected';
    if (confidence > 90) return 'High Confidence';
    if (confidence > 70) return 'Moderate Confidence';
    return 'Low Confidence';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Diagnosis Result'), backgroundColor: AppTheme.primaryGreen),
      floatingActionButton: imagePath.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ReviewPage(
                    imagePath: imagePath,
                    originalPrediction: diseaseName,
                    originalConfidence: confidence,
                  ),
                ),
              ),
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.rate_review_outlined),
              label: const Text('Review this'),
              tooltip: 'Disagree with this result? Submit a correction',
            ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            if (imagePath.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(File(imagePath), height: 250, width: double.infinity, fit: BoxFit.cover),
              ),
            const SizedBox(height: 20),

            // Disease Name
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _severityColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _severityColor, width: 2),
              ),
              child: Column(
                children: [
                  Icon(diseaseName == 'Healthy' ? Icons.check_circle : Icons.warning, size: 50, color: _severityColor),
                  const SizedBox(height: 12),
                  Text(diseaseName.replaceAll('_', ' '), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _severityColor)),
                  const SizedBox(height: 8),
                  Text('${confidence.toStringAsFixed(1)}% ${context.read<LanguageProvider>().t('confidence')}', style: const TextStyle(fontSize: 18, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text(_severityLabel, style: TextStyle(fontSize: 14, color: _severityColor, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Confidence Bar
            const Text('All Predictions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...allPredictions.entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(e.key.toString().replaceAll('_', ' '), style: const TextStyle(fontSize: 13)),
                      Text('${(e.value as num).toStringAsFixed(1)}%', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: (e.value as num) / 100,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation(e.key == diseaseName ? _severityColor : Colors.grey),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            )),
            const SizedBox(height: 24),

            // Treatment Button
            if (diseaseName != 'Healthy')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => TreatmentPage(diseaseName: diseaseName),
                  )),
                  icon: const Icon(Icons.medical_services),
                  label: Text(context.read<LanguageProvider>().t('view_treatment'), style: const TextStyle(fontSize: 18)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen, foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
