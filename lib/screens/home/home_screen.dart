import 'package:flutter/material.dart';
import '../../config/themes/app_theme.dart';
import '../../widgets/ocean_background.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../models/pee_log.dart';
import '../../models/hydration_recommendation.dart';
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
  List<PeeLog> _recentLogs = [];
  HydrationRecommendation? _recommendation;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final logs = await PeeLogService.instance.getRecentLogs(
        widget.userId,
        limit: 5,
      );
      final recommendation = await MLService.instance.getRecommendation(
        widget.userId,
      );

      setState(() {
        _recentLogs = logs;
        _recommendation = recommendation;
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
                builder: (context) => ListScreen(userId: widget.userId),
              ),
            )
            .then((_) => _loadData());
        break;
      case 2:
        Navigator.of(context)
            .push(
              MaterialPageRoute(
                builder: (context) => CalendarScreen(userId: widget.userId),
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
                              const SizedBox(height: AppTheme.spacingL),

                              // Hydration recommendation card
                              _buildRecommendationCard(),
                              const SizedBox(height: AppTheme.spacingL),

                              // Recent logs
                              _buildRecentLogsSection(),
                              const SizedBox(height: AppTheme.spacingL),

                              // Action buttons
                              _buildActionButtons(),
                              const SizedBox(height: 100), // Space for nav bar
                            ],
                          ),
                        ),
                      ),
              ),

              // Bottom navigation
              GlassBottomNavBar(
                currentIndex: _currentNavIndex,
                onTap: _onNavTap,
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              // Logo
              Text('P', style: AppTheme.logoStyle.copyWith(fontSize: 28)),
              Text('²', style: AppTheme.logoStyle.copyWith(fontSize: 14)),
              const SizedBox(width: AppTheme.spacingS),
              const Text('PeePal', style: AppTheme.headingMedium),
            ],
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
        Text(widget.username, style: AppTheme.headingLarge),
      ],
    );
  }

  Widget _buildRecommendationCard() {
    final recommendation = _recommendation ?? HydrationRecommendation.noData();
    final isAlert = recommendation.shouldDrinkWater;

    return GlassContainer(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      backgroundColor: isAlert
          ? AppTheme.warning.withValues(alpha: 0.3)
          : AppTheme.success.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isAlert ? Icons.water_drop : Icons.check_circle,
                color: isAlert ? AppTheme.warning : AppTheme.success,
                size: 28,
              ),
              const SizedBox(width: AppTheme.spacingS),
              Text('Hydration Status', style: AppTheme.headingSmall),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          Text(recommendation.message, style: AppTheme.headingMedium),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            recommendation.explanation,
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
          ),
          if (recommendation.confidence != null) ...[
            const SizedBox(height: AppTheme.spacingS),
            Text(
              'Confidence: ${recommendation.confidence!.toStringAsFixed(0)}%',
              style: AppTheme.caption,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecentLogsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent', style: AppTheme.headingSmall),
        const SizedBox(height: AppTheme.spacingM),
        if (_recentLogs.isEmpty)
          GlassContainer(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingL),
                child: Column(
                  children: [
                    Icon(
                      Icons.water_drop_outlined,
                      size: 48,
                      color: AppTheme.textMuted,
                    ),
                    const SizedBox(height: AppTheme.spacingM),
                    Text(
                      'No logs yet',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          GlassContainer(
            padding: EdgeInsets.zero,
            child: Column(
              children: _recentLogs.asMap().entries.map((entry) {
                final index = entry.key;
                final log = entry.value;
                return Column(
                  children: [
                    _buildLogItem(log),
                    if (index < _recentLogs.length - 1)
                      Divider(color: AppTheme.glassBorder, height: 1),
                  ],
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildLogItem(PeeLog log) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingM,
        vertical: AppTheme.spacingS,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.water_drop, color: AppTheme.lightBlue, size: 20),
              const SizedBox(width: AppTheme.spacingS),
              Text(
                'Today, At ${log.formattedTime}',
                style: AppTheme.bodyMedium,
              ),
            ],
          ),
          // Volume display removed as per new requirements
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: GlassContainer(
            onTap: _logPeeNow,
            backgroundColor: AppTheme.primaryBlue,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add, color: AppTheme.textPrimary),
                const SizedBox(width: AppTheme.spacingXS),
                Text('Log Pee Now', style: AppTheme.buttonText),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spacingM),
        SizedBox(
          width: double.infinity,
          child: GlassContainer(
            onTap: _logOldPee,
            child: Center(
              child: Text('Log Old Pee', style: AppTheme.buttonText),
            ),
          ),
        ),
      ],
    );
  }
}
