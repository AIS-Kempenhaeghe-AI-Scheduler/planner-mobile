import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../models/schedule.dart';
import '../../../services/schedule_service.dart';
import '../../../services/auth_service.dart';
import '../../../theme/theme_provider.dart';

class PersonalWeekView extends StatefulWidget {
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final Function(DateTime, DateTime?) onDateChanged;

  const PersonalWeekView({
    super.key,
    required this.focusedDay,
    required this.selectedDay,
    required this.onDateChanged,
  });

  @override
  State<PersonalWeekView> createState() => _PersonalWeekViewState();
}

class _PersonalWeekViewState extends State<PersonalWeekView> {
  WeeklySchedule? _weeklySchedule;
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
  void didUpdateWidget(PersonalWeekView oldWidget) {
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
    final weekStart = _scheduleService.getWeekStart(dayToShow);
    final startDateString = _scheduleService.formatDate(weekStart);

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final scheduleData =
          await _scheduleService.getMyWeeklySchedule(startDateString);
      setState(() {
        _weeklySchedule = WeeklySchedule.fromJson(scheduleData);
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
    final weekStart = _scheduleService.getWeekStart(dayToShow);
    final weekEnd = weekStart.add(const Duration(days: 6));
    final formatter = DateFormat('MMM d');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Text(
                '${formatter.format(weekStart)} - ${formatter.format(weekEnd)}',
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
                  final previousWeek =
                      weekStart.subtract(const Duration(days: 7));
                  widget.onDateChanged(previousWeek, previousWeek);
                },
                style: IconButton.styleFrom(
                  minimumSize: const Size(32, 32),
                  padding: EdgeInsets.zero,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, size: 20),
                onPressed: () {
                  final nextWeek = weekStart.add(const Duration(days: 7));
                  widget.onDateChanged(nextWeek, nextWeek);
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

    if (_weeklySchedule == null) {
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

    return _buildWeekGrid();
  }

  Widget _buildWeekGrid() {
    final dayToShow = widget.selectedDay ?? widget.focusedDay;
    final weekStart = _scheduleService.getWeekStart(dayToShow);

    // Generate all days of the week
    final weekDays =
        List.generate(7, (index) => weekStart.add(Duration(days: index)));

    return Column(
      children: [
        // Week header
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: weekDays.map((day) {
              final isToday = day.day == DateTime.now().day &&
                  day.month == DateTime.now().month &&
                  day.year == DateTime.now().year;
              final isSelected = widget.selectedDay != null &&
                  day.day == widget.selectedDay!.day &&
                  day.month == widget.selectedDay!.month &&
                  day.year == widget.selectedDay!.year;

              return Expanded(
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? ThemeProvider.notionBlue
                        : isToday
                            ? ThemeProvider.notionBlue.withOpacity(0.1)
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('E').format(day),
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected
                              ? Colors.white
                              : isToday
                                  ? ThemeProvider.notionBlue
                                  : Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        day.day.toString(),
                        style: TextStyle(
                          fontSize: 16,
                          color: isSelected
                              ? Colors.white
                              : isToday
                                  ? ThemeProvider.notionBlue
                                  : ThemeProvider.notionBlack,
                          fontWeight: isSelected || isToday
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const Divider(height: 1),
        // Week content
        Expanded(
          child: _weeklySchedule!.weekSchedule.isEmpty
              ? const Center(
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
                        'No activities scheduled for this week',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: weekDays.length,
                  itemBuilder: (context, index) {
                    final day = weekDays[index];
                    final dateString = _scheduleService.formatDate(day);
                    final dayActivities =
                        _weeklySchedule!.weekSchedule[dateString];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      elevation: 2,
                      child: InkWell(
                        onTap: () {
                          widget.onDateChanged(day, day);
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    DateFormat('EEEE, MMM d').format(day),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: ThemeProvider.notionBlack,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (dayActivities != null &&
                                      dayActivities.hasActivities)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: ThemeProvider.notionBlue
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${dayActivities.activities.length} activities',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: ThemeProvider.notionBlue,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (dayActivities != null &&
                                  dayActivities.hasActivities)
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  children:
                                      dayActivities.activities.map((activity) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: ThemeProvider.notionBlue
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: ThemeProvider.notionBlue
                                              .withOpacity(0.3),
                                        ),
                                      ),
                                      child: Text(
                                        activity.activity,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: ThemeProvider.notionBlack,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                )
                              else
                                Text(
                                  'No activities scheduled',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
