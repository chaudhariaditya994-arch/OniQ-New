import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import '../config/api_config.dart';
import '../config/app_theme.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../services/openrouter_service.dart';
import '../data/offline_treatments.dart';

class TreatmentPage extends StatefulWidget {
  final String diseaseName;
  const TreatmentPage({super.key, required this.diseaseName});

  @override
  State<TreatmentPage> createState() => _TreatmentPageState();
}

class _TreatmentPageState extends State<TreatmentPage> {
  Map<String, dynamic>? _treatment;
  bool _isLoading = true;
  bool _isTranslating = false;
  bool _isPlayingVoice = false;
  String _selectedLanguage = 'en';
  final AudioPlayer _audioPlayer = AudioPlayer();
  final OpenRouterService _openRouterService = OpenRouterService();

  // Translated display strings

  // Translated display strings
  String? _translatedDescription;
  List<String>? _translatedSymptoms;
  List<String>? _translatedSteps;
  List<String>? _translatedPrevention;

  @override
  void initState() {
    super.initState();
    _loadTreatment();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadTreatment() async {
    try {
      final resp = await http.get(Uri.parse(ApiConfig.treatment(widget.diseaseName))).timeout(const Duration(seconds: 3));
      final data = json.decode(resp.body);
      if (data['success'] == true && mounted) {
        setState(() { _treatment = data['treatment']; _isLoading = false; });
        return;
      }
    } catch (_) {}

    if (mounted) {
      final fallback = offlineTreatments[widget.diseaseName] ?? offlineTreatments['Healthy'];
      setState(() {
        _treatment = fallback;
        _isLoading = false;
      });
    }
  }

  Future<void> _onLanguageChanged(String lang) async {
    setState(() => _selectedLanguage = lang);

    if (lang == 'en' || _treatment == null) {
      setState(() {
        _translatedDescription = null;
        _translatedSymptoms = null;
        _translatedSteps = null;
        _translatedPrevention = null;
      });
      return;
    }

    setState(() => _isTranslating = true);

    try {
      // Build all text to translate in one call for efficiency
      final description = _treatment!['description']['en'] ?? '';
      final symptoms = (_treatment!['symptoms'] as List).map((s) => s.toString()).toList();
      final steps = (_treatment!['treatment_steps'] as List).map((s) => s.toString()).toList();
      final prevention = (_treatment!['prevention'] as List).map((s) => s.toString()).toList();

      final allText = [
        'DESCRIPTION: $description',
        'SYMPTOMS: ${symptoms.join(' | ')}',
        'STEPS: ${steps.join(' | ')}',
        'PREVENTION: ${prevention.join(' | ')}',
      ].join('\n\n');

      final translated = await _openRouterService.translate(allText, lang);

      // Parse the translated sections
      final sections = translated.split(RegExp(r'(?:DESCRIPTION|SYMPTOMS|STEPS|PREVENTION)\s*:\s*'));
      if (sections.length >= 4 && mounted) {
        setState(() {
          _translatedDescription = sections[1].trim().split('\n\n').first.trim();
          _translatedSymptoms = sections[2].trim().split('\n\n').first.split(' | ').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
          _translatedSteps = sections[3].trim().split('\n\n').first.split(' | ').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
          _translatedPrevention = sections.length > 4
              ? sections[4].trim().split(' | ').map((s) => s.trim()).where((s) => s.isNotEmpty).toList()
              : prevention;
        });
      }
    } catch (_) {
      // If translation fails, keep showing English
    } finally {
      if (mounted) setState(() => _isTranslating = false);
    }
  }

  Future<void> _playVoice() async {
    setState(() => _isPlayingVoice = true);
    try {
      final url = ApiConfig.treatmentVoice(widget.diseaseName, _selectedLanguage);
      await _audioPlayer.play(UrlSource(url));
      _audioPlayer.onPlayerComplete.listen((_) {
        if (mounted) setState(() => _isPlayingVoice = false);
      });
    } catch (_) {
      if (mounted) setState(() => _isPlayingVoice = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.watch<LanguageProvider>().t('treatment_guide')), backgroundColor: AppTheme.primaryGreen),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _treatment == null
              ? const Center(child: Text('Treatment data not available'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Text(_treatment!['disease_name'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _severityColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('Severity: ${_treatment!['severity']}'.toUpperCase(),
                            style: TextStyle(color: _severityColor, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                      const SizedBox(height: 16),

                      // Language + Voice
                      Row(children: [
                        Expanded(child: _languageDropdown()),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: _isPlayingVoice ? null : _playVoice,
                          icon: Icon(_isPlayingVoice ? Icons.stop : Icons.volume_up),
                          label: Text(context.read<LanguageProvider>().t('listen')),
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen, foregroundColor: Colors.white),
                        ),
                      ]),
                      const SizedBox(height: 16),

                      // Translating indicator
                      if (_isTranslating)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Row(children: [
                            const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryGreen)),
                            const SizedBox(width: 12),
                            Text(context.read<LanguageProvider>().t('translating'), style: const TextStyle(color: Colors.grey)),
                          ]),
                        ),

                      // Description
                      Text(_translatedDescription ?? _treatment!['description'][_selectedLanguage] ?? _treatment!['description']['en'],
                          style: const TextStyle(fontSize: 15, height: 1.5)),
                      const SizedBox(height: 20),

                      // Symptoms
                      if ((_treatment!['symptoms'] as List).isNotEmpty) ...[
                        _sectionTitle(context.read<LanguageProvider>().t('symptoms')),
                        ...(_translatedSymptoms ?? (_treatment!['symptoms'] as List).map((s) => s.toString()).toList())
                            .map((s) => _bulletItem(s, Icons.circle, Colors.red)),
                        const SizedBox(height: 20),
                      ],

                      // Treatment Steps
                      _sectionTitle(context.read<LanguageProvider>().t('treatment_steps')),
                      ...(_translatedSteps ?? (_treatment!['treatment_steps'] as List).map((s) => s.toString()).toList())
                          .asMap().entries.map((e) => _numberedItem(e.key + 1, e.value)),
                      const SizedBox(height: 20),

                      // Prevention
                      _sectionTitle(context.read<LanguageProvider>().t('prevention')),
                      ...(_translatedPrevention ?? (_treatment!['prevention'] as List).map((s) => s.toString()).toList())
                          .map((p) => _bulletItem(p, Icons.shield, AppTheme.primaryGreen)),
                      const SizedBox(height: 20),

                      // Local Products
                      _sectionTitle(context.read<LanguageProvider>().t('recommended_products')),
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: (_treatment!['local_products'] as List).map((p) => Chip(
                          label: Text(p.toString(), style: const TextStyle(fontSize: 12)),
                          backgroundColor: AppTheme.accentGreen.withOpacity(0.3),
                        )).toList(),
                      ),
                    ],
                  ),
                ),
    );
  }

  Color get _severityColor {
    switch (_treatment?['severity']) {
      case 'critical': return Colors.red;
      case 'high': return Colors.orange;
      case 'none': return Colors.green;
      default: return Colors.yellow.shade700;
    }
  }

  Widget _languageDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(border: Border.all(color: AppTheme.primaryGreen), borderRadius: BorderRadius.circular(12)),
      child: DropdownButtonHideUnderline(child: DropdownButton<String>(
        value: _selectedLanguage, isExpanded: true,
        items: LanguageProvider.languages.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
        onChanged: (val) => _onLanguageChanged(val!),
      )),
    );
  }

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.darkGreen)),
  );

  Widget _bulletItem(String text, IconData icon, Color color) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 8, color: color),
      const SizedBox(width: 10),
      Expanded(child: Text(text, style: const TextStyle(fontSize: 14, height: 1.4))),
    ]),
  );

  Widget _numberedItem(int num, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 24, height: 24,
        decoration: BoxDecoration(color: AppTheme.primaryGreen, borderRadius: BorderRadius.circular(12)),
        child: Center(child: Text('$num', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
      ),
      const SizedBox(width: 10),
      Expanded(child: Text(text, style: const TextStyle(fontSize: 14, height: 1.4))),
    ]),
  );
}
