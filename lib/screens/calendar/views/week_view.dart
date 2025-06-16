import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../models/event.dart';
import '../../../services/event_manager.dart';
import '../../../theme/theme_provider.dart';
import '../../event_form_screen.dart';

class WeekView extends StatelessWidget {
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final Function(DateTime, DateTime?) onDateChanged;

  const WeekView({
    super.key,
    required this.focusedDay,
    required this.selectedDay,
    required this.onDateChanged,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        await Provider.of<EventManager>(context, listen: false).loadEvents();
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
          },
          onPageChanged: (focusedDay) {
            onDateChanged(focusedDay, selectedDay);
          },
          calendarStyle: CalendarStyle(
            markersMaxCount: 3,
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
