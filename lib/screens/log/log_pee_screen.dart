import 'package:flutter/material.dart';
import '../../config/themes/app_theme.dart';

import '../../widgets/ocean_background.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/primary_button.dart';
import '../../services/pee_log_service.dart';

/// Log Pee Screen - Add a new pee log
class LogPeeScreen extends StatefulWidget {
  final int userId;
  final bool isOldLog;

  const LogPeeScreen({super.key, required this.userId, this.isOldLog = false});

  @override
  State<LogPeeScreen> createState() => _LogPeeScreenState();
}

class _LogPeeScreenState extends State<LogPeeScreen> {
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isLoading = false;

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primaryBlue,
              onPrimary: AppTheme.textPrimary,
              surface: AppTheme.backgroundDark,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primaryBlue,
              onPrimary: AppTheme.textPrimary,
              surface: AppTheme.backgroundDark,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _savePeeLog() async {
    setState(() => _isLoading = true);

    try {
      final timestamp = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      await PeeLogService.instance.addPeeLog(
        userId: widget.userId,
        timestamp: timestamp,
      );

      if (!mounted) return;

      _showLoggedDialog(timestamp);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showLoggedDialog(DateTime timestamp) {
    final hours = timestamp.hour.toString().padLeft(2, '0');
    final minutes = timestamp.minute.toString().padLeft(2, '0');
    final day = timestamp.day.toString().padLeft(2, '0');
    final months = [
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
    final month = months[timestamp.month - 1];
    final year = timestamp.year;

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      barrierDismissible: false,
      builder: (context) => Center(
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
      ),
    );

    // Auto-dismiss after 2 seconds and pop the screen
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pop(); // Close dialog
        Navigator.of(context).pop(true); // Return to home with success
      }
    });
  }

  String get _formattedDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDay = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );

    if (selectedDay == today) {
      return 'Today';
    } else if (selectedDay == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}';
    }
  }

  String get _formattedTime {
    final hour = _selectedTime.hourOfPeriod == 0
        ? 12
        : _selectedTime.hourOfPeriod;
    final minute = _selectedTime.minute.toString().padLeft(2, '0');
    final period = _selectedTime.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return OceanBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              // App bar
              _buildAppBar(),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppTheme.spacingM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: AppTheme.spacingL),

                      // Date/Time selection always shown for manual entry
                      _buildDateTimeSection(),
                      const SizedBox(height: AppTheme.spacingXL),

                      // Summary
                      _buildSummary(),
                      const SizedBox(height: AppTheme.spacingXL),

                      // Save button
                      PrimaryButton(
                        text: 'Save Log',
                        onPressed: _savePeeLog,
                        isLoading: _isLoading,
                        icon: Icons.check,
                      ),
                    ],
                  ),
                ),
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
          Expanded(
            child: Text(
              'Log Past Pee',
              style: AppTheme.headingMedium,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48), // Balance
        ],
      ),
    );
  }

  Widget _buildDateTimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('When did it happen?', style: AppTheme.headingSmall),
        const SizedBox(height: AppTheme.spacingM),
        Row(
          children: [
            Expanded(
              child: GlassContainer(
                onTap: _selectDate,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      color: AppTheme.lightBlue,
                      size: 20,
                    ),
                    const SizedBox(width: AppTheme.spacingS),
                    Text(_formattedDate, style: AppTheme.bodyLarge),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppTheme.spacingM),
            Expanded(
              child: GlassContainer(
                onTap: _selectTime,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.access_time,
                      color: AppTheme.lightBlue,
                      size: 20,
                    ),
                    const SizedBox(width: AppTheme.spacingS),
                    Text(_formattedTime, style: AppTheme.bodyLarge),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummary() {
    return GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Summary', style: AppTheme.headingSmall),
          const SizedBox(height: AppTheme.spacingM),
          _buildSummaryRow('Date', _formattedDate, Icons.calendar_today),
          const SizedBox(height: AppTheme.spacingS),
          _buildSummaryRow('Time', _formattedTime, Icons.access_time),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.textMuted),
        const SizedBox(width: AppTheme.spacingS),
        Text(
          '$label: ',
          style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
        ),
        Text(value, style: AppTheme.bodyMedium),
      ],
    );
  }
}
