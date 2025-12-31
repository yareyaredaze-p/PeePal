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
    final hours = timestamp.hour.toString().padLeft(2, '0');
    final minutes = timestamp.minute.toString().padLeft(2, '0');
    final day = timestamp.day.toString().padLeft(2, '0');
    final year = timestamp.year;
    final months = [
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
    final month = months[timestamp.month];

    return Center(
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingXXL,
          vertical: AppTheme.spacingL,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'LOGGED',
              style: AppTheme.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: 2,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              '$hours : $minutes',
              style: AppTheme.headingLarge.copyWith(
                fontSize: 64,
                fontWeight: FontWeight.w300,
                fontStyle: FontStyle.italic,
                letterSpacing: 2,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              '$day $month $year',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.lightBlue,
                fontStyle: FontStyle.italic,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
