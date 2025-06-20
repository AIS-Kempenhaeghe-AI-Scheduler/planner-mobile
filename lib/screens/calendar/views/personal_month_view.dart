import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../models/schedule.dart';
import '../../../services/schedule_service.dart';
import '../../../services/auth_service.dart';
import '../../../theme/theme_provider.dart';

class PersonalMonthView extends StatefulWidget {
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final Function(DateTime, DateTime?) onDateChanged;
  final VoidCallback? onViewChanged;

  const PersonalMonthView({
    super.key,
    required this.focusedDay,
    required this.selectedDay,
    required this.onDateChanged,
    this.onViewChanged,
  });

  @override
  State<PersonalMonthView> createState() => _PersonalMonthViewState();
}

class _PersonalMonthViewState extends State<PersonalMonthView> {
  MonthlySchedule? _monthlySchedule;
  bool _isLoading = false;
  String? _error;
  final ScheduleService _scheduleService = ScheduleService();

  @override
  void initState() {
    super.initState();
    _initializeService();
    _loadSchedule();
  }

  @override
  void didUpdateWidget(PersonalMonthView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusedDay.month != widget.focusedDay.month ||
        oldWidget.focusedDay.year != widget.focusedDay.year) {
      _loadSchedule();
    }
  }

  void _initializeService() {
    final authService = Provider.of<AuthService>(context, listen: false);
    _scheduleService.setAuthToken(authService.authToken);
  }

  Future<void> _loadSchedule() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final scheduleData = await _scheduleService.getMyMonthlySchedule(
        widget.focusedDay.year,
        widget.focusedDay.month,
      );
      setState(() {
        _monthlySchedule = MonthlySchedule.fromJson(scheduleData);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<ScheduleActivity> _getActivitiesForDay(DateTime day) {
    if (_monthlySchedule == null) return [];

    final dateString = _scheduleService.formatDate(day);
    final dayActivities = _monthlySchedule!.monthSchedule[dateString];
    return dayActivities?.activities ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with month navigation
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Text(
                DateFormat('MMMM yyyy').format(widget.focusedDay),
                style: TextStyle(
                  color: isDarkMode ? Colors.white : ThemeProvider.notionBlack,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(
                  Icons.chevron_left,
                  size: 20,
                  color:
                      isDarkMode ? Colors.white70 : ThemeProvider.notionBlack,
                ),
                onPressed: () {
                  final previousMonth = DateTime(
                    widget.focusedDay.year,
                    widget.focusedDay.month - 1,
                    widget.focusedDay.day,
                  );
                  widget.onDateChanged(previousMonth, widget.selectedDay);
                },
                style: IconButton.styleFrom(
                  minimumSize: const Size(32, 32),
                  padding: EdgeInsets.zero,
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.chevron_right,
                  size: 20,
                  color:
                      isDarkMode ? Colors.white70 : ThemeProvider.notionBlack,
                ),
                onPressed: () {
                  final nextMonth = DateTime(
                    widget.focusedDay.year,
                    widget.focusedDay.month + 1,
                    widget.focusedDay.day,
                  );
                  widget.onDateChanged(nextMonth, widget.selectedDay);
                },
                style: IconButton.styleFrom(
                  minimumSize: const Size(32, 32),
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ),
        Divider(
          height: 1,
          color: isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFE5E5E5),
        ),
        // Calendar content
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadSchedule,
            color: ThemeProvider.notionBlue,
            child: _buildContent(),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: ThemeProvider.notionBlue,
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load schedule',
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!.replaceAll('Exception: ', ''),
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadSchedule,
              style: ElevatedButton.styleFrom(
                backgroundColor: ThemeProvider.notionBlue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return _buildCalendar();
  }

  Widget _buildCalendar() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      child: Column(
        children: [
          TableCalendar<ScheduleActivity>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: widget.focusedDay,
            selectedDayPredicate: (day) {
              return isSameDay(widget.selectedDay, day);
            },
            eventLoader: _getActivitiesForDay,
            startingDayOfWeek: StartingDayOfWeek.monday,
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              weekendTextStyle: TextStyle(
                color: isDarkMode ? Colors.white : ThemeProvider.notionBlack,
              ),
              holidayTextStyle: TextStyle(
                color: isDarkMode ? Colors.white : ThemeProvider.notionBlack,
              ),
              defaultTextStyle: TextStyle(
                color: isDarkMode ? Colors.white : ThemeProvider.notionBlack,
              ),
              selectedDecoration: const BoxDecoration(
                color: ThemeProvider.notionBlue,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: ThemeProvider.notionBlue.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              selectedTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              todayTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              markersMaxCount: 3,
              markerDecoration: const BoxDecoration(
                color: ThemeProvider.notionBlue,
                shape: BoxShape.circle,
              ),
              markerMargin: const EdgeInsets.symmetric(horizontal: 1.0),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: TextStyle(
                color: isDarkMode
                    ? ThemeProvider.notionGray
                    : const Color(0xFF6B7280),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              weekendStyle: TextStyle(
                color: isDarkMode
                    ? ThemeProvider.notionGray
                    : const Color(0xFF6B7280),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              leftChevronVisible: false,
              rightChevronVisible: false,
              titleTextStyle: TextStyle(
                fontSize: 0, // Hide the header since we have our own
              ),
            ),
            onDaySelected: (selectedDay, focusedDay) {
              widget.onDateChanged(focusedDay, selectedDay);
              if (widget.onViewChanged != null) {
                widget.onViewChanged!();
              }
            },
            onPageChanged: (focusedDay) {
              widget.onDateChanged(focusedDay, widget.selectedDay);
            },
          ), // Selected day details
          if (widget.selectedDay != null)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      isDarkMode ? const Color(0xFF2D2D2D) : Colors.grey[200]!,
                ),
              ),
              child: _buildSelectedDayDetails(),
            ),
        ],
      ),
    );
  }

  Widget _buildSelectedDayDetails() {
    if (widget.selectedDay == null) return const SizedBox.shrink();

    final activities = _getActivitiesForDay(widget.selectedDay!);
    final formatter = DateFormat('EEEE, MMMM d, yyyy');
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              formatter.format(widget.selectedDay!),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white : ThemeProvider.notionBlack,
              ),
            ),
            const Spacer(),
            if (activities.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: ThemeProvider.notionBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${activities.length} activities',
                  style: const TextStyle(
                    fontSize: 12,
                    color: ThemeProvider.notionBlue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (activities.isEmpty)
          Text(
            'No activities scheduled for this day',
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
              fontStyle: FontStyle.italic,
            ),
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Scheduled Activities:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDarkMode ? Colors.white : ThemeProvider.notionBlack,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: activities.map((activity) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: ThemeProvider.notionBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: ThemeProvider.notionBlue.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.medical_services,
                          size: 16,
                          color: ThemeProvider.notionBlue,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          activity.activity,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDarkMode
                                ? Colors.white
                                : ThemeProvider.notionBlack,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (activity.time != null) ...[
                          const SizedBox(width: 6),
                          Text(
                            activity.time!,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDarkMode
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
      ],
    );
  }
}
