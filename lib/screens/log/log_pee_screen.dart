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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Pee log added successfully!'),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
        ),
      );
      Navigator.of(context).pop(true);
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
    return Scaffold(
      body: OceanBackground(
        child: SafeArea(
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
