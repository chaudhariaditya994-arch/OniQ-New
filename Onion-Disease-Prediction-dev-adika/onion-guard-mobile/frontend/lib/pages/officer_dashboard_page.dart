import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class OfficerScansPage extends StatefulWidget {
  const OfficerScansPage({super.key});

  @override
  State<OfficerScansPage> createState() => _OfficerScansPageState();
}

class _OfficerScansPageState extends State<OfficerScansPage> {
  List<dynamic> _allScans = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadScans();
  }

  Future<void> _loadScans() async {
    try {
      final resp = await http.get(Uri.parse(ApiConfig.analyticsAllScans));
      final data = json.decode(resp.body);
      if (data['success'] == true && mounted) {
        setState(() { _allScans = data['events'] ?? []; _isLoading = false; });
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    if (_allScans.isEmpty) {
      return const Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text('No farmer scans yet', style: TextStyle(fontSize: 16, color: Colors.grey)),
        ],
      ));
    }

    // Group scans by farmer email
    final Map<String, List<dynamic>> farmerScans = {};
    for (final scan in _allScans) {
      final email = scan['email'] ?? 'Unknown';
      farmerScans.putIfAbsent(email, () => []).add(scan);
    }

    return RefreshIndicator(
      onRefresh: _loadScans,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Summary
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Farmer Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('${farmerScans.length} farmers • ${_allScans.length} total scans',
                    style: const TextStyle(fontSize: 14, color: Colors.grey)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Per-farmer breakdown
          ...farmerScans.entries.map((entry) {
            final email = entry.key;
            final scans = entry.value;
            final diseaseCount = scans.where((s) => s['disease'] != 'Healthy').length;
            final healthyCount = scans.length - diseaseCount;

            return ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 8),
              leading: CircleAvatar(
                backgroundColor: diseaseCount > healthyCount ? Colors.red.shade100 : Colors.green.shade100,
                child: Icon(Icons.person, color: diseaseCount > healthyCount ? Colors.red : Colors.green),
              ),
              title: Text(email, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: Text('$healthyCount healthy • $diseaseCount diseased', style: const TextStyle(fontSize: 12)),
              children: scans.map<Widget>((scan) {
                final disease = scan['disease'] ?? 'Unknown';
                final confidence = (scan['confidence'] ?? 0).toDouble();
                final isHealthy = disease == 'Healthy';
                String timeAgo = '';
                try {
                  final dt = DateTime.parse(scan['timestamp'] ?? '');
                  final diff = DateTime.now().toUtc().difference(dt);
                  if (diff.inMinutes < 60) {
                    timeAgo = '${diff.inMinutes}m ago';
                  } else if (diff.inHours < 24) {
                    timeAgo = '${diff.inHours}h ago';
                  } else {
                    timeAgo = '${diff.inDays}d ago';
                  }
                } catch (_) {}

                return ListTile(
                  dense: true,
                  leading: Icon(
                    isHealthy ? Icons.check_circle : Icons.warning,
                    color: isHealthy ? Colors.green : Colors.red,
                    size: 20,
                  ),
                  title: Text(disease.replaceAll('_', ' '), style: const TextStyle(fontSize: 13)),
                  trailing: Text('${confidence.toStringAsFixed(1)}% • $timeAgo', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                );
              }).toList(),
            );
          }),
        ],
      ),
    );
  }
}

class OfficerTrendsPage extends StatefulWidget {
  const OfficerTrendsPage({super.key});

  @override
  State<OfficerTrendsPage> createState() => _OfficerTrendsPageState();
}

class _OfficerTrendsPageState extends State<OfficerTrendsPage> {
  Map<String, dynamic>? _summary;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTrends();
  }

  Future<void> _loadTrends() async {
    try {
      final resp = await http.get(Uri.parse(ApiConfig.analyticsSummaryAll));
      final data = json.decode(resp.body);
      if (data['success'] == true && mounted) {
        setState(() { _summary = data['summary']; _isLoading = false; });
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    if (_summary == null) {
      return const Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.trending_up, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text('No trend data yet', style: TextStyle(fontSize: 16, color: Colors.grey)),
        ],
      ));
    }

    final total = _summary!['total_scans'] ?? 0;
    final totalUsers = _summary!['total_users'] ?? 0;
    final healthy = _summary!['healthy_count'] ?? 0;
    final diseased = _summary!['disease_count'] ?? 0;
    final distribution = (_summary!['disease_distribution'] as Map?) ?? {};

    // Find most common disease
    String topDisease = 'None';
    int topCount = 0;
    distribution.forEach((k, v) {
      if (k != 'Healthy' && (v['count'] ?? 0) > topCount) {
        topDisease = k.toString().replaceAll('_', ' ');
        topCount = v['count'];
      }
    });

    return RefreshIndicator(
      onRefresh: _loadTrends,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Disease Trends', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            // Alert card if disease is dominant
            if (diseased > healthy)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Row(children: [
                  Icon(Icons.warning_amber, color: Colors.red.shade700, size: 36),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Alert: High Disease Rate', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade700)),
                      Text('$topDisease is the most common disease ($topCount cases)',
                          style: TextStyle(fontSize: 13, color: Colors.red.shade600)),
                    ],
                  )),
                ]),
              ),

            Row(children: [
              _statCard('Farmers', '$totalUsers', Icons.people, Colors.blue),
              const SizedBox(width: 12),
              _statCard('Total Scans', '$total', Icons.qr_code_scanner, Colors.purple),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              _statCard('Healthy', '$healthy', Icons.check_circle, Colors.green),
              const SizedBox(width: 12),
              _statCard('Diseased', '$diseased', Icons.warning, Colors.red),
            ]),
            const SizedBox(height: 24),

            if (distribution.isNotEmpty) ...[
              const Text('Disease Breakdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...distribution.entries.map((e) {
                final count = e.value['count'] ?? 0;
                final avgConf = e.value['avg_confidence'] ?? 0;
                final pct = total > 0 ? count / total : 0.0;
                final isHealthy = e.key == 'Healthy';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text(e.key.toString().replaceAll('_', ' '), style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text('$count scans (avg ${avgConf.toStringAsFixed(0)}%)', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ]),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: pct.toDouble(),
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation(isHealthy ? Colors.green : Colors.orange),
                        minHeight: 10,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ]),
      ),
    );
  }
}
