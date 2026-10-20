import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../models/user_model.dart';
import '../providers/language_provider.dart';
import '../services/auth_service.dart';
import '../widgets/onion_dialog.dart';

class TalkToUsPage extends StatefulWidget {
  final UserModel? user;
  final String userEmail;
  const TalkToUsPage({super.key, required this.user, required this.userEmail});

  @override
  State<TalkToUsPage> createState() => _TalkToUsPageState();
}

class _TalkToUsPageState extends State<TalkToUsPage> {
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  final _authService = AuthService();
  bool _isSending = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final lang = context.read<LanguageProvider>();
    final subject = _subjectController.text.trim();
    final message = _messageController.text.trim();

    if (message.isEmpty) {
      OnionDialog.showError(context, title: lang.t('error'), message: lang.t('feedback_message_required'));
      return;
    }

    setState(() => _isSending = true);
    try {
      final result = await _authService.sendFeedback(
        name: widget.user?.name ?? '',
        email: widget.userEmail,
        subject: subject,
        message: message,
      );
      if (!mounted) return;
      if (result['success'] == true) {
        OnionDialog.showSuccess(
          context,
          title: lang.t('feedback_sent_title'),
          message: lang.t('feedback_sent_message'),
          onDismiss: () => Navigator.of(context).pop(),
        );
      } else {
        OnionDialog.showError(
          context,
          title: lang.t('error'),
          message: result['detail']?.toString() ?? lang.t('feedback_send_failed'),
        );
      }
    } catch (_) {
      if (!mounted) return;
      OnionDialog.showError(context, title: lang.t('error'), message: lang.t('feedback_send_failed'));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      appBar: AppBar(
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(lang.t('talk_to_us')),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryGreen, AppTheme.darkGreen],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 28),
                      const SizedBox(width: 10),
                      Text(lang.t('talk_to_us_intro_title'),
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ]),
                    const SizedBox(height: 8),
                    Text(lang.t('talk_to_us_intro_body'),
                        style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _label(lang.t('feedback_from')),
                    const SizedBox(height: 6),
                    _readonlyChip(widget.user?.name ?? '', widget.userEmail),
                    const SizedBox(height: 16),
                    _label(lang.t('feedback_subject_label')),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _subjectController,
                      maxLength: 120,
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: lang.t('feedback_subject_hint'),
                        prefixIcon: const Icon(Icons.subject),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _label(lang.t('feedback_message_label')),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _messageController,
                      maxLines: 6,
                      maxLength: 5000,
                      decoration: InputDecoration(
                        hintText: lang.t('feedback_message_hint'),
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _isSending ? null : _send,
                        icon: _isSending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                              )
                            : const Icon(Icons.send_rounded),
                        label: Text(
                          _isSending ? lang.t('sending') : lang.t('send'),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) =>
      Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87));

  Widget _readonlyChip(String name, String email) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.15),
            child: Text(
              (name.isNotEmpty ? name[0] : email.isNotEmpty ? email[0] : '?').toUpperCase(),
              style: const TextStyle(color: AppTheme.darkGreen, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (name.isNotEmpty)
                  Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                Text(email, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
