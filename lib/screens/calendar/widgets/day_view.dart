import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../services/schedule_service.dart';
import '../../../theme/theme_provider.dart';
import 'time_slot.dart';

class DayView extends StatelessWidget {
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final Function(DateTime) onDayChanged;

  const DayView({
    super.key,
    required this.focusedDay,
    required this.selectedDay,
    required this.onDayChanged,
  });

  @override
  Widget build(BuildContext context) {
    final dayToShow = selectedDay ?? focusedDay;
    final formatter = DateFormat('EEEE, MMMM d, yyyy');
    final scheduleService = Provider.of<ScheduleService>(context);

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
                  onDayChanged(dayToShow.subtract(const Duration(days: 1)));
                },
                style: IconButton.styleFrom(
                  minimumSize: const Size(32, 32),
                  padding: EdgeInsets.zero,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, size: 20),
                onPressed: () {
                  onDayChanged(dayToShow.add(const Duration(days: 1)));
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
            onRefresh: () async {
              await Provider.of<ScheduleService>(context, listen: false)
                  .loadEvents();
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
            child: _buildTimeSlots(context, dayToShow, scheduleService),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSlots(
      BuildContext context, DateTime day, ScheduleService scheduleService) {
    // Create time slots from 6 AM to 9 PM
    final List<DateTime> timeSlots = [];
    DateTime startTime = DateTime(day.year, day.month, day.day, 6);

    // Get events for the selected day from the ScheduleService
    final eventsForDay = scheduleService.getEventsForDay(day);

    for (int i = 0; i < 16; i++) {
      // 16 hours - 6 AM to 9 PM
      timeSlots.add(startTime.add(Duration(hours: i)));
    }

    return Stack(
      children: [
        // Time slots with events
        ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          itemCount: timeSlots.length,
          itemBuilder: (context, index) {
            final time = timeSlots[index];
            final isCurrentHour = time.hour == DateTime.now().hour &&
                time.day == DateTime.now().day &&
                time.month == DateTime.now().month;

            // Find events that overlap with this time slot
            final eventsAtThisHour = eventsForDay.where((event) {
              // Convert event times to same-day comparison to handle multi-day events
              final timeHour = time.hour;
              final eventStartHour = event.startTime.hour;
              final eventEndHour = event.endTime.hour;

              // Special case for events ending at midnight (0:00)
              final eventEndHourAdjusted =
                  (event.endTime.hour == 0 && event.endTime.minute == 0)
                      ? 24 // Represent midnight as hour 24 for comparison
                      : event.endTime.hour;

              // For same-day events
              if (isSameDay(event.startTime, event.endTime)) {
                // Check if this timeslot falls within the event hours
                return timeHour >= eventStartHour &&
                    timeHour < eventEndHourAdjusted;
              }

              // For multi-day events
              if (isSameDay(time, event.startTime)) {
                // First day of the event - show from start time onwards
                return timeHour >= eventStartHour;
              } else if (isSameDay(time, event.endTime)) {
                // Last day of the event - show until end time
                return timeHour < eventEndHourAdjusted;
              } else if (time.isAfter(event.startTime) &&
                  time.isBefore(event.endTime)) {
                // Middle day of multi-day event - show all hours
                return true;
              }

              return false;
            }).toList();

            return TimeSlot(
              time: time,
              isCurrentHour: isCurrentHour,
              eventsAtThisHour: eventsAtThisHour,
            );
          },
        ), // Loading indicator - placed AFTER (above) the list view
        if (scheduleService.isLoading)
          Container(
            color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.7),
            child: const Center(child: CircularProgressIndicator()),
          ),

        // Error message - placed AFTER (above) the list view
        if (scheduleService.error != null)
          Container(
            color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.9),
            child: Center(
              child: Card(
                margin: const EdgeInsets.all(16),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading events',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        scheduleService.error!,
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => scheduleService.loadEvents(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // Helper to determine if two dates are the same day
  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
