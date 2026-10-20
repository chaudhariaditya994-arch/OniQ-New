import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_theme.dart';
import '../services/review_service.dart';

class ReviewsListPage extends StatefulWidget {
  const ReviewsListPage({super.key});

  @override
  State<ReviewsListPage> createState() => _ReviewsListPageState();
}

class _ReviewsListPageState extends State<ReviewsListPage> {
  final _service = ReviewService();
  late Future<List<Map<String, dynamic>>> _future;
  String _email = '';
  String _role = 'Farmer';

  bool get _isAdmin => _role.toLowerCase() == 'admin';

  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _email = prefs.getString('user_email') ?? '';
    final userJson = prefs.getString('user_data');
    if (userJson != null) {
      try {
        final decoded = json.decode(userJson) as Map<String, dynamic>;
        _role = decoded['user_type']?.toString() ?? 'Farmer';
      } catch (_) {}
    }
    if (_isAdmin) {
      return _service.listAllReviews(_role);
    }
    return _service.listMyReviews(_email);
  }

  Future<void> _exportCsv() async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      final result = await _service.downloadExport(_role);
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/${result.filename}');
      await file.writeAsBytes(result.bytes, flush: true);

      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Export saved'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${result.bytes.length ~/ 1024} KB · '
                  '${result.filename}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  'The ZIP contains reviews.csv plus an images/ folder. '
                  'It is saved to the app\'s documents directory:',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 8),
                SelectableText(
                  file.path,
                  style: const TextStyle(
                      fontSize: 12, fontFamily: 'monospace'),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Use a file manager (Files / Solid Explorer / adb pull) '
                  'to retrieve it from this path.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
  }

  Future<void> _confirmDelete(String reviewId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete review?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed != true) return;
    final ok = await _service.deleteReview(
      id: reviewId,
      requesterEmail: _email,
      requesterRole: _role,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Deleted' : 'Delete failed')),
    );
    if (ok) await _refresh();
  }

  Future<void> _editReview(Map<String, dynamic> review) async {
    final commentCtrl =
        TextEditingController(text: review['comment']?.toString() ?? '');
    var label = review['corrected_label']?.toString();
    if (label != null && !kReviewLabelOptions.contains(label)) label = null;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Edit review'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: label,
                  isExpanded: true,
                  decoration: const InputDecoration(
                      labelText: 'Corrected class'),
                  items: kReviewLabelOptions
                      .map((l) => DropdownMenuItem(
                          value: l, child: Text(l.replaceAll('_', ' '))))
                      .toList(),
                  onChanged: (v) => setLocal(() => label = v),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: commentCtrl,
                  maxLines: 3,
                  decoration:
                      const InputDecoration(labelText: 'Comment'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Save')),
          ],
        ),
      ),
    );
    if (saved != true) return;

    final result = await _service.updateReview(
      id: review['id'],
      requesterEmail: _email,
      requesterRole: _role,
      correctedLabel: label,
      comment: commentCtrl.text.trim(),
    );
    if (!mounted) return;
    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved')),
      );
      await _refresh();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: ${result['detail'] ?? 'unknown'}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isAdmin ? 'All Reviews' : 'My Reviews'),
        backgroundColor: AppTheme.primaryGreen,
        actions: [
          if (_isAdmin)
            IconButton(
              tooltip: 'Export reviews (CSV + images as ZIP)',
              icon: _exporting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.file_download_outlined),
              onPressed: _exporting ? null : _exportCsv,
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _future,
          builder: (ctx, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final items = snap.data ?? [];
            if (items.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 200),
                  Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No reviews yet.\nUse the "Review this" button after a scan to add one.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _ReviewTile(
                review: items[i],
                currentEmail: _email,
                currentRole: _role,
                onEdit: () => _editReview(items[i]),
                onDelete: () => _confirmDelete(items[i]['id']),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final Map<String, dynamic> review;
  final String currentEmail;
  final String currentRole;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ReviewTile({
    required this.review,
    required this.currentEmail,
    required this.currentRole,
    required this.onEdit,
    required this.onDelete,
  });

  bool get _canEdit {
    if (review['user_email'] == currentEmail) return true;
    return currentRole.toLowerCase() == 'admin';
  }

  @override
  Widget build(BuildContext context) {
    final orig =
        (review['original_prediction']?.toString() ?? '').replaceAll('_', ' ');
    final corrected =
        (review['corrected_label']?.toString() ?? '').replaceAll('_', ' ');
    final comment = review['comment']?.toString() ?? '';
    final by = review['user_email']?.toString() ?? '';
    final created = review['created_at']?.toString() ?? '';

    return Card(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '$orig → $corrected',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    review['status']?.toString() ?? 'pending',
                    style: TextStyle(
                        fontSize: 11, color: Colors.orange.shade900),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('by $by  ·  ${created.split('T').first}',
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
            if (comment.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(comment, style: const TextStyle(fontSize: 14)),
            ],
            if (_canEdit)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit'),
                  ),
                  TextButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete,
                        size: 18, color: Colors.red),
                    label: const Text('Delete',
                        style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
