import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/event_preference.dart';
import '../models/event_category.dart';
import '../models/event.dart';
import '../services/user_preference_manager.dart';
import '../services/schedule_recommendation_service.dart';
import '../theme/theme_provider.dart';

class PreferenceScreen extends StatefulWidget {
  const PreferenceScreen({Key? key}) : super(key: key);

  @override
  State<PreferenceScreen> createState() => _PreferenceScreenState();
}

class _PreferenceScreenState extends State<PreferenceScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize the user preference manager
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserPreferenceManager>(context, listen: false).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final preferenceManager = Provider.of<UserPreferenceManager>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (preferenceManager.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Preferences')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Preferences'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              _showHelpDialog();
            },
          ),
        ],
      ),
      body: preferenceManager.categories.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.category_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No event categories available',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => preferenceManager.initialize(),
                    child: const Text('Reload categories'),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.info_outline,
                                color: ThemeProvider.notionBlue),
                            const SizedBox(width: 8),
                            Text(
                              'How it works',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Set your preferences for each event category to help our AI create optimal schedules for you. Your preferences will be used to suggest event times that align with your preferences.',
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),

                Text(
                  'Event Categories',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),

                ...preferenceManager.categories.map((category) {
                  // Get existing preference if any
                  final preference =
                      preferenceManager.getPreferenceForCategory(category.id);

                  return _buildCategoryPreferenceCard(
                    context,
                    category,
                    preference,
                    isDarkMode,
                  );
                }).toList(),

                const SizedBox(height: 24),
                Text(
                  'Schedule Preferences',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),

                // Global schedule preferences (future enhancement)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.schedule,
                                color: ThemeProvider.notionBlue),
                            const SizedBox(width: 8),
                            Text(
                              'Schedule Generation',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          title: const Text('Generate suggested schedules'),
                          subtitle: const Text(
                              'Let the AI suggest optimal schedules based on your preferences'),
                          trailing:
                              const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            // Navigate to schedule generation screen
                            _showScheduleGenerationDialog();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCategoryPreferenceCard(
    BuildContext context,
    EventCategory category,
    EventPreference? preference,
    bool isDarkMode,
  ) {
    // Default values if no preference exists
    double preferenceScore = preference?.preferenceScore ?? 0.5;
    int preferredHour = preference?.averageHourPreference ?? 9;
    List<int> preferredDays =
        preference?.preferredDaysOfWeek ?? [1, 2, 3, 4, 5];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: category.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  category.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  onPressed: () {
                    _showPreferenceEditDialog(
                      context,
                      category,
                      preference,
                    );
                  },
                ),
              ],
            ),

            if (category.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                category.description,
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                ),
              ),
            ],

            const Divider(height: 24),

            // Preference score
            Row(
              children: [
                const Icon(Icons.thumb_up_alt_outlined, size: 16),
                const SizedBox(width: 8),
                const Text('Preference: '),
                const Spacer(),
                _buildPreferenceIndicator(preferenceScore),
              ],
            ),

            const SizedBox(height: 12),

            // Preferred time
            Row(
              children: [
                const Icon(Icons.access_time, size: 16),
                const SizedBox(width: 8),
                const Text('Preferred time: '),
                const Spacer(),
                Text(_formatHour(preferredHour)),
              ],
            ),

            const SizedBox(height: 12),

            // Preferred days
            Row(
              children: [
                const Icon(Icons.date_range, size: 16),
                const SizedBox(width: 8),
                const Text('Preferred days: '),
                const Spacer(),
                Text(_formatDays(preferredDays)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferenceIndicator(double score) {
    String label;
    Color color;

    if (score < 0.25) {
      label = 'Strongly Dislike';
      color = Colors.red;
    } else if (score < 0.45) {
      label = 'Dislike';
      color = Colors.orange;
    } else if (score < 0.55) {
      label = 'Neutral';
      color = Colors.grey;
    } else if (score < 0.75) {
      label = 'Like';
      color = Colors.lightBlue;
    } else {
      label = 'Strongly Like';
      color = Colors.green;
    }

    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 4),
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }

  String _formatHour(int hour) {
    final is24Hour = MediaQuery.of(context).alwaysUse24HourFormat;

    if (is24Hour) {
      return '$hour:00';
    } else {
      final period = hour < 12 ? 'AM' : 'PM';
      final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      return '$displayHour:00 $period';
    }
  }

  String _formatDays(List<int> days) {
    if (days.length == 7) {
      return 'Every day';
    } else if (days.length == 5 &&
        days.contains(1) &&
        days.contains(2) &&
        days.contains(3) &&
        days.contains(4) &&
        days.contains(5)) {
      return 'Weekdays';
    } else if (days.length == 2 && days.contains(6) && days.contains(7)) {
      return 'Weekends';
    } else {
      final dayNames = days.map((day) {
        switch (day) {
          case 1:
            return 'Mon';
          case 2:
            return 'Tue';
          case 3:
            return 'Wed';
          case 4:
            return 'Thu';
          case 5:
            return 'Fri';
          case 6:
            return 'Sat';
          case 7:
            return 'Sun';
          default:
            return '';
        }
      }).join(', ');

      return dayNames;
    }
  }

  void _showPreferenceEditDialog(
    BuildContext context,
    EventCategory category,
    EventPreference? existingPreference,
  ) {
    // Initial values
    double preferenceScore = existingPreference?.preferenceScore ?? 0.5;
    int preferredHour = existingPreference?.averageHourPreference ?? 9;
    List<int> preferredDays = List<int>.from(
        existingPreference?.preferredDaysOfWeek ?? [1, 2, 3, 4, 5]);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Edit ${category.name} Preferences'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Preference score slider
                  Text(
                    'How much do you prefer this category?',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Text('Dislike'),
                      Expanded(
                        child: Slider(
                          value: preferenceScore,
                          min: 0.0,
                          max: 1.0,
                          divisions: 4,
                          onChanged: (value) {
                            setState(() {
                              preferenceScore = value;
                            });
                          },
                        ),
                      ),
                      const Text('Like'),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Preferred hour picker
                  Text(
                    'Preferred time of day',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    value: preferredHour,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: List.generate(24, (index) {
                      return DropdownMenuItem<int>(
                        value: index,
                        child: Text(_formatHour(index)),
                      );
                    }),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          preferredHour = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Preferred days
                  Text(
                    'Preferred days of week',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildDayToggle('Mon', 1, preferredDays, (selected) {
                        setState(() {
                          if (selected) {
                            preferredDays.add(1);
                          } else {
                            preferredDays.remove(1);
                          }
                        });
                      }),
                      _buildDayToggle('Tue', 2, preferredDays, (selected) {
                        setState(() {
                          if (selected) {
                            preferredDays.add(2);
                          } else {
                            preferredDays.remove(2);
                          }
                        });
                      }),
                      _buildDayToggle('Wed', 3, preferredDays, (selected) {
                        setState(() {
                          if (selected) {
                            preferredDays.add(3);
                          } else {
                            preferredDays.remove(3);
                          }
                        });
                      }),
                      _buildDayToggle('Thu', 4, preferredDays, (selected) {
                        setState(() {
                          if (selected) {
                            preferredDays.add(4);
                          } else {
                            preferredDays.remove(4);
                          }
                        });
                      }),
                      _buildDayToggle('Fri', 5, preferredDays, (selected) {
                        setState(() {
                          if (selected) {
                            preferredDays.add(5);
                          } else {
                            preferredDays.remove(5);
                          }
                        });
                      }),
                      _buildDayToggle('Sat', 6, preferredDays, (selected) {
                        setState(() {
                          if (selected) {
                            preferredDays.add(6);
                          } else {
                            preferredDays.remove(6);
                          }
                        });
                      }),
                      _buildDayToggle('Sun', 7, preferredDays, (selected) {
                        setState(() {
                          if (selected) {
                            preferredDays.add(7);
                          } else {
                            preferredDays.remove(7);
                          }
                        });
                      }),
                    ],
                  ),

                  if (preferredDays.isEmpty) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Please select at least one day',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: preferredDays.isEmpty
                    ? null
                    : () {
                        final newPreference = EventPreference(
                          categoryId: category.id,
                          categoryColor: category.color,
                          categoryName: category.name,
                          preferenceScore: preferenceScore,
                          averageHourPreference: preferredHour,
                          preferredDaysOfWeek: preferredDays,
                        );

                        Provider.of<UserPreferenceManager>(context,
                                listen: false)
                            .updatePreference(newPreference);

                        Navigator.pop(context);
                      },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDayToggle(
    String label,
    int dayValue,
    List<int> selectedDays,
    Function(bool) onChanged,
  ) {
    final isSelected = selectedDays.contains(dayValue);

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onChanged,
      backgroundColor: Colors.grey[200],
      selectedColor: ThemeProvider.notionBlue.withOpacity(0.2),
      checkmarkColor: ThemeProvider.notionBlue,
      labelStyle: TextStyle(
        color: isSelected ? ThemeProvider.notionBlue : Colors.black87,
        fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Preferences'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'How it works',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                'Our AI scheduler uses your preferences to suggest optimal schedules. Here\'s what each setting means:',
              ),
              SizedBox(height: 16),
              Text(
                'Preference Score',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'Indicates how much you enjoy or prefer working on this category of events. The AI will try to allocate more of your preferred event types.',
              ),
              SizedBox(height: 12),
              Text(
                'Preferred Time',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'The time of day when you prefer to handle this type of event. The AI will try to schedule events near your preferred hours.',
              ),
              SizedBox(height: 12),
              Text(
                'Preferred Days',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'The days of the week when you prefer to handle this type of event. The AI will prioritize scheduling on your preferred days.',
              ),
              SizedBox(height: 16),
              Text(
                'The more accurate your preferences, the better the AI can create schedules tailored to your working style!',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _showScheduleGenerationDialog() {
    final preferenceManager =
        Provider.of<UserPreferenceManager>(context, listen: false);
    DateTime startDate = DateTime.now().add(const Duration(days: 1));
    startDate = DateTime(startDate.year, startDate.month,
        startDate.day); // Normalize to midnight
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
            title: const Text('Generate Schedule'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Let our AI generate an optimized schedule based on your preferences',
                  ),
                  const SizedBox(height: 16),

                  // Date range selection
                  Text(
                    'Date Range',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          readOnly: true,
                          initialValue:
                              DateFormat('MM/dd/yyyy').format(startDate),
                          decoration: const InputDecoration(
                            labelText: 'Start Date',
                            suffixIcon: Icon(Icons.calendar_today),
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
                          initialValue:
                              DateFormat('MM/dd/yyyy').format(endDate),
                          decoration: const InputDecoration(
                            labelText: 'End Date',
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: endDate,
                              firstDate: startDate,
                              lastDate:
                                  startDate.add(const Duration(days: 365)),
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
                    'Specify how many of each event type you need in this period:',
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
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
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
    Navigator.pop(context);

    // Show the suggested schedule
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Suggested Schedule'),
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
                    return ListTile(
                      leading: Container(
                        width: 12,
                        height: 12,
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
                : () {
                    // TODO: In a real implementation, this would add the events to the user's calendar
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Schedule applied successfully'),
                      ),
                    );
                  },
            child: const Text('Apply Schedule'),
          ),
        ],
      ),
    );
  }
}
