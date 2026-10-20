import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../config/app_theme.dart';
import '../providers/language_provider.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  Map<String, dynamic>? _summary;
  Map<String, dynamic>? _timeseries;
  bool _isLoading = true;
  int _windowDays = 30;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('user_email') ?? '';

    try {
      final results = await Future.wait([
        http.get(Uri.parse(ApiConfig.analyticsSummary(email))).timeout(const Duration(seconds: 3)),
        http.get(Uri.parse(ApiConfig.analyticsTimeseries(email, days: _windowDays))).timeout(const Duration(seconds: 3)),
      ]);
      final summaryData = json.decode(results[0].body);
      final timeseriesData = json.decode(results[1].body);
      if (!mounted) return;
      setState(() {
        if (summaryData['success'] == true) {
          _summary = summaryData['summary'];
          prefs.setString('oniq_analytics_summary', json.encode(_summary));
        }
        if (timeseriesData['success'] == true) {
          _timeseries = timeseriesData;
          prefs.setString('oniq_analytics_timeseries', json.encode(_timeseries));
        }
        _isLoading = false;
      });
      return;
    } catch (_) {
      // Offline fallback: load cached analytics if available
      final cachedSummary = prefs.getString('oniq_analytics_summary');
      final cachedTimeseries = prefs.getString('oniq_analytics_timeseries');
      if (mounted) {
        setState(() {
          if (cachedSummary != null) _summary = json.decode(cachedSummary);
          if (cachedTimeseries != null) _timeseries = json.decode(cachedTimeseries);
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final total = (_summary?['total_scans'] as num?)?.toInt() ?? 0;

    if (total == 0) return _buildEmptyState(lang);

    final healthy = (_summary?['healthy_count'] as num?)?.toInt() ?? 0;
    final diseased = (_summary?['disease_count'] as num?)?.toInt() ?? 0;

    return RefreshIndicator(
      color: AppTheme.primaryGreen,
      onRefresh: _loadAnalytics,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(lang),
            const SizedBox(height: 16),
            _buildStatCards(lang, total, healthy, diseased),
            const SizedBox(height: 20),
            _DailyBarChartCard(
              daily: (_timeseries?['daily'] as List?) ?? const [],
              windowDays: _windowDays,
              onWindowChange: (d) {
                setState(() => _windowDays = d);
                _loadAnalytics();
              },
            ),
            const SizedBox(height: 20),
            _DiseaseDonutCard(distribution: (_summary?['disease_distribution'] as Map?) ?? const {}),
            const SizedBox(height: 20),
            _WeekdayPatternCard(pattern: (_timeseries?['weekday_pattern'] as Map?) ?? const {}),
            const SizedBox(height: 20),
            _RecentActivityCard(recent: (_timeseries?['recent'] as List?) ?? const []),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(LanguageProvider lang) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.insights, color: AppTheme.primaryGreen, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(lang.t('your_farm_analytics'),
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              Text(lang.t('farm_analytics_subtitle'),
                  style: const TextStyle(fontSize: 13, color: Colors.grey)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCards(LanguageProvider lang, int total, int healthy, int diseased) {
    return Row(children: [
      _buildStatCard(lang.t('total_scans'), '$total', Icons.qr_code_scanner_rounded, Colors.blue.shade600),
      const SizedBox(width: 10),
      _buildStatCard(lang.t('healthy'), '$healthy', Icons.eco_rounded, AppTheme.primaryGreen),
      const SizedBox(width: 10),
      _buildStatCard(lang.t('diseased'), '$diseased', Icons.warning_amber_rounded, Colors.orange.shade700),
    ]);
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }

  Widget _buildEmptyState(LanguageProvider lang) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.insights_rounded, size: 64, color: AppTheme.primaryGreen),
            ),
            const SizedBox(height: 24),
            Text(lang.t('no_analytics_data'),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(lang.t('start_scanning_hint'),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.5)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable card scaffold
// ─────────────────────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;
  const _SectionCard({required this.title, this.subtitle, this.trailing, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Daily stacked bar chart (last N days)
// ─────────────────────────────────────────────────────────────────────────────

class _DailyBarChartCard extends StatelessWidget {
  final List daily;
  final int windowDays;
  final ValueChanged<int> onWindowChange;
  const _DailyBarChartCard({required this.daily, required this.windowDays, required this.onWindowChange});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final orange = Colors.orange.shade400;

    final healthySpots = <FlSpot>[];
    final diseasedSpots = <FlSpot>[];
    double seriesMax = 0;
    for (var i = 0; i < daily.length; i++) {
      final d = daily[i];
      final h = ((d['healthy'] as num?) ?? 0).toDouble();
      final s = ((d['diseased'] as num?) ?? 0).toDouble();
      healthySpots.add(FlSpot(i.toDouble(), h));
      diseasedSpots.add(FlSpot(i.toDouble(), s));
      if (h > seriesMax) seriesMax = h;
      if (s > seriesMax) seriesMax = s;
    }
    final maxY = seriesMax == 0 ? 1.0 : (seriesMax * 1.25).ceilToDouble();
    final maxX = (daily.length - 1).clamp(0, double.maxFinite.toInt()).toDouble();

    return _SectionCard(
      title: lang.t('scans_over_time'),
      subtitle: lang.tf('scans_over_time_subtitle', {'days': windowDays}),
      trailing: SegmentedButton<int>(
        showSelectedIcon: false,
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          textStyle: WidgetStateProperty.all(const TextStyle(fontSize: 11)),
        ),
        segments: const [
          ButtonSegment(value: 7, label: Text('7d')),
          ButtonSegment(value: 30, label: Text('30d')),
        ],
        selected: {windowDays},
        onSelectionChanged: (s) => onWindowChange(s.first),
      ),
      child: SizedBox(
        height: 200,
        child: LineChart(
          LineChartData(
            minX: 0,
            maxX: maxX,
            minY: 0,
            maxY: maxY,
            lineTouchData: LineTouchData(
              enabled: true,
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => Colors.black87,
                tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                getTooltipItems: (spots) {
                  if (spots.isEmpty) return [];
                  final idx = spots.first.x.toInt();
                  if (idx < 0 || idx >= daily.length) {
                    return List<LineTooltipItem?>.filled(spots.length, null);
                  }
                  final d = daily[idx];
                  final headline = LineTooltipItem(
                    '${d['date']}\n',
                    const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                    children: [
                      TextSpan(
                        text: lang.tf('chart_tooltip_breakdown', {
                          'healthy': d['healthy'],
                          'diseased': d['diseased'],
                        }),
                        style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.normal),
                      ),
                    ],
                  );
                  return [
                    headline,
                    ...List<LineTooltipItem?>.filled(spots.length - 1, null),
                  ];
                },
              ),
            ),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(),
              rightTitles: const AxisTitles(),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  interval: maxY / 4 == 0 ? 1 : maxY / 4,
                  getTitlesWidget: (val, _) => Text(val.toInt().toString(),
                      style: const TextStyle(fontSize: 10, color: Colors.grey)),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 22,
                  interval: 1,
                  getTitlesWidget: (val, _) {
                    final idx = val.toInt();
                    if (idx < 0 || idx >= daily.length) return const SizedBox();
                    final step = (daily.length / 6).ceil();
                    if (idx % step != 0) return const SizedBox();
                    final dateStr = daily[idx]['date']?.toString() ?? '';
                    final parts = dateStr.split('-');
                    if (parts.length != 3) return const SizedBox();
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text('${parts[1]}/${parts[2]}',
                          style: const TextStyle(fontSize: 9, color: Colors.grey)),
                    );
                  },
                ),
              ),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: maxY / 4 == 0 ? 1 : maxY / 4,
              getDrawingHorizontalLine: (_) =>
                  FlLine(color: Colors.grey.shade200, strokeWidth: 1, dashArray: const [3, 3]),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: healthySpots,
                isCurved: true,
                curveSmoothness: 0.3,
                preventCurveOverShooting: true,
                color: AppTheme.primaryGreen,
                barWidth: 2.5,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: windowDays <= 14,
                  getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                    radius: 3,
                    color: Colors.white,
                    strokeWidth: 2,
                    strokeColor: AppTheme.primaryGreen,
                  ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: AppTheme.primaryGreen.withValues(alpha: 0.12),
                ),
              ),
              LineChartBarData(
                spots: diseasedSpots,
                isCurved: true,
                curveSmoothness: 0.3,
                preventCurveOverShooting: true,
                color: orange,
                barWidth: 2.5,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: windowDays <= 14,
                  getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                    radius: 3,
                    color: Colors.white,
                    strokeWidth: 2,
                    strokeColor: orange,
                  ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: orange.withValues(alpha: 0.12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Disease distribution donut chart
// ─────────────────────────────────────────────────────────────────────────────

class _DiseaseDonutCard extends StatefulWidget {
  final Map distribution;
  const _DiseaseDonutCard({required this.distribution});

  @override
  State<_DiseaseDonutCard> createState() => _DiseaseDonutCardState();
}

class _DiseaseDonutCardState extends State<_DiseaseDonutCard> {
  int _touchedIndex = -1;

  static const _palette = [
    AppTheme.primaryGreen,
    Color(0xFFFF9800),
    Color(0xFFE57373),
    Color(0xFF7E57C2),
    Color(0xFF42A5F5),
    Color(0xFF26A69A),
  ];

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final entries = widget.distribution.entries.toList();
    final total = entries.fold<num>(0, (sum, e) => sum + ((e.value['count'] as num?) ?? 0)).toDouble();
    if (total == 0) {
      return _SectionCard(
        title: lang.t('disease_distribution'),
        child: SizedBox(
          height: 100,
          child: Center(child: Text(lang.t('no_data'), style: TextStyle(color: Colors.grey.shade500))),
        ),
      );
    }

    return _SectionCard(
      title: lang.t('disease_distribution'),
      subtitle: lang.t('disease_distribution_subtitle'),
      child: SizedBox(
        height: 220,
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (event, response) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            response == null ||
                            response.touchedSection == null) {
                          _touchedIndex = -1;
                          return;
                        }
                        _touchedIndex = response.touchedSection!.touchedSectionIndex;
                      });
                    },
                  ),
                  centerSpaceRadius: 42,
                  sectionsSpace: 2,
                  startDegreeOffset: -90,
                  sections: List.generate(entries.length, (i) {
                    final e = entries[i];
                    final count = ((e.value['count'] as num?) ?? 0).toDouble();
                    final pct = (count / total * 100).toStringAsFixed(0);
                    final isTouched = i == _touchedIndex;
                    return PieChartSectionData(
                      color: _palette[i % _palette.length],
                      value: count,
                      title: '$pct%',
                      radius: isTouched ? 62 : 56,
                      titleStyle: TextStyle(
                        fontSize: isTouched ? 13 : 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(entries.length, (i) {
                  final e = entries[i];
                  final name = e.key.toString().replaceAll('_', ' ');
                  final count = ((e.value['count'] as num?) ?? 0).toInt();
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: _palette[i % _palette.length],
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(name,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                        ),
                        Text('$count',
                            style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Weekday pattern bar chart
// ─────────────────────────────────────────────────────────────────────────────

class _WeekdayPatternCard extends StatelessWidget {
  final Map pattern;
  const _WeekdayPatternCard({required this.pattern});

  // Backend keys remain English ('Mon', 'Tue', …); the localized labels for
  // the chart axis and tooltip are looked up via _shortKeys below.
  static const _order = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _shortKeys = [
    'weekday_mon_short',
    'weekday_tue_short',
    'weekday_wed_short',
    'weekday_thu_short',
    'weekday_fri_short',
    'weekday_sat_short',
    'weekday_sun_short',
  ];

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final values = _order.map((d) => ((pattern[d] as num?) ?? 0).toDouble()).toList();
    final maxVal = values.fold<double>(0, (m, v) => v > m ? v : m);
    final maxY = maxVal == 0 ? 1.0 : (maxVal * 1.3).ceilToDouble();

    final busiestIdx = values.indexOf(maxVal);
    final busiestDayLocalized = maxVal > 0 ? lang.t(_shortKeys[busiestIdx]) : null;

    return _SectionCard(
      title: lang.t('weekly_pattern'),
      subtitle: busiestDayLocalized != null
          ? lang.tf('you_scan_most_on', {'day': busiestDayLocalized})
          : lang.t('activity_by_day_of_week'),
      child: SizedBox(
        height: 140,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxY,
            minY: 0,
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => Colors.black87,
                tooltipPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                  '${lang.t(_shortKeys[group.x])}: ${rod.toY.toInt()}',
                  const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(),
              rightTitles: const AxisTitles(),
              leftTitles: const AxisTitles(),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 22,
                  getTitlesWidget: (val, _) {
                    final i = val.toInt();
                    if (i < 0 || i >= _order.length) return const SizedBox();
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(lang.t(_shortKeys[i]),
                          style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
                    );
                  },
                ),
              ),
            ),
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            barGroups: List.generate(7, (i) {
              return BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: values[i],
                    width: 22,
                    color: i == busiestIdx
                        ? AppTheme.primaryGreen
                        : AppTheme.primaryGreen.withValues(alpha: 0.45),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Recent activity list
// ─────────────────────────────────────────────────────────────────────────────

class _RecentActivityCard extends StatelessWidget {
  final List recent;
  const _RecentActivityCard({required this.recent});

  static String _relativeTime(LanguageProvider lang, DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return lang.t('just_now');
    if (diff.inHours < 1) return lang.tf('minutes_ago', {'n': diff.inMinutes});
    if (diff.inDays < 1) return lang.tf('hours_ago', {'n': diff.inHours});
    if (diff.inDays < 7) return lang.tf('days_ago', {'n': diff.inDays});
    return '${dt.month}/${dt.day}/${dt.year % 100}';
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    if (recent.isEmpty) {
      return _SectionCard(
        title: lang.t('recent_scans'),
        child: SizedBox(
          height: 60,
          child: Center(child: Text(lang.t('no_recent_activity'), style: TextStyle(color: Colors.grey.shade500))),
        ),
      );
    }

    return _SectionCard(
      title: lang.t('recent_scans'),
      subtitle: lang.tf(
        recent.length == 1 ? 'recent_scans_subtitle_one' : 'recent_scans_subtitle_many',
        {'count': recent.length},
      ),
      child: Column(
        children: recent.map((scan) {
          final disease = scan['disease']?.toString() ?? 'Unknown';
          final confidence = ((scan['confidence'] as num?) ?? 0).toDouble();
          final ts = DateTime.tryParse(scan['timestamp']?.toString() ?? '');
          final isHealthy = disease == 'Healthy';
          final color = isHealthy ? AppTheme.primaryGreen : Colors.orange.shade700;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isHealthy ? Icons.eco_rounded : Icons.warning_amber_rounded,
                    color: color,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(disease.replaceAll('_', ' '),
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(
                        '${lang.tf('confidence_dot', {'pct': confidence.toStringAsFixed(1)})} · ${_relativeTime(lang, ts)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
