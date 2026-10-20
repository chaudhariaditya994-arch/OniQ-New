import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../config/api_config.dart';
import '../providers/language_provider.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  List<dynamic> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final resp = await http.get(Uri.parse(ApiConfig.usersList));
      final data = json.decode(resp.body);
      if (data['success'] == true && mounted) {
        setState(() { _users = data['users'] ?? []; _isLoading = false; });
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleStatus(String email) async {
    try {
      final resp = await http.post(Uri.parse(ApiConfig.toggleUserStatus(email)));
      final data = json.decode(resp.body);
      if (data['success'] == true) {
        _loadUsers();
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    if (_users.isEmpty) {
      return const Center(child: Text('No users found', style: TextStyle(fontSize: 16, color: Colors.grey)));
    }

    final farmers = _users.where((u) => u['user_type'] == 'Farmer').toList();
    final officers = _users.where((u) => u['user_type'] == 'Extension_Officer').toList();

    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Summary cards
          Row(children: [
            _statCard('Total Users', '${_users.length}', Icons.people, Colors.blue),
            const SizedBox(width: 12),
            _statCard('Farmers', '${farmers.length}', Icons.agriculture, Colors.green),
            const SizedBox(width: 12),
            _statCard('Officers', '${officers.length}', Icons.badge, Colors.orange),
          ]),
          const SizedBox(height: 24),

          // User list
          const Text('All Users', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ..._users.map((user) {
            final isActive = user['is_active'] ?? true;
            final userType = (user['user_type'] ?? 'Farmer').toString().replaceAll('_', ' ');
            Color typeColor;
            switch (user['user_type']) {
              case 'Admin': typeColor = Colors.red; break;
              case 'Extension_Officer': typeColor = Colors.orange; break;
              default: typeColor = Colors.green;
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isActive ? typeColor.withOpacity(0.2) : Colors.grey.shade200,
                  child: Icon(Icons.person, color: isActive ? typeColor : Colors.grey),
                ),
                title: Text(user['name'] ?? '', style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isActive ? Colors.black : Colors.grey,
                )),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user['email'] ?? '', style: const TextStyle(fontSize: 12)),
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: typeColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(userType, style: TextStyle(fontSize: 10, color: typeColor, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.circle, size: 8, color: isActive ? Colors.green : Colors.red),
                      const SizedBox(width: 4),
                      Text(isActive ? 'Active' : 'Inactive', style: TextStyle(fontSize: 10, color: isActive ? Colors.green : Colors.red)),
                    ]),
                  ],
                ),
                trailing: user['user_type'] != 'Admin'
                    ? IconButton(
                        icon: Icon(isActive ? Icons.block : Icons.check_circle, color: isActive ? Colors.red : Colors.green),
                        onPressed: () => _toggleStatus(user['email']),
                      )
                    : null,
              ),
            );
          }),
        ],
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

class AdminAnalyticsPage extends StatefulWidget {
  const AdminAnalyticsPage({super.key});

  @override
  State<AdminAnalyticsPage> createState() => _AdminAnalyticsPageState();
}

class _AdminAnalyticsPageState extends State<AdminAnalyticsPage> {
  Map<String, dynamic>? _summary;
  List<dynamic> _recentScans = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        http.get(Uri.parse(ApiConfig.analyticsSummaryAll)),
        http.get(Uri.parse(ApiConfig.analyticsAllScans)),
      ]);

      final summaryData = json.decode(results[0].body);
      final scansData = json.decode(results[1].body);

      if (mounted) {
        setState(() {
          if (summaryData['success'] == true) _summary = summaryData['summary'];
          if (scansData['success'] == true) _recentScans = scansData['events'] ?? [];
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    if (_summary == null) {
      return Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.analytics, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          Text(lang.t('no_analytics_data'), style: const TextStyle(fontSize: 16, color: Colors.grey)),
        ],
      ));
    }

    final total = _summary!['total_scans'] ?? 0;
    final totalUsers = _summary!['total_users'] ?? 0;
    final healthy = _summary!['healthy_count'] ?? 0;
    final diseased = _summary!['disease_count'] ?? 0;
    final distribution = (_summary!['disease_distribution'] as Map?) ?? {};

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(lang.t('platform_analytics'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            Row(children: [
              _statCard(lang.t('users'), '$totalUsers', Icons.people, Colors.blue),
              const SizedBox(width: 8),
              _statCard(lang.t('scans'), '$total', Icons.qr_code_scanner, Colors.purple),
              const SizedBox(width: 8),
              _statCard(lang.t('healthy'), '$healthy', Icons.check_circle, Colors.green),
              const SizedBox(width: 8),
              _statCard(lang.t('diseased'), '$diseased', Icons.warning, Colors.red),
            ]),
            const SizedBox(height: 24),

            if (distribution.isNotEmpty) ...[
              const Text('Disease Distribution', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...distribution.entries.map((e) {
                final count = e.value['count'] ?? 0;
                final pct = total > 0 ? count / total : 0.0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text(e.key.toString().replaceAll('_', ' '), style: const TextStyle(fontWeight: FontWeight.w500)),
                        Text('$count scans', style: const TextStyle(color: Colors.grey)),
                      ]),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: pct.toDouble(),
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation(e.key == 'Healthy' ? Colors.green : Colors.orange),
                        minHeight: 10,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ],
                  ),
                );
              }),
            ],

            if (_recentScans.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text('Recent Scans (All Users)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ..._recentScans.take(20).map((scan) {
                final disease = scan['disease'] ?? 'Unknown';
                final email = scan['email'] ?? '';
                final confidence = (scan['confidence'] ?? 0).toDouble();
                final isHealthy = disease == 'Healthy';

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isHealthy ? Colors.green.shade100 : Colors.red.shade100,
                      child: Icon(isHealthy ? Icons.check_circle : Icons.warning, color: isHealthy ? Colors.green : Colors.red, size: 20),
                    ),
                    title: Text(disease.replaceAll('_', ' '), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text('$email • ${confidence.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 12)),
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
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ]),
      ),
    );
  }
}
