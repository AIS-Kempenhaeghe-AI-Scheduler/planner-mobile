import 'dart:math';
import '../models/user.dart';
import '../models/event.dart';
import 'neural_network_service.dart';

/// Service to provide AI-based schedule recommendations
class ScheduleRecommendationService {
  final NeuralNetworkService _neuralNetworkService = NeuralNetworkService();
  bool _isInitialized = false;

  /// Initialize the neural network
  Future<void> initializeNetwork() async {
    try {
      _isInitialized = await _neuralNetworkService.initialize();
      if (!_isInitialized) {
        print(
            'Warning: Neural network service initialization failed. Falling back to basic recommendations.');
      }
    } catch (e) {
      print('Error initializing neural network: $e');
      _isInitialized = false;
    }
  }

  /// Update neural network weights with feedback
  Future<void> updateNetworkWeights(Map<String, double> scoreData) async {
    if (_isInitialized) {
      await _neuralNetworkService.updateNetworkWeights(scoreData);
    } else {
      print('Warning: Neural network not initialized, weights not updated');
    }
  }

  /// Suggest schedule based on user preferences
  Future<List<Event>> suggestSchedule({
    required User user,
    required List<Map<String, dynamic>> requiredEvents,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (_isInitialized) {
      // Use the external neural network service for recommendations
      return await _neuralNetworkSuggestSchedule(
        user: user,
        requiredEvents: requiredEvents,
        startDate: startDate,
        endDate: endDate,
      );
    } else {
      // Fall back to basic recommendations if network not available
      return _fallbackSuggestSchedule(
        user: user,
        requiredEvents: requiredEvents,
        startDate: startDate,
        endDate: endDate,
      );
    }
  }

  /// Get schedule suggestions from the neural network
  Future<List<Event>> _neuralNetworkSuggestSchedule({
    required User user,
    required List<Map<String, dynamic>> requiredEvents,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final recommendations = await _neuralNetworkService.suggestSchedule(
        user: user,
        requiredEvents: requiredEvents,
        startDate: startDate,
        endDate: endDate,
      );

      if (recommendations.isNotEmpty) {
        return recommendations;
      } else {
        print(
            'Neural network returned no recommendations, falling back to basic algorithm');
        return _fallbackSuggestSchedule(
          user: user,
          requiredEvents: requiredEvents,
          startDate: startDate,
          endDate: endDate,
        );
      }
    } catch (e) {
      print('Error getting neural network recommendations: $e');
      return _fallbackSuggestSchedule(
        user: user,
        requiredEvents: requiredEvents,
        startDate: startDate,
        endDate: endDate,
      );
    }
  }

  /// Fallback scheduling algorithm for when neural network is unavailable
  List<Event> _fallbackSuggestSchedule({
    required User user,
    required List<Map<String, dynamic>> requiredEvents,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final events = <Event>[];
    final random = Random();

    // Get working days between start and end date
    final workingDays = _getWorkingDays(startDate, endDate);
    if (workingDays.isEmpty) return [];

    // Create events for each required category
    for (final requirement in requiredEvents) {
      final categoryId = requirement['categoryId'] as String;
      final count = requirement['count'] as int;

      // Find user preference for this category
      final preference = user.preferences.firstWhere(
        (p) => p.categoryId == categoryId,
        orElse: () => user.preferences.first,
      );

      // Create 'count' number of events for this category
      for (int i = 0; i < count; i++) {
        // Select a random working day
        final selectedDay = workingDays[random.nextInt(workingDays.length)];

        // Create a time based on the preferred time in preferences
        // Default to business hours (9-17) if preference not set
        final hour = preference.averageHourPreference > 0
            ? preference.averageHourPreference
            : 9 + random.nextInt(8); // 9 AM to 5 PM

        final startTime = DateTime(
          selectedDay.year,
          selectedDay.month,
          selectedDay.day,
          hour,
          0,
        );

        final endTime = startTime.add(const Duration(hours: 1));

        // Ensure the event fits within the desired date range
        if (startTime.isAfter(startDate) && endTime.isBefore(endDate)) {
          final event = Event(
            id: 'suggested_${categoryId}_${startTime.millisecondsSinceEpoch}',
            title:
                '${preference.categoryName} - ${_formatWeekday(startTime.weekday)} at ${_formatTime(startTime)}',
            description: 'AI suggested event based on your preferences',
            startTime: startTime,
            endTime: endTime,
            color: preference.categoryColor,
            isAllDay: false,
            location: '',
            attendees: [],
          );

          events.add(event);
        }
      }
    }

    return events;
  }

  /// Get a list of working days between start and end date
  List<DateTime> _getWorkingDays(DateTime start, DateTime end) {
    final days = <DateTime>[];

    var current = DateTime(start.year, start.month, start.day);
    while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
      // Consider weekdays (Monday-Friday) as working days
      if (current.weekday >= 1 && current.weekday <= 5) {
        days.add(current);
      }

      current = current.add(const Duration(days: 1));
    }

    return days;
  }

  /// Format weekday number to string
  String _formatWeekday(int weekday) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return days[weekday - 1]; // weekday is 1-7, array is 0-6
  }

  /// Format time to AM/PM format
  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : time.hour;
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:${time.minute.toString().padLeft(2, '0')} $period';
  }
}
