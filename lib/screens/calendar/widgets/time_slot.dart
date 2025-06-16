import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../models/event.dart';
import '../../../screens/event_form_screen.dart';
import '../../../services/event_manager.dart';
import '../../../theme/theme_provider.dart';
import 'event_badge.dart';

class TimeSlot extends StatelessWidget {
  final DateTime time;
  final bool isCurrentHour;
  final List<Event> eventsAtThisHour;

  const TimeSlot({
    super.key,
    required this.time,
    required this.isCurrentHour,
    required this.eventsAtThisHour,
  });

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('h:mm a');
    final eventManager = Provider.of<EventManager>(context, listen: false);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(
          color: isCurrentHour
              ? ThemeProvider.notionBlue
              : Theme.of(context).dividerTheme.color!,
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(3),
        onTap: () {
          // Navigate to the event form screen with the selected time
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EventFormScreen(initialDate: time),
            ),
          ).then((newEvent) {
            // If a new event was created, add it to the EventManager
            if (newEvent != null) {
              eventManager.addEvent(newEvent);
            }
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Container(
                width: 70,
                alignment: Alignment.center,
                child: Text(
                  timeFormat.format(time),
                  style: TextStyle(
                    color: isCurrentHour
                        ? ThemeProvider.notionBlue
                        : ThemeProvider.notionGray,
                    fontWeight:
                        isCurrentHour ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: eventsAtThisHour.isEmpty
                    ? _buildEmptySlot(context)
                    : _buildEventsList(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptySlot(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 8,
        horizontal: 12,
      ),
      decoration: BoxDecoration(
        color: isCurrentHour
            ? ThemeProvider.notionFaintBlue.withOpacity(0.3)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(
          color: isCurrentHour
              ? ThemeProvider.notionBlue.withOpacity(0.3)
              : Colors.transparent,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.drag_indicator,
            size: 16,
            color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
          ),
          const SizedBox(width: 8),
          const Text(
            'Click to add an event',
            style: TextStyle(
              color: ThemeProvider.notionGray,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsList(BuildContext context) {
    final eventManager = Provider.of<EventManager>(context, listen: false);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: eventsAtThisHour.map((event) {
        return GestureDetector(
          onTap: () {
            // Open the event editing form
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EventFormScreen(
                  event: event,
                ),
              ),
            ).then((updatedEvent) {
              // If the event was updated
              if (updatedEvent != null) {
                eventManager.updateEvent(
                  updatedEvent,
                );
              }
            });
          },
          child: Container(
            margin: const EdgeInsets.only(
              bottom: 4,
            ),
            padding: const EdgeInsets.symmetric(
              vertical: 8,
              horizontal: 12,
            ),
            decoration: BoxDecoration(
              color: event.color.withOpacity(
                isDarkMode ? 0.4 : 0.15,
              ),
              borderRadius: BorderRadius.circular(3),
              border: Border.all(
                color: event.color.withOpacity(
                  0.5,
                ),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: event.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: isDarkMode
                              ? Colors.white
                              : ThemeProvider.notionBlack,
                        ),
                      ),
                      if (event.location.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          event.location,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDarkMode
                                ? ThemeProvider.notionGray
                                : Colors.grey[700],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Text(
                  '${DateFormat('h:mm a').format(event.startTime)} - ${DateFormat('h:mm a').format(event.endTime)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode
                        ? ThemeProvider.notionGray
                        : Colors.grey[700],
                  ),
                ),
                EventBadge(event: event, isDarkMode: isDarkMode),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
