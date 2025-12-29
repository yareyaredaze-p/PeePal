import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../config/themes/app_theme.dart';
import '../../widgets/ocean_background.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../models/pee_log.dart';
import '../../services/pee_log_service.dart';

/// Calendar Screen - Monthly view with activity highlights
class CalendarScreen extends StatefulWidget {
  final int userId;

  const CalendarScreen({super.key, required this.userId});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Set<DateTime> _activityDates = {};
  Map<DateTime, int> _weeklyData = {};
  List<PeeLog> _selectedDayLogs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final activityDates = await PeeLogService.instance
          .getActivityDatesInMonth(
            widget.userId,
            _focusedDay.year,
            _focusedDay.month,
          );

      final weeklyData = await PeeLogService.instance.getWeeklyFrequency(
        widget.userId,
      );

      List<PeeLog> selectedDayLogs = [];
      if (_selectedDay != null) {
        selectedDayLogs = await PeeLogService.instance.getLogsForDate(
          widget.userId,
          _selectedDay!,
        );
      }

      setState(() {
        _activityDates = activityDates;
        _weeklyData = weeklyData;
        _selectedDayLogs = selectedDayLogs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) async {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });

    final logs = await PeeLogService.instance.getLogsForDate(
      widget.userId,
      selectedDay,
    );

    setState(() {
      _selectedDayLogs = logs;
    });
  }

  void _onPageChanged(DateTime focusedDay) {
    _focusedDay = focusedDay;
    _loadData();
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
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(AppTheme.spacingM),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Calendar
                            _buildCalendar(),
                            const SizedBox(height: AppTheme.spacingL),

                            // Selected day logs
                            _buildSelectedDaySection(),
                            const SizedBox(height: AppTheme.spacingL),

                            // Weekly report
                            _buildWeeklyReport(),
                            const SizedBox(
                              height: 120,
                            ), // Extra space for nav bar
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: GlassBottomNavBar(
          currentIndex: 2,
          onTap: (index) {
            if (index != 2) {
              Navigator.of(context).pop();
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
          Row(
            children: [
              Text('P', style: AppTheme.logoStyle.copyWith(fontSize: 28)),
              Text('²', style: AppTheme.logoStyle.copyWith(fontSize: 14)),
              const SizedBox(width: AppTheme.spacingS),
              const Text('PeePal', style: AppTheme.logoStyle),
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

  Widget _buildCalendar() {
    return GlassContainer(
      padding: const EdgeInsets.all(AppTheme.spacingS),
      child: TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: _onDaySelected,
        onPageChanged: _onPageChanged,
        calendarFormat: CalendarFormat.month,
        startingDayOfWeek: StartingDayOfWeek.sunday,

        calendarStyle: CalendarStyle(
          // Today
          todayDecoration: BoxDecoration(
            color: AppTheme.primaryBlue.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          todayTextStyle: AppTheme.bodyMedium,

          // Selected
          selectedDecoration: const BoxDecoration(
            color: AppTheme.primaryBlue,
            shape: BoxShape.circle,
          ),
          selectedTextStyle: AppTheme.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),

          // Default
          defaultTextStyle: AppTheme.bodyMedium,
          weekendTextStyle: AppTheme.bodyMedium,
          outsideTextStyle: AppTheme.bodyMedium.copyWith(
            color: AppTheme.textMuted,
          ),

          // Markers
          markerDecoration: const BoxDecoration(
            color: AppTheme.lightBlue,
            shape: BoxShape.circle,
          ),
          markersMaxCount: 1,
          markerSize: 6,
          markerMargin: const EdgeInsets.only(top: 2),
        ),

        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: AppTheme.headingSmall,
          leftChevronIcon: const Icon(
            Icons.chevron_left,
            color: AppTheme.textPrimary,
          ),
          rightChevronIcon: const Icon(
            Icons.chevron_right,
            color: AppTheme.textPrimary,
          ),
        ),

        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: AppTheme.caption.copyWith(fontWeight: FontWeight.w600),
          weekendStyle: AppTheme.caption.copyWith(fontWeight: FontWeight.w600),
        ),

        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, date, events) {
            final normalizedDate = DateTime(date.year, date.month, date.day);
            if (_activityDates.contains(normalizedDate)) {
              return Positioned(
                bottom: 4,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppTheme.lightBlue,
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }
            return null;
          },
        ),
      ),
    );
  }

  Widget _buildSelectedDaySection() {
    final dateStr = _selectedDay != null
        ? '${_selectedDay!.day}/${_selectedDay!.month}/${_selectedDay!.year}'
        : 'Select a day';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Activity on $dateStr', style: AppTheme.headingSmall),
        const SizedBox(height: AppTheme.spacingM),
        if (_selectedDayLogs.isEmpty)
          GlassContainer(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingL),
                child: Text(
                  'No logs for this day',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.textMuted,
                  ),
                ),
              ),
            ),
          )
        else
          GlassContainer(
            padding: EdgeInsets.zero,
            child: Column(
              children: _selectedDayLogs.asMap().entries.map((entry) {
                final index = entry.key;
                final log = entry.value;
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(AppTheme.spacingM),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.water_drop,
                                color: AppTheme.lightBlue,
                                size: 20,
                              ),
                              const SizedBox(width: AppTheme.spacingS),
                              Text(
                                'At ${log.formattedTime}',
                                style: AppTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (index < _selectedDayLogs.length - 1)
                      Divider(color: AppTheme.glassBorder, height: 1),
                  ],
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildWeeklyReport() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Weekly Report', style: AppTheme.headingSmall),
        const SizedBox(height: AppTheme.spacingM),
        GlassContainer(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          child: Column(
            children: [
              // Bar chart
              SizedBox(
                height: 120,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: _weeklyData.entries.map((entry) {
                    final date = entry.key;
                    final count = entry.value;
                    final maxCount = _weeklyData.values.isEmpty
                        ? 1
                        : _weeklyData.values.reduce((a, b) => a > b ? a : b);
                    final height = maxCount > 0 ? (count / maxCount) * 80 : 0.0;

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          count.toString(),
                          style: AppTheme.caption.copyWith(
                            color: AppTheme.lightBlue,
                          ),
                        ),
                        const SizedBox(height: 4),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 24,
                          height: height.clamp(4.0, 80.0),
                          decoration: BoxDecoration(
                            color: AppTheme.lightBlue,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _getDayAbbr(date.weekday),
                          style: AppTheme.caption,
                        ),
                      ],
                    );
                  }).toList(),
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
