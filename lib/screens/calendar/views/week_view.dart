import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../models/event.dart';
import '../../../services/schedule_service.dart';
import '../../../theme/theme_provider.dart';
import '../../event_form_screen.dart';

class WeekView extends StatelessWidget {
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final Function(DateTime, DateTime?) onDateChanged;
  final VoidCallback? onViewChanged;

  const WeekView({
    super.key,
    required this.focusedDay,
    required this.selectedDay,
    required this.onDateChanged,
    this.onViewChanged,
  });
  @override
  Widget build(BuildContext context) {
    // Get events for each day to show markers
    final scheduleService = Provider.of<ScheduleService>(context);

    // Event loader function for table calendar
    List<dynamic> getEventsForDay(DateTime day) {
      final events = scheduleService.getEventsForDay(day);
      return events;
    }

    return RefreshIndicator(
      onRefresh: () async {
        // Load events for the current week
        final weekStart = scheduleService.getWeekStart(focusedDay);
        await Provider.of<ScheduleService>(context, listen: false)
            .loadEventsForWeek(weekStart);
        // Optional: Show a success message
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Schedule refreshed'),
            duration: Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      color: ThemeProvider.notionBlue,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        child: TableCalendar(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: focusedDay,
          calendarFormat: CalendarFormat.week,
          selectedDayPredicate: (day) {
            return isSameDay(selectedDay, day);
          },
          onDaySelected: (selectedDay, focusedDay) {
            onDateChanged(focusedDay, selectedDay);
            // Switch to day view when a day is selected
            onViewChanged?.call();
          },
          onPageChanged: (focusedDay) {
            onDateChanged(focusedDay, selectedDay);
            // Load events for the week containing the new focused day
            final weekStart = scheduleService.getWeekStart(focusedDay);
            Provider.of<ScheduleService>(context, listen: false)
                .loadEventsForWeek(weekStart);
          },
          // Add event loader to display markers on days with events
          eventLoader: getEventsForDay,
          calendarStyle: CalendarStyle(
            markersMaxCount: 3,
            markerDecoration: const BoxDecoration(
              color: ThemeProvider.notionBlue,
              shape: BoxShape.circle,
            ),
            markerSize: 7.0,
            markersAlignment: Alignment.bottomCenter,
            markerMargin: const EdgeInsets.only(top: 1.0),
            isTodayHighlighted: true,
            todayDecoration: BoxDecoration(
              color: ThemeProvider.notionFaintBlue,
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(3),
            ),
            todayTextStyle: const TextStyle(
              color: ThemeProvider.notionBlack,
              fontWeight: FontWeight.bold,
            ),
            selectedDecoration: BoxDecoration(
              color: ThemeProvider.notionBlue.withOpacity(0.15),
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: ThemeProvider.notionBlue, width: 1),
            ),
            selectedTextStyle: const TextStyle(
              color: ThemeProvider.notionBlue,
              fontWeight: FontWeight.bold,
            ),
            defaultDecoration: BoxDecoration(
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(3),
            ),
            outsideDecoration: BoxDecoration(
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(3),
            ),
            weekendDecoration: BoxDecoration(
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(3),
            ),
            cellMargin: const EdgeInsets.all(4),
            cellPadding: const EdgeInsets.all(4),
          ),
          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
            titleCentered: false,
            leftChevronVisible: false,
            rightChevronVisible: false,
            titleTextStyle: TextStyle(
              fontSize:
                  0, // Hide the title as we're showing it in view selector
            ),
          ),
          daysOfWeekStyle: const DaysOfWeekStyle(
            weekdayStyle: TextStyle(
              color: ThemeProvider.notionGray,
              fontSize: 12,
              fontWeight: FontWeight.normal,
            ),
            weekendStyle: TextStyle(
              color: ThemeProvider.notionGray,
              fontSize: 12,
              fontWeight: FontWeight.normal,
            ),
          ),
          rowHeight: 60,
        ),
      ),
    );
  }
}
