import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_theme.dart';
import '../services/review_service.dart';

class ReviewPage extends StatefulWidget {
  final String imagePath;
  final String originalPrediction;
  final double originalConfidence;

  const ReviewPage({
    super.key,
    required this.imagePath,
    required this.originalPrediction,
    required this.originalConfidence,
  });

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  final _service = ReviewService();
  final _commentController = TextEditingController();
  String? _selectedLabel;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _selectedLabel = widget.originalPrediction.isNotEmpty &&
            kReviewLabelOptions.contains(widget.originalPrediction)
        ? widget.originalPrediction
        : null;
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedLabel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please pick the correct class')),
      );
      return;
    }
    if (widget.imagePath.isEmpty || !File(widget.imagePath).existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image is no longer available')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('user_email') ?? '';
      final userJson = prefs.getString('user_data');
      var role = 'Farmer';
      if (userJson != null) {
        try {
          final decoded = json.decode(userJson) as Map<String, dynamic>;
          role = decoded['user_type']?.toString() ?? 'Farmer';
        } catch (_) {}
      }

      final result = await _service.createReview(
        imageFile: File(widget.imagePath),
        userEmail: email,
        userRole: role,
        correctedLabel: _selectedLabel!,
        originalPrediction: widget.originalPrediction,
        originalConfidence: widget.originalConfidence,
        comment: _commentController.text.trim(),
      );

      if (!mounted) return;
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review submitted — thank you!'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
        Navigator.pop(context, true);
      } else {
        final detail = result['detail'] ?? 'Something went wrong';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $detail')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Network error: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review this Scan'),
        backgroundColor: AppTheme.primaryGreen,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.imagePath.isNotEmpty &&
                File(widget.imagePath).existsSync())
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  File(widget.imagePath),
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Model said:',
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.originalPrediction.replaceAll('_', ' ')}'
                    ' — ${widget.originalConfidence.toStringAsFixed(1)}%',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'What is the correct class?',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedLabel,
              isExpanded: true,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
              ),
              hint: const Text('Pick the correct class'),
              items: kReviewLabelOptions
                  .map((l) => DropdownMenuItem(
                        value: l,
                        child: Text(l.replaceAll('_', ' ')),
                      ))
                  .toList(),
              onChanged: _submitting
                  ? null
                  : (v) => setState(() => _selectedLabel = v),
            ),
            const SizedBox(height: 20),

            const Text(
              'Comment (optional)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _commentController,
              maxLines: 4,
              maxLength: 500,
              enabled: !_submitting,
              decoration: InputDecoration(
                hintText: 'Add any context that would help an expert...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send),
                label: Text(_submitting ? 'Submitting...' : 'Submit Review'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
