import 'package:flutter/material.dart';
import '../../config/themes/app_theme.dart';
import '../../widgets/ocean_background.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../services/pee_log_service.dart';
import '../../services/ml_service.dart';
import '../log/log_pee_screen.dart';

import '../list/list_screen.dart';
import '../calendar/calendar_screen.dart';
import '../account/account_screen.dart';

/// Home Screen - Main dashboard with hydration status and quick actions
class HomeScreen extends StatefulWidget {
  final int userId;
  final String username;

  const HomeScreen({super.key, required this.userId, required this.username});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final int _currentNavIndex = 0;
  Map<String, double> _stats = {'sinceLast': 0.0, 'averageInterval': 0.0};
  List<Map<String, dynamic>> _futureRecommendations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final stats = await MLService.instance.getRecentStats(widget.userId);
      final futureRecommendations = await MLService.instance
          .getFutureRecommendations(widget.userId);

      if (!mounted) return;

      setState(() {
        _stats = stats;
        _futureRecommendations = futureRecommendations;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onNavTap(int index) {
    if (index == _currentNavIndex) return;

    switch (index) {
      case 0:
        // Already on home
        break;
      case 1:
        Navigator.of(context)
            .push(
              MaterialPageRoute(
                builder: (context) => ListScreen(
                  userId: widget.userId,
                  username: widget.username,
                ),
              ),
            )
            .then((_) => _loadData());
        break;
      case 2:
        Navigator.of(context)
            .push(
              MaterialPageRoute(
                builder: (context) => CalendarScreen(
                  userId: widget.userId,
                  username: widget.username,
                ),
              ),
            )
            .then((_) => _loadData());
        break;
      case 3:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) =>
                AccountScreen(userId: widget.userId, username: widget.username),
          ),
        );
        break;
    }
  }

  Future<void> _logPeeNow() async {
    setState(() => _isLoading = true);
    try {
      await PeeLogService.instance.addPeeLog(
        userId: widget.userId,
        timestamp: DateTime.now(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Pee logged successfully!'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
          ),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to log pee')));
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _logOldPee() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) =>
            LogPeeScreen(userId: widget.userId, isOldLog: true),
      ),
    );

    if (result == true) {
      if (mounted) {
        _loadData();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return OceanBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        body: SafeArea(
          bottom: false,
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
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        color: AppTheme.primaryBlue,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(AppTheme.spacingM),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Greeting
                              _buildGreeting(),
                              const SizedBox(height: AppTheme.spacingXS),

                              // Recent logs (now includes graph)
                              _buildRecentLogsSection(),
                              const SizedBox(height: AppTheme.spacingL),

                              // Recommended Water Intake
                              _buildRecommendedWaterIntakeSection(),
                              const SizedBox(height: AppTheme.spacingL),
                            ],
                          ),
                        ),
                      ),
              ),

              // Action buttons (Sticky)
              _buildActionButtons(),
              const SizedBox(height: 110), // Space for nav bar
            ],
          ),
        ),
        bottomNavigationBar: GlassBottomNavBar(
          currentIndex: _currentNavIndex,
          onTap: _onNavTap,
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Image.asset(
            'assets/images/PeePal_logo_v.png',
            height: 40,
            fit: BoxFit.contain,
          ),
          IconButton(
            icon: const Icon(
              Icons.notifications_outlined,
              color: AppTheme.textPrimary,
            ),
            onPressed: () {
              // TODO: Notifications
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGreeting() {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Good Morning';
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
    } else {
      greeting = 'Good Evening';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$greeting,',
          style: AppTheme.bodyLarge.copyWith(color: AppTheme.textSecondary),
        ),
        Text(widget.username, style: AppTheme.headingMedium),
        const SizedBox(height: AppTheme.spacingS),
        Text(
          'Stay hydrated! Your recent patterns look consistent. Keep logging your activity to help us provide better insights for your health.',
          style: AppTheme.bodyMedium.copyWith(
            color: AppTheme.textSecondary,
            height: 1.5,
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildRecentLogsSection() {
    final sinceLast = _stats['sinceLast'] ?? 0.0;
    final avgInterval = _stats['averageInterval'] ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Recent', style: AppTheme.headingSmall),
            TextButton(
              onPressed: () => _onNavTap(1),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingXS),
        GlassContainer(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGraphItem(
                label: 'Since Last Pee',
                value: sinceLast,
                displayValue: '${sinceLast.toStringAsFixed(1)} Hours',
                maxValue: 12, // Scale bar up to 12 hours
              ),
              const SizedBox(height: AppTheme.spacingL),
              _buildGraphItem(
                label: 'Average Time between Last 10 pees',
                value: avgInterval,
                displayValue: '${avgInterval.toStringAsFixed(1)} Hours',
                maxValue: 12,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGraphItem({
    required String label,
    required double value,
    required String displayValue,
    required double maxValue,
  }) {
    final percentage = (value / maxValue).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.caption.copyWith(color: AppTheme.textMuted),
        ),
        const SizedBox(height: AppTheme.spacingS),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.glassBorder, width: 1.5),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: percentage,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.lightBlue.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppTheme.spacingM),
            SizedBox(
              width: 70,
              child: Text(
                displayValue,
                style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecommendedWaterIntakeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Recommended Water Intake', style: AppTheme.headingSmall),
        const SizedBox(height: AppTheme.spacingM),
        if (_futureRecommendations.isEmpty)
          const GlassContainer(
            padding: EdgeInsets.all(AppTheme.spacingL),
            child: Center(
              child: Text(
                'Ongoing Training period',
                style: AppTheme.bodyMedium,
              ),
            ),
          )
        else
          GlassContainer(
            padding: EdgeInsets.zero,
            child: Column(
              children: _futureRecommendations.asMap().entries.map((entry) {
                final index = entry.key;
                final rec = entry.value;
                final DateTime time = rec['time'];

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(AppTheme.spacingM),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.lightBlue.withValues(
                                    alpha: 0.2,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.water_drop,
                                  color: AppTheme.lightBlue,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: AppTheme.spacingM),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'At ${TimeOfDay.fromDateTime(time).format(context)}',
                                    style: AppTheme.bodyMedium,
                                  ),
                                  const Text('Today', style: AppTheme.caption),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (index < _futureRecommendations.length - 1)
                      Divider(
                        color: AppTheme.glassBorder.withValues(alpha: 0.5),
                        height: 1,
                        indent: AppTheme.spacingM,
                        endIndent: AppTheme.spacingM,
                      ),
                  ],
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
      child: Row(
        children: [
          Expanded(
            child: GlassContainer(
              onTap: _logOldPee,
              borderRadius: AppTheme.radiusXLarge,
              child: Center(
                child: Text('Log Old Pee', style: AppTheme.buttonText),
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: GlassContainer(
              onTap: _logPeeNow,
              backgroundColor: AppTheme.primaryBlue,
              borderRadius: AppTheme.radiusXLarge,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add, color: AppTheme.textPrimary),
                  const SizedBox(width: AppTheme.spacingXS),
                  Text('Log Pee', style: AppTheme.buttonText),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
