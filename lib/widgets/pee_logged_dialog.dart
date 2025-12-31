import 'package:flutter/material.dart';
import '../config/themes/app_theme.dart';
import 'glass_container.dart';

/// Standardized dialog to show when a pee is successfully logged
class PeeLoggedDialog extends StatelessWidget {
  final DateTime timestamp;

  const PeeLoggedDialog({super.key, required this.timestamp});

  /// Helper to show the dialog
  static Future<void> show(BuildContext context, DateTime timestamp) async {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      barrierDismissible: false,
      builder: (context) => PeeLoggedDialog(timestamp: timestamp),
    );

    // Auto-dismiss after 2 seconds
    await Future.delayed(const Duration(seconds: 2));
    if (context.mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeStr = TimeOfDay.fromDateTime(timestamp).format(context);
    final dateStr =
        '${_month(timestamp.month)} ${timestamp.day}, ${timestamp.year}';

    return Center(
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingXXL,
          vertical: AppTheme.spacingXL,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              decoration: BoxDecoration(
                color: AppTheme.success.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.success.withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.check_rounded,
                color: AppTheme.success,
                size: 40,
              ),
            ),
            const SizedBox(height: AppTheme.spacingL),
            Text(
              'Peee Logged!',
              style: AppTheme.headingMedium.copyWith(
                color: AppTheme.textPrimary,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              'at $timeStr',
              style: AppTheme.headingLarge.copyWith(
                fontSize: 32,
                color: AppTheme.textPrimary,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: AppTheme.spacingXS),
            Text(
              dateStr,
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textSecondary,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _month(int month) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month];
  }
}
