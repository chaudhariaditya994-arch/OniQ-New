import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../config/app_theme.dart';

class ServerConfigDialog extends StatefulWidget {
  const ServerConfigDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (_) => const ServerConfigDialog(),
    );
  }

  @override
  State<ServerConfigDialog> createState() => _ServerConfigDialogState();
}

class _ServerConfigDialogState extends State<ServerConfigDialog> {
  late final TextEditingController _controller;
  bool _isTesting = false;
  String? _testResult;
  bool _testSuccess = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: ApiConfig.baseUrl);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    final url = _controller.text.trim();
    if (url.isEmpty) return;

    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    try {
      var target = url;
      if (!target.startsWith('http://') && !target.startsWith('https://')) {
        target = 'http://$target';
      }
      if (target.endsWith('/')) {
        target = target.substring(0, target.length - 1);
      }

      final resp = await http.get(Uri.parse('$target/health')).timeout(const Duration(seconds: 3));
      if (resp.statusCode == 200) {
        setState(() {
          _testSuccess = true;
          _testResult = 'Connected successfully! (HTTP 200)';
        });
      } else {
        setState(() {
          _testSuccess = false;
          _testResult = 'Server responded with error ${resp.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _testSuccess = false;
        _testResult = 'Could not reach server: $e';
      });
    } finally {
      if (mounted) setState(() => _isTesting = false);
    }
  }

  Future<void> _saveAndApply() async {
    final url = _controller.text.trim();
    if (url.isNotEmpty) {
      await ApiConfig.setBaseUrl(url);
    }
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Server URL set to: ${ApiConfig.baseUrl}'),
          backgroundColor: AppTheme.primaryGreen,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.dns_rounded, color: AppTheme.primaryGreen),
          SizedBox(width: 10),
          Text('Server Configuration', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the backend server URL or IP address (e.g., your PC Wi-Fi IP or public cloud domain):',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Server Base URL',
                hintText: 'http://192.168.1.5:8000',
                prefixIcon: const Icon(Icons.link),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _isTesting ? null : _testConnection,
                  icon: _isTesting
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.network_check, size: 16),
                  label: const Text('Test', style: TextStyle(fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    _controller.text = ApiConfig.defaultUrl;
                  },
                  child: const Text('Reset', style: TextStyle(fontSize: 13)),
                ),
              ],
            ),
            if (_testResult != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _testSuccess ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _testSuccess ? Colors.green.shade300 : Colors.red.shade300),
                ),
                child: Text(
                  _testResult!,
                  style: TextStyle(
                    fontSize: 12,
                    color: _testSuccess ? Colors.green.shade800 : Colors.red.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveAndApply,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryGreen,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Save & Apply'),
        ),
      ],
    );
  }
}
