import 'package:flutter/material.dart';
import '../../config/themes/app_theme.dart';
import '../../widgets/ocean_background.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../services/auth_service.dart';
import '../../services/pee_log_service.dart';
import '../../services/ml_service.dart';
import '../auth/login_screen.dart';

/// Account Screen - User profile and settings
class AccountScreen extends StatefulWidget {
  final int userId;
  final String username;

  const AccountScreen({
    super.key,
    required this.userId,
    required this.username,
  });

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  int _totalLogs = 0;
  bool _hasModel = false;
  Map<String, dynamic>? _modelInfo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final totalLogs = await PeeLogService.instance.getTotalCount(
        widget.userId,
      );
      final hasModel = await MLService.instance.hasModel(widget.userId);
      final modelInfo = await MLService.instance.getModelInfo(widget.userId);

      setState(() {
        _totalLogs = totalLogs;
        _hasModel = hasModel;
        _modelInfo = modelInfo;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSignOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.backgroundDark,
        title: const Text('Sign Out?', style: AppTheme.headingSmall),
        content: const Text(
          'Are you sure you want to sign out?',
          style: AppTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Sign Out', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AuthService.instance.logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  Future<void> _retrainModel() async {
    await MLService.instance.retrainModel(widget.userId);
    await _loadData();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Model retrained successfully!'),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
        ),
      );
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
                            // Profile card
                            _buildProfileCard(),
                            const SizedBox(height: AppTheme.spacingL),

                            // Stats
                            _buildStatsSection(),
                            const SizedBox(height: AppTheme.spacingL),

                            // ML Model info
                            _buildMLSection(),
                            const SizedBox(height: AppTheme.spacingL),

                            // Sign out
                            PrimaryButton(
                              text: 'Sign Out',
                              onPressed: _handleSignOut,
                              icon: Icons.logout,
                            ),
                            const SizedBox(height: 100), // Space for nav bar
                          ],
                        ),
                      ),
              ),

              // Bottom navigation
              GlassBottomNavBar(
                currentIndex: 3,
                onTap: (index) {
                  if (index != 3) {
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
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
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return GlassContainer(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Account', style: AppTheme.headingSmall),
          const SizedBox(height: AppTheme.spacingL),
          Row(
            children: [
              // Avatar
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.lightBlue, width: 2),
                ),
                child: Center(
                  child: Text(
                    widget.username[0].toUpperCase(),
                    style: AppTheme.headingLarge.copyWith(
                      color: AppTheme.lightBlue,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),

              // User info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.username, style: AppTheme.headingMedium),
                    Text('Tracking since day 1', style: AppTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Statistics', style: AppTheme.headingSmall),
        const SizedBox(height: AppTheme.spacingM),
        GlassContainer(
          child: Column(
            children: [
              _buildStatRow(
                'Total Logs',
                _totalLogs.toString(),
                Icons.water_drop,
              ),
              Divider(color: AppTheme.glassBorder),
              _buildStatRow(
                'ML Model',
                _hasModel ? 'Trained' : 'Not trained',
                Icons.psychology,
              ),
              if (_modelInfo != null) ...[
                Divider(color: AppTheme.glassBorder),
                _buildStatRow(
                  'Training Data',
                  '${_modelInfo!['trainingSize']} samples',
                  Icons.data_usage,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingS),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.lightBlue, size: 20),
              const SizedBox(width: AppTheme.spacingS),
              Text(label, style: AppTheme.bodyMedium),
            ],
          ),
          Text(
            value,
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildMLSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Machine Learning', style: AppTheme.headingSmall),
        const SizedBox(height: AppTheme.spacingM),
        GlassContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.psychology,
                    color: _hasModel ? AppTheme.success : AppTheme.warning,
                    size: 24,
                  ),
                  const SizedBox(width: AppTheme.spacingS),
                  Text(
                    _hasModel
                        ? 'Decision Tree Model Active'
                        : 'Model Not Trained',
                    style: AppTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingM),
              Text(
                'The ML model uses your pee log data to provide personalized hydration recommendations.',
                style: AppTheme.bodySmall,
              ),
              if (_modelInfo != null) ...[
                const SizedBox(height: AppTheme.spacingM),
                Text(
                  'Model Details (for viva):',
                  style: AppTheme.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingS),
                Text(
                  '• Gap Threshold: ${(_modelInfo!['gapThreshold'] as double).toStringAsFixed(0)} minutes',
                  style: AppTheme.caption,
                ),
                Text(
                  '• Count Threshold: ${_modelInfo!['countThreshold']} logs/day',
                  style: AppTheme.caption,
                ),
                if (_modelInfo!['featureImportance'] != null) ...[
                  const SizedBox(height: AppTheme.spacingS),
                  Text(
                    'Feature Importance:',
                    style: AppTheme.caption.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '• Gap Minutes: ${((_modelInfo!['featureImportance']['gapMinutes'] as double) * 100).toStringAsFixed(1)}%',
                    style: AppTheme.caption,
                  ),
                  Text(
                    '• Hour of Day: ${((_modelInfo!['featureImportance']['hourOfDay'] as double) * 100).toStringAsFixed(1)}%',
                    style: AppTheme.caption,
                  ),
                  Text(
                    '• Daily Count: ${((_modelInfo!['featureImportance']['dailyCount'] as double) * 100).toStringAsFixed(1)}%',
                    style: AppTheme.caption,
                  ),
                ],
              ],
              const SizedBox(height: AppTheme.spacingM),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: _totalLogs > 0 ? _retrainModel : null,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retrain Model'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
