import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/event.dart';
import '../../services/user_preference_manager.dart';
import '../../services/schedule_recommendation_service.dart';
import '../../services/schedule_service.dart';
import '../../theme/theme_provider.dart';
import '../preference_screen.dart';

/// Shows a dialog to generate schedule recommendations
void showScheduleRecommendationDialog(BuildContext context) {
  final preferenceManager =
      Provider.of<UserPreferenceManager>(context, listen: false);

  // Default date range: next 7 days
  DateTime startDate = DateTime.now().add(const Duration(days: 1));
  startDate = DateTime(
      startDate.year, startDate.month, startDate.day); // Normalize to midnight
  DateTime endDate = startDate.add(const Duration(days: 7));

  // Default requirements - one of each category
  final requirements = preferenceManager.categories.map((category) {
    return {
      'categoryId': category.id,
      'count': 1,
    };
  }).toList();

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          title: const Text('AI Schedule Recommendations'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome,
                        color: ThemeProvider.notionBlue, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Let our AI suggest optimal events based on your preferences',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[300]
                              : Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Date range selection
                Text(
                  'Date Range',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        readOnly: true,
                        initialValue:
                            DateFormat('MM/dd/yyyy').format(startDate),
                        decoration: const InputDecoration(
                          labelText: 'Start Date',
                          suffixIcon: Icon(Icons.calendar_today, size: 18),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                        ),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: startDate,
                            firstDate: DateTime.now(),
                            lastDate:
                                DateTime.now().add(const Duration(days: 365)),
                          );

                          if (picked != null && picked != startDate) {
                            setState(() {
                              startDate = picked;
                              if (endDate.isBefore(startDate)) {
                                endDate =
                                    startDate.add(const Duration(days: 7));
                              }
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        readOnly: true,
                        initialValue: DateFormat('MM/dd/yyyy').format(endDate),
                        decoration: const InputDecoration(
                          labelText: 'End Date',
                          suffixIcon: Icon(Icons.calendar_today, size: 18),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                        ),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: endDate,
                            firstDate: startDate,
                            lastDate: startDate.add(const Duration(days: 365)),
                          );

                          if (picked != null && picked != endDate) {
                            setState(() {
                              endDate = picked;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Event requirements
                Text(
                  'Event Requirements',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                const Text(
                  'How many of each event type should be included:',
                  style: TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 12),

                ...preferenceManager.categories.map((category) {
                  final requirement = requirements.firstWhere(
                    (r) => r['categoryId'] == category.id,
                    orElse: () => {'categoryId': category.id, 'count': 0},
                  );

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: category.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(category.name),
                        ),
                        SizedBox(
                          width: 100,
                          child: DropdownButtonFormField<int>(
                            value: requirement['count'] as int,
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            items: List.generate(11, (index) {
                              return DropdownMenuItem<int>(
                                value: index,
                                child: Text('$index'),
                              );
                            }),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  final index = requirements.indexWhere(
                                    (r) => r['categoryId'] == category.id,
                                  );

                                  if (index >= 0) {
                                    requirements[index]['count'] = value;
                                  } else {
                                    requirements.add({
                                      'categoryId': category.id,
                                      'count': value,
                                    });
                                  }
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),

                if (preferenceManager.categories.isEmpty)
                  Center(
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        Icon(Icons.category_outlined,
                            size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        const Text(
                          'No event categories available. Please set up your preferences first.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const PreferenceScreen(),
                              ),
                            );
                          },
                          child: const Text('Set Up Preferences'),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: preferenceManager.categories.isEmpty
                  ? null
                  : () {
                      // Filter out requirements with zero count
                      final validRequirements = requirements
                          .where((r) => (r['count'] as int) > 0)
                          .toList();

                      if (validRequirements.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Please specify at least one event requirement'),
                          ),
                        );
                        return;
                      }

                      // Generate schedule and show results
                      _generateAndShowSchedule(
                        context,
                        startDate,
                        endDate,
                        validRequirements,
                      );

                      Navigator.pop(context);
                    },
              child: const Text('Generate'),
            ),
          ],
        );
      },
    ),
  );
}

void _generateAndShowSchedule(
  BuildContext context,
  DateTime startDate,
  DateTime endDate,
  List<Map<String, dynamic>> requirements,
) async {
  // Get the current user and preference manager
  final preferenceManager =
      Provider.of<UserPreferenceManager>(context, listen: false);
  final user = preferenceManager.currentUser;

  if (user == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('User profile not found')),
    );
    return;
  }

  // Show loading indicator
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const Center(
      child: CircularProgressIndicator(),
    ),
  );

  // Generate the schedule using the recommendation service
  final recommendationService = ScheduleRecommendationService();
  final suggestedEvents = await recommendationService.suggestSchedule(
    user: user,
    requiredEvents: requirements,
    startDate: startDate,
    endDate: endDate,
  );

  // Hide loading indicator
  if (context.mounted) {
    Navigator.pop(context);

    // Show the suggested schedule
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.auto_awesome,
                color: ThemeProvider.notionBlue, size: 20),
            const SizedBox(width: 8),
            const Text('AI Suggested Schedule'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: suggestedEvents.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'No events could be scheduled. Try adjusting your preferences or date range.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: suggestedEvents.length,
                  itemBuilder: (context, index) {
                    final event = suggestedEvents[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: event.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        title: Text(event.title),
                        subtitle: Text(
                          '${DateFormat('EEE, MMM d').format(event.startTime)} at ${DateFormat('h:mm a').format(event.startTime)}',
                        ),
                        dense: true,
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: suggestedEvents.isEmpty
                ? null
                : () async {
                    // Add the suggested events to the calendar
                    final scheduleService =
                        Provider.of<ScheduleService>(context, listen: false);
                    for (final event in suggestedEvents) {
                      await scheduleService.addEvent(event);
                    }

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            '${suggestedEvents.length} events added to your schedule'),
                        backgroundColor: ThemeProvider.notionBlue,
                      ),
                    );
                  },
            child: const Text('Add to Calendar'),
          ),
        ],
      ),
    );
  }
}
