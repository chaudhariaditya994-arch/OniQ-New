import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../config/app_theme.dart';
import '../models/storage_model.dart';
import '../services/storage_service.dart';

class StoragePage extends StatefulWidget {
  final String userEmail;
  const StoragePage({super.key, required this.userEmail});

  @override
  State<StoragePage> createState() => _StoragePageState();
}

class _StoragePageState extends State<StoragePage> {
  final _service = StorageService();
  bool _isLoading = true;
  String? _errorMessage;

  List<StorageBatch> _batches = [];
  StorageBatch? _selectedBatch;

  StorageReading? _currentReading;
  StorageRiskAssessment? _currentRisk;
  List<StorageReading> _history = [];
  StorageAdvisory? _advisory;
  bool _isLoadingAdvisory = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final batches = await _service.getBatches(widget.userEmail);
      if (batches.isNotEmpty) {
        _batches = batches;
        _selectedBatch = batches.first;
        await _loadBatchData(_selectedBatch!.id);
      } else {
        // If no batch exists, create a default demo lot automatically
        final demo = await _service.createBatch(
          userEmail: widget.userEmail,
          name: "Nashik Chawl Bay #1",
          structureType: "Traditional Chawl (Naturally Ventilated)",
          variety: "Garwa (Rabi)",
          quantityQuintals: 100.0,
          location: "Nashik, Maharashtra",
          deviceId: "esp32-node-01",
          notes: "Equipped with SHT31, MQ-135, and MQ-136 sensors",
        );
        _batches = [demo];
        _selectedBatch = demo;
        await _loadBatchData(demo.id);
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Could not load storage data: $e";
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadBatchData(String batchId) async {
    try {
      final statusMap = await _service.getCurrentStatus(batchId);
      final history = await _service.getHistory(batchId, limit: 30);

      if (mounted) {
        setState(() {
          _selectedBatch = statusMap['batch'] as StorageBatch;
          _currentReading = statusMap['reading'] as StorageReading;
          _currentRisk = statusMap['risk'] as StorageRiskAssessment;
          _history = history;
        });
      }
    } catch (e) {
      debugPrint("Error loading batch details: $e");
    }
  }

  Future<void> _fetchAIAdvisory() async {
    if (_selectedBatch == null) return;
    setState(() => _isLoadingAdvisory = true);
    try {
      final adv = await _service.getAdvisory(_selectedBatch!.id);
      if (mounted) {
        setState(() => _advisory = adv);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Advisory request failed: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingAdvisory = false);
    }
  }

  void _showAddBatchDialog() {
    final nameCtrl = TextEditingController(text: "Chawl Bay #${_batches.length + 1}");
    final qtyCtrl = TextEditingController(text: "75");
    final deviceCtrl = TextEditingController(text: "esp32-node-0${_batches.length + 1}");
    String structureType = "Traditional Chawl (Naturally Ventilated)";
    String variety = "Garwa (Rabi)";

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: const Text("Register New Storage Lot"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: "Storage Lot / Room Name"),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: structureType,
                  decoration: const InputDecoration(labelText: "Storage Structure"),
                  items: const [
                    DropdownMenuItem(
                      value: "Traditional Chawl (Naturally Ventilated)",
                      child: Text("Traditional Chawl"),
                    ),
                    DropdownMenuItem(
                      value: "Bottom-Ventilated Godown",
                      child: Text("Bottom-Ventilated Godown"),
                    ),
                    DropdownMenuItem(
                      value: "Cold Storage Facility",
                      child: Text("Cold Storage (0-4°C)"),
                    ),
                  ],
                  onChanged: (v) => setDlgState(() => structureType = v!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: variety,
                  decoration: const InputDecoration(labelText: "Onion Variety"),
                  items: const [
                    DropdownMenuItem(value: "Garwa (Rabi)", child: Text("Garwa (Rabi)")),
                    DropdownMenuItem(value: "Rangda (Late Kharif)", child: Text("Rangda (Late Kharif)")),
                    DropdownMenuItem(value: "Pol (Kharif)", child: Text("Pol (Kharif)")),
                    DropdownMenuItem(value: "Nashik Red", child: Text("Nashik Red")),
                  ],
                  onChanged: (v) => setDlgState(() => variety = v!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: qtyCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Quantity (Quintals)"),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: deviceCtrl,
                  decoration: const InputDecoration(labelText: "Assigned Sensor Device ID"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                setState(() => _isLoading = true);
                try {
                  final newB = await _service.createBatch(
                    userEmail: widget.userEmail,
                    name: nameCtrl.text.trim(),
                    structureType: structureType,
                    variety: variety,
                    quantityQuintals: double.tryParse(qtyCtrl.text) ?? 50.0,
                    location: "Nashik, Maharashtra",
                    deviceId: deviceCtrl.text.trim(),
                  );
                  _batches.add(newB);
                  _selectedBatch = newB;
                  await _loadBatchData(newB.id);
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Error creating batch: $e")),
                    );
                  }
                } finally {
                  if (mounted) setState(() => _isLoading = false);
                }
              },
              child: const Text("Create"),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRiskColor(String level) {
    switch (level.toLowerCase()) {
      case 'low':
        return Colors.green.shade600;
      case 'moderate':
        return Colors.amber.shade700;
      case 'high':
        return Colors.orange.shade800;
      case 'critical':
        return Colors.red.shade700;
      default:
        return AppTheme.primaryGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("OniQ Storage Monitor", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: AppTheme.primaryGreen,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Refresh Readings",
            onPressed: _selectedBatch != null
                ? () => _loadBatchData(_selectedBatch!.id)
                : _loadInitialData,
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: "Add Storage Lot",
            onPressed: _showAddBatchDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
          : _errorMessage != null
              ? _buildErrorView()
              : _buildDashboard(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadInitialData,
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
              child: const Text("Retry Connection", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard() {
    return RefreshIndicator(
      onRefresh: () async {
        if (_selectedBatch != null) await _loadBatchData(_selectedBatch!.id);
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Batch Selector Dropdown
            _buildBatchSelector(),
            const SizedBox(height: 16),

            // Deterioration Risk Score Banner
            if (_currentRisk != null) _buildRiskScoreCard(),
            const SizedBox(height: 16),

            // 4-Card Sensor Telemetry Grid
            if (_currentReading != null) _buildSensorsGrid(),
            const SizedBox(height: 20),

            // 24-Hour Telemetry Trend Chart
            _buildHistoryChart(),
            const SizedBox(height: 20),

            // AI Decision Support & Advisory Card
            _buildAdvisorySection(),
          ],
        ),
      ),
    );
  }

  Widget _buildBatchSelector() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.location_on, color: AppTheme.primaryGreen),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _batches.any((b) => b.id == _selectedBatch?.id) ? _selectedBatch?.id : null,
                  isExpanded: true,
                  items: _batches.map((b) {
                    return DropdownMenuItem<String>(
                      value: b.id,
                      child: Text(
                        "${b.name} (${b.variety})",
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                    );
                  }).toList(),
                  onChanged: (id) {
                    if (id != null) {
                      final found = _batches.firstWhere((b) => b.id == id);
                      setState(() => _selectedBatch = found);
                      _loadBatchData(id);
                    }
                  },
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add, color: AppTheme.primaryGreen),
              tooltip: "Add Lot",
              onPressed: _showAddBatchDialog,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskScoreCard() {
    final risk = _currentRisk!;
    final color = _getRiskColor(risk.riskLevel);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield_outlined, color: color, size: 22),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  "Deterioration Risk Index",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "${risk.riskLevel.toUpperCase()} RISK",
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                risk.riskScore.toStringAsFixed(1),
                style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: color, height: 1.0),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 6, left: 4),
                child: Text("/ 100", style: TextStyle(fontSize: 16, color: Colors.grey)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            risk.primaryConcern,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade800, height: 1.3),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorsGrid() {
    final r = _currentReading!;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: "Temperature",
                value: "${r.temperature.toStringAsFixed(1)} °C",
                icon: Icons.thermostat,
                subtitle: r.temperature > 30.5 ? "Warm" : "Optimal (25-30°)",
                color: r.temperature > 32 ? Colors.orange : AppTheme.primaryGreen,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                title: "Humidity",
                value: "${r.humidity.toStringAsFixed(1)} %",
                icon: Icons.water_drop,
                subtitle: r.humidity > 70 ? "Moisture Warning" : "Optimal (65-70%)",
                color: r.humidity > 75 ? Colors.red : (r.humidity > 70 ? Colors.amber.shade800 : Colors.blue),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: "Air Quality (MQ-135)",
                value: r.mq135Raw.toStringAsFixed(0),
                icon: Icons.air,
                subtitle: r.mq135Raw > 1200 ? "Volatile Gas Build-up" : "Good Aeration",
                color: r.mq135Raw > 1200 ? Colors.orange : Colors.teal,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                title: "Rot Gas (MQ-136 H₂S)",
                value: r.mq136Raw.toStringAsFixed(0),
                icon: Icons.biotech,
                subtitle: r.mq136Raw > 600 ? "Rot Detected!" : "Undetected (Safe)",
                color: r.mq136Raw > 600 ? Colors.red.shade700 : AppTheme.darkGreen,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: color.withOpacity(0.12),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildHistoryChart() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                Text("24h Environmental Trends", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, color: AppTheme.primaryGreen, size: 10),
                    SizedBox(width: 4),
                    Text("Temp (°C)", style: TextStyle(fontSize: 11)),
                    SizedBox(width: 8),
                    Icon(Icons.circle, color: Colors.blue, size: 10),
                    SizedBox(width: 4),
                    Text("RH (%)", style: TextStyle(fontSize: 11)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 180,
              child: _history.isEmpty
                  ? const Center(child: Text("Awaiting telemetry history from gateway..."))
                  : LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: true, drawVerticalLine: false),
                        titlesData: const FlTitlesData(
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          // Temperature line (Green)
                          LineChartBarData(
                            spots: _history.asMap().entries.map((e) {
                              return FlSpot(e.key.toDouble(), e.value.temperature);
                            }).toList(),
                            isCurved: true,
                            color: AppTheme.primaryGreen,
                            barWidth: 3,
                            dotData: const FlDotData(show: false),
                          ),
                          // Humidity line (Blue)
                          LineChartBarData(
                            spots: _history.asMap().entries.map((e) {
                              return FlSpot(e.key.toDouble(), e.value.humidity);
                            }).toList(),
                            isCurved: true,
                            color: Colors.blue,
                            barWidth: 3,
                            dotData: const FlDotData(show: false),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvisorySection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.psychology, color: AppTheme.primaryGreen),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    "AI Storage Advisory",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _isLoadingAdvisory
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : TextButton.icon(
                        icon: const Icon(Icons.auto_awesome, size: 16),
                        label: const Text("Generate"),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.primaryGreen,
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                        ),
                        onPressed: _fetchAIAdvisory,
                      ),
              ],
            ),
            const Divider(),
            if (_advisory != null) ...[
              Text(
                _advisory!.advisoryText,
                style: const TextStyle(fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 16),
              const Text(
                "Actionable Recommendations:",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              ..._advisory!.actionChecklist.map((act) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle_outline, size: 18, color: AppTheme.primaryGreen),
                        const SizedBox(width: 8),
                        Expanded(child: Text(act, style: const TextStyle(fontSize: 13))),
                      ],
                    ),
                  )),
            ] else if (_currentRisk != null) ...[
              Text(
                _currentRisk!.primaryConcern,
                style: const TextStyle(fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 14),
              const Text(
                "Immediate Recommended Actions:",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              ..._currentRisk!.recommendations.map((rec) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.arrow_right, size: 20, color: AppTheme.primaryGreen),
                        const SizedBox(width: 4),
                        Expanded(child: Text(rec, style: const TextStyle(fontSize: 13))),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}
