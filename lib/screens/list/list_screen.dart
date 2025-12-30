import 'package:flutter/material.dart';
import '../../config/themes/app_theme.dart';
import '../../widgets/notification_popup.dart';
import '../../widgets/ocean_background.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../models/pee_log.dart';
import '../../services/pee_log_service.dart';
import '../home/home_screen.dart';
import '../calendar/calendar_screen.dart';
import '../account/account_screen.dart';
import '../../utils/premium_route.dart';

/// List Screen - Chronological view of all pee logs grouped by date
class ListScreen extends StatefulWidget {
  final int userId;
  final String username;

  const ListScreen({super.key, required this.userId, required this.username});

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  Map<String, List<PeeLog>> _groupedLogs = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);

    try {
      final groupedLogs = await PeeLogService.instance.getLogsGroupedByDate(
        widget.userId,
      );
      setState(() {
        _groupedLogs = groupedLogs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
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
                    : _groupedLogs.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadLogs,
                        color: AppTheme.primaryBlue,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(AppTheme.spacingM),
                          itemCount: _groupedLogs.length,
                          itemBuilder: (context, index) {
                            final dateKey = _groupedLogs.keys.elementAt(index);
                            final logs = _groupedLogs[dateKey]!;
                            return _buildDateGroup(dateKey, logs);
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: GlassBottomNavBar(
          currentIndex: 1,
          onTap: (index) {
            if (index == 1) return;
            switch (index) {
              case 0:
                Navigator.of(context).pushReplacement(
                  PremiumPageRoute(
                    page: HomeScreen(
                      userId: widget.userId,
                      username: widget.username,
                    ),
                  ),
                );
                break;
              case 2:
                Navigator.of(context).pushReplacement(
                  PremiumPageRoute(
                    page: CalendarScreen(
                      userId: widget.userId,
                      username: widget.username,
                    ),
                  ),
                );
                break;
              case 3:
                Navigator.of(context).pushReplacement(
                  PremiumPageRoute(
                    page: AccountScreen(
                      userId: widget.userId,
                      username: widget.username,
                    ),
                  ),
                );
                break;
            }
          },
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
            onPressed: () => NotificationPopup.show(context),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 80, color: AppTheme.textMuted),
          const SizedBox(height: AppTheme.spacingL),
          Text(
            'No logs yet',
            style: AppTheme.headingMedium.copyWith(color: AppTheme.textMuted),
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            'Start tracking your pee to see history',
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildDateGroup(String dateKey, List<PeeLog> logs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date header
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingS),
          child: Text(
            dateKey,
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // Logs for this date
        GlassContainer(
          padding: EdgeInsets.zero,
          margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
          child: Column(
            children: logs.asMap().entries.map((entry) {
              final index = entry.key;
              final log = entry.value;
              return Column(
                children: [
                  _buildLogItem(log),
                  if (index < logs.length - 1)
                    Divider(
                      color: AppTheme.glassBorder,
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

  Widget _buildLogItem(PeeLog log) {
    return RepaintBoundary(
      child: Dismissible(
        key: Key('pee_log_${log.id}'),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: AppTheme.spacingL),
          decoration: BoxDecoration(
            color: AppTheme.error.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          child: const Icon(Icons.delete, color: AppTheme.error),
        ),
        confirmDismiss: (direction) => _confirmDelete(),
        onDismissed: (direction) async {
          await _deleteLog(log);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingM,
            vertical: AppTheme.spacingM,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.lightBlue.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
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
                        'At ${log.formattedTime}',
                        style: AppTheme.bodyMedium,
                      ),
                      Text(_formatDate(log.timestamp), style: AppTheme.caption),
                    ],
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppTheme.lightBlue,
                  size: 20,
                ),
                onPressed: () async {
                  final confirm = await _confirmDelete();
                  if (confirm) {
                    await _deleteLog(log);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmDelete() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppTheme.backgroundDark,
            title: const Text('Delete Log?', style: AppTheme.headingSmall),
            content: const Text(
              'This action cannot be undone.',
              style: AppTheme.bodyMedium,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('Delete', style: TextStyle(color: AppTheme.error)),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _deleteLog(PeeLog log) async {
    await PeeLogService.instance.deleteLog(log.id!, widget.userId);
    _loadLogs();
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final logDate = DateTime(date.year, date.month, date.day);

    if (logDate == today) {
      return 'Today';
    } else if (logDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
