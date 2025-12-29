import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../config/themes/app_theme.dart';
import '../../widgets/ocean_background.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../services/pee_log_service.dart';

/// Analytics Screen - Weekly stats and trends
class AnalyticsScreen extends StatefulWidget {
  final int userId;

  const AnalyticsScreen({super.key, required this.userId});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  Map<DateTime, int> _weeklyData = {};
  int _totalLogs = 0;
  int _todayCount = 0;
  double _averageDaily = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final weeklyData = await PeeLogService.instance.getWeeklyFrequency(
        widget.userId,
      );
      final totalLogs = await PeeLogService.instance.getTotalCount(
        widget.userId,
      );
      final todayCount = await PeeLogService.instance.getTodayCount(
        widget.userId,
      );

      double avgDaily = 0;
      if (weeklyData.isNotEmpty) {
        avgDaily =
            weeklyData.values.reduce((a, b) => a + b) / weeklyData.length;
      }

      setState(() {
        _weeklyData = weeklyData;
        _totalLogs = totalLogs;
        _todayCount = todayCount;
        _averageDaily = avgDaily;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: OceanBackground(
        child: SafeArea(
          child: Column(
            children: [
              // App bar
              _buildAppBar(),

              // Content
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.textPrimary,
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(AppTheme.spacingM),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Stats cards
                            _buildStatsRow(),
                            const SizedBox(height: AppTheme.spacingL),

                            // Weekly frequency chart
                            _buildWeeklyChart(),
                            const SizedBox(height: AppTheme.spacingL),

                            // Hydration trend
                            _buildTrendSection(),
                            const SizedBox(height: 100), // Space for nav bar
                          ],
                        ),
                      ),
              ),

              // Bottom navigation
              GlassBottomNavBar(
                currentIndex: 2,
                onTap: (index) {
                  if (index != 2) {
                    Navigator.of(context).pop();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: AppTheme.textPrimary),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const Expanded(
            child: Text(
              'Analytics',
              style: AppTheme.headingMedium,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Today',
            _todayCount.toString(),
            'logs',
            Icons.today,
          ),
        ),
        const SizedBox(width: AppTheme.spacingM),
        Expanded(
          child: _buildStatCard(
            'Average',
            _averageDaily.toStringAsFixed(1),
            'per day',
            Icons.trending_up,
          ),
        ),
        const SizedBox(width: AppTheme.spacingM),
        Expanded(
          child: _buildStatCard(
            'Total',
            _totalLogs.toString(),
            'logs',
            Icons.all_inclusive,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
  ) {
    return GlassContainer(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.lightBlue, size: 24),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            value,
            style: AppTheme.headingMedium.copyWith(color: AppTheme.aqua),
          ),
          Text(subtitle, style: AppTheme.caption),
          const SizedBox(height: AppTheme.spacingXS),
          Text(
            title,
            style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Weekly Frequency', style: AppTheme.headingSmall),
        const SizedBox(height: AppTheme.spacingM),
        GlassContainer(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          child: SizedBox(
            height: 200,
            child: _weeklyData.isEmpty
                ? Center(
                    child: Text(
                      'No data available',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.textMuted,
                      ),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 2,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: AppTheme.glassBorder,
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            interval: 2,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toInt().toString(),
                                style: AppTheme.caption,
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index >= 0 && index < _weeklyData.length) {
                                final date = _weeklyData.keys.elementAt(index);
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    _getDayAbbr(date.weekday),
                                    style: AppTheme.caption,
                                  ),
                                );
                              }
                              return const SizedBox();
                            },
                          ),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: _weeklyData.entries
                              .toList()
                              .asMap()
                              .entries
                              .map(
                                (e) => FlSpot(
                                  e.key.toDouble(),
                                  e.value.value.toDouble(),
                                ),
                              )
                              .toList(),
                          isCurved: true,
                          color: AppTheme.lightBlue,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, bar, index) {
                              return FlDotCirclePainter(
                                radius: 4,
                                color: AppTheme.aqua,
                                strokeWidth: 2,
                                strokeColor: AppTheme.lightBlue,
                              );
                            },
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            color: AppTheme.lightBlue.withValues(alpha: 0.2),
                          ),
                        ),
                      ],
                      minY: 0,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrendSection() {
    final trend = _averageDaily >= 6
        ? 'healthy'
        : _averageDaily >= 4
        ? 'moderate'
        : 'low';

    final trendColor = trend == 'healthy'
        ? AppTheme.success
        : trend == 'moderate'
        ? AppTheme.warning
        : AppTheme.error;

    final trendMessage = trend == 'healthy'
        ? 'Great! Your hydration pattern looks healthy.'
        : trend == 'moderate'
        ? 'You could improve your hydration.'
        : 'Consider drinking more water!';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Hydration Trend', style: AppTheme.headingSmall),
        const SizedBox(height: AppTheme.spacingM),
        GlassContainer(
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: trendColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  trend == 'healthy'
                      ? Icons.check_circle
                      : trend == 'moderate'
                      ? Icons.info
                      : Icons.warning,
                  color: trendColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${trend[0].toUpperCase()}${trend.substring(1)} Hydration',
                      style: AppTheme.headingSmall.copyWith(color: trendColor),
                    ),
                    const SizedBox(height: 4),
                    Text(trendMessage, style: AppTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getDayAbbr(int weekday) {
    const days = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday];
  }
}
