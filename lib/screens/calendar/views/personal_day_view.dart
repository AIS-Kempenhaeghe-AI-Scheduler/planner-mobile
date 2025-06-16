import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../models/schedule.dart';
import '../../../services/schedule_service.dart';
import '../../../services/auth_service.dart';
import '../../../theme/theme_provider.dart';

class PersonalDayView extends StatefulWidget {
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final Function(DateTime, DateTime?) onDateChanged;

  const PersonalDayView({
    super.key,
    required this.focusedDay,
    required this.selectedDay,
    required this.onDateChanged,
  });

  @override
  State<PersonalDayView> createState() => _PersonalDayViewState();
}

class _PersonalDayViewState extends State<PersonalDayView> {
  DaySchedule? _daySchedule;
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
  void didUpdateWidget(PersonalDayView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDay != widget.selectedDay ||
        oldWidget.focusedDay != widget.focusedDay) {
      _loadSchedule();
    }
  }

  void _initializeService() {
    final authService = Provider.of<AuthService>(context, listen: false);
    _scheduleService.setAuthToken(authService.authToken);
  }

  Future<void> _loadSchedule() async {
    final dayToShow = widget.selectedDay ?? widget.focusedDay;
    final dateString = _scheduleService.formatDate(dayToShow);

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final scheduleData =
          await _scheduleService.getMyDailySchedule(dateString);
      setState(() {
        _daySchedule = DaySchedule.fromJson(scheduleData);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dayToShow = widget.selectedDay ?? widget.focusedDay;
    final formatter = DateFormat('EEEE, MMMM d, yyyy');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Text(
                formatter.format(dayToShow),
                style: const TextStyle(
                  color: ThemeProvider.notionBlack,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 20),
                onPressed: () {
                  final previousDay =
                      dayToShow.subtract(const Duration(days: 1));
                  widget.onDateChanged(previousDay, previousDay);
                },
                style: IconButton.styleFrom(
                  minimumSize: const Size(32, 32),
                  padding: EdgeInsets.zero,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, size: 20),
                onPressed: () {
                  final nextDay = dayToShow.add(const Duration(days: 1));
                  widget.onDateChanged(nextDay, nextDay);
                },
                style: IconButton.styleFrom(
                  minimumSize: const Size(32, 32),
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
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
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load schedule',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!.replaceAll('Exception: ', ''),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
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

    if (_daySchedule == null) {
      return const Center(
        child: Text(
          'No schedule data available',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      );
    }

    return _buildTimeSlots();
  }

  Widget _buildTimeSlots() {
    if (_daySchedule!.workingHours.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today,
              size: 48,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No activities scheduled for this day',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      itemCount: _daySchedule!.workingHours.length,
      itemBuilder: (context, index) {
        final timeSlot = _daySchedule!.workingHours[index];
        final isCurrentHour = timeSlot.hour == DateTime.now().hour &&
            widget.selectedDay?.day == DateTime.now().day &&
            widget.selectedDay?.month == DateTime.now().month;

        return Container(
          margin: const EdgeInsets.only(bottom: 8.0),
          decoration: BoxDecoration(
            color: isCurrentHour
                ? ThemeProvider.notionBlue.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8.0),
            border: isCurrentHour
                ? Border.all(color: ThemeProvider.notionBlue.withOpacity(0.3))
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Time label
                SizedBox(
                  width: 60,
                  child: Text(
                    timeSlot.time,
                    style: TextStyle(
                      fontSize: 12,
                      color: isCurrentHour
                          ? ThemeProvider.notionBlue
                          : Colors.grey[600],
                      fontWeight:
                          isCurrentHour ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Activities
                Expanded(
                  child: timeSlot.hasActivities
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: timeSlot.activities.map((activity) {
                            return Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 4.0),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12.0,
                                vertical: 8.0,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    ThemeProvider.notionBlue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6.0),
                                border: Border.all(
                                  color:
                                      ThemeProvider.notionBlue.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                activity.activity,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: ThemeProvider.notionBlack,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                        )
                      : Container(
                          height: 20,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Free time',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[400],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
