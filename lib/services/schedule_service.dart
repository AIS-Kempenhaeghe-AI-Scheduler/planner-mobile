import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/event.dart';

class ScheduleService extends ChangeNotifier {
  static const String _baseUrl = 'http://192.168.178.192:3000/api/schedule';
  static const String _eventsUrl = 'http://192.168.178.192:3000/api/events';
  String? _authToken;
  List<Event> _events = [];
  bool _isLoading = false;
  String? _error;

  List<Event> get events => _events;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void setAuthToken(String? token) {
    _authToken = token;
    notifyListeners();
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_authToken != null) 'Authorization': 'Bearer $_authToken',
      };

  // Get current user's daily schedule
  Future<Map<String, dynamic>> getMyDailySchedule(String date) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/my/daily/$date'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required');
      } else {
        throw Exception('Failed to load daily schedule: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error fetching daily schedule: $e');
      rethrow;
    }
  }

  // Get current user's weekly schedule
  Future<Map<String, dynamic>> getMyWeeklySchedule(String startDate) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/my/weekly/$startDate'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required');
      } else {
        throw Exception('Failed to load weekly schedule: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error fetching weekly schedule: $e');
      rethrow;
    }
  }

  // Get current user's monthly schedule
  Future<Map<String, dynamic>> getMyMonthlySchedule(int year, int month) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/my/monthly/$year/$month'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required');
      } else {
        throw Exception('Failed to load monthly schedule: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error fetching monthly schedule: $e');
      rethrow;
    }
  }

  // Load events from API - now loads from schedule endpoints
  Future<void> loadEvents() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('ScheduleService: Loading events from API');

      if (_authToken == null) {
        _error = 'Authentication required';
        debugPrint('ScheduleService: No auth token available');
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Get current month's schedule
      final now = DateTime.now();
      final scheduleData = await getMyMonthlySchedule(now.year, now.month);

      debugPrint('ScheduleService: Raw schedule response received');

      _events = [];
      final monthSchedule =
          scheduleData['monthSchedule'] as Map<String, dynamic>?;

      if (monthSchedule != null) {
        debugPrint(
            'ScheduleService: Processing ${monthSchedule.length} schedule days');

        for (var entry in monthSchedule.entries) {
          final dateStr = entry.key;
          final dayData = entry.value as Map<String, dynamic>;
          final activities = dayData['activities'] as List<dynamic>?;

          if (activities != null) {
            for (var activity in activities) {
              final activityMap = activity as Map<String, dynamic>;
              final activityName = activityMap['activity'] as String;
              final timeSlot =
                  activityMap['time'] as String; // e.g., "09:00-17:00"

              try {
                final event =
                    _createEventFromSchedule(dateStr, activityName, timeSlot);
                _events.add(event);
              } catch (e) {
                debugPrint(
                    'ScheduleService: Error creating event for $dateStr $activityName: $e');
              }
            }
          }
        }
      }

      debugPrint(
          'ScheduleService: Loaded ${_events.length} events successfully');
    } catch (e) {
      _error = 'Failed to load schedule: $e';
      debugPrint('ScheduleService: Exception loading events - $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load events for a specific month
  Future<void> loadEventsForMonth(int year, int month) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('ScheduleService: Loading events for $year-$month');

      if (_authToken == null) {
        _error = 'Authentication required';
        debugPrint('ScheduleService: No auth token available');
        _isLoading = false;
        notifyListeners();
        return;
      }

      final scheduleData = await getMyMonthlySchedule(year, month);

      debugPrint(
          'ScheduleService: Raw schedule response received for $year-$month');

      // Clear existing events for this month
      _events.removeWhere((event) =>
          event.startTime.year == year && event.startTime.month == month);

      final monthSchedule =
          scheduleData['monthSchedule'] as Map<String, dynamic>?;

      if (monthSchedule != null) {
        debugPrint(
            'ScheduleService: Processing ${monthSchedule.length} schedule days');

        for (var entry in monthSchedule.entries) {
          final dateStr = entry.key;
          final dayData = entry.value as Map<String, dynamic>;
          final activities = dayData['activities'] as List<dynamic>?;

          if (activities != null) {
            for (var activity in activities) {
              final activityMap = activity as Map<String, dynamic>;
              final activityName = activityMap['activity'] as String;
              final timeSlot = activityMap['time'] as String;

              try {
                final event =
                    _createEventFromSchedule(dateStr, activityName, timeSlot);
                _events.add(event);
              } catch (e) {
                debugPrint(
                    'ScheduleService: Error creating event for $dateStr $activityName: $e');
              }
            }
          }
        }
      }

      debugPrint(
          'ScheduleService: Loaded ${_events.where((e) => e.startTime.year == year && e.startTime.month == month).length} events for $year-$month');
    } catch (e) {
      _error = 'Failed to load schedule for $year-$month: $e';
      debugPrint(
          'ScheduleService: Exception loading events for $year-$month - $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load events for a specific week
  Future<void> loadEventsForWeek(DateTime weekStart) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final startDateString = formatDate(weekStart);
      debugPrint(
          'ScheduleService: Loading events for week starting $startDateString');

      if (_authToken == null) {
        _error = 'Authentication required';
        debugPrint('ScheduleService: No auth token available');
        _isLoading = false;
        notifyListeners();
        return;
      }

      final scheduleData = await getMyWeeklySchedule(startDateString);

      debugPrint(
          'ScheduleService: Raw weekly schedule response received for $startDateString');

      // Clear existing events for this week
      final weekEnd = weekStart.add(const Duration(days: 7));
      _events.removeWhere((event) =>
          (event.startTime.isAfter(weekStart) ||
              event.startTime.isAtSameMomentAs(weekStart)) &&
          event.startTime.isBefore(weekEnd));

      final weekSchedule =
          scheduleData['weekSchedule'] as Map<String, dynamic>?;

      if (weekSchedule != null) {
        debugPrint(
            'ScheduleService: Processing ${weekSchedule.length} schedule days');

        for (var entry in weekSchedule.entries) {
          final dateStr = entry.key;
          final dayData = entry.value as Map<String, dynamic>;
          final activities = dayData['activities'] as List<dynamic>?;

          if (activities != null) {
            for (var activity in activities) {
              final activityMap = activity as Map<String, dynamic>;
              final activityName = activityMap['activity'] as String;
              final timeSlot = activityMap['time'] as String;

              try {
                final event =
                    _createEventFromSchedule(dateStr, activityName, timeSlot);
                _events.add(event);
              } catch (e) {
                debugPrint(
                    'ScheduleService: Error creating event for $dateStr $activityName: $e');
              }
            }
          }
        }
      }

      debugPrint(
          'ScheduleService: Loaded ${_events.where((e) => (e.startTime.isAfter(weekStart) || e.startTime.isAtSameMomentAs(weekStart)) && e.startTime.isBefore(weekEnd)).length} events for week starting $startDateString');
    } catch (e) {
      _error =
          'Failed to load schedule for week starting ${formatDate(weekStart)}: $e';
      debugPrint('ScheduleService: Exception loading events for week - $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add a new event
  Future<bool> addEvent(Event event) async {
    try {
      debugPrint(
          'ScheduleService: Adding new event - ID: ${event.id}, Title: ${event.title}');

      final response = await http
          .post(
            Uri.parse(_eventsUrl),
            headers: _headers,
            body: jsonEncode(_eventToJson(event)),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 201) {
        final eventJson = jsonDecode(response.body);
        final createdEvent = _parseEventFromJson(eventJson);
        _events.add(createdEvent);
        debugPrint('ScheduleService: Event added successfully');
        notifyListeners();
        return true;
      } else {
        _error = 'Failed to create event: ${response.body}';
        debugPrint('ScheduleService: Error adding event - $_error');
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Failed to connect to server: $e';
      debugPrint('ScheduleService: Exception adding event - $e');
      notifyListeners();
      return false;
    }
  }

  // Update an existing event
  Future<bool> updateEvent(Event event) async {
    try {
      debugPrint(
          'ScheduleService: Updating event - ID: ${event.id}, Title: ${event.title}');

      final response = await http
          .put(
            Uri.parse('$_eventsUrl/${event.id}'),
            headers: _headers,
            body: jsonEncode(_eventToJson(event)),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final eventJson = jsonDecode(response.body);
        final updatedEvent = _parseEventFromJson(eventJson);
        final index = _events.indexWhere((e) => e.id == event.id);
        if (index != -1) {
          _events[index] = updatedEvent;
          debugPrint('ScheduleService: Event updated successfully');
        } else {
          debugPrint(
              'ScheduleService: Event not found in local list, ID: ${event.id}');
        }
        notifyListeners();
        return true;
      } else {
        _error = 'Failed to update event: ${response.body}';
        debugPrint('ScheduleService: Error updating event - $_error');
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Failed to connect to server: $e';
      debugPrint('ScheduleService: Exception updating event - $e');
      notifyListeners();
      return false;
    }
  }

  // Delete an event
  Future<bool> deleteEvent(String id) async {
    try {
      debugPrint('ScheduleService: Deleting event - ID: $id');

      final response = await http
          .delete(Uri.parse('$_eventsUrl/$id'), headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        _events.removeWhere((event) => event.id == id);
        debugPrint('ScheduleService: Event deleted successfully');
        notifyListeners();
        return true;
      } else {
        _error = 'Failed to delete event: ${response.body}';
        debugPrint('ScheduleService: Error deleting event - $_error');
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Failed to connect to server: $e';
      debugPrint('ScheduleService: Exception deleting event - $e');
      notifyListeners();
      return false;
    }
  }

  // Get events for a specific day
  List<Event> getEventsForDay(DateTime day) {
    final startOfDay = DateTime(day.year, day.month, day.day);
    final endOfDay = DateTime(day.year, day.month, day.day, 23, 59, 59);

    return _events.where((event) {
      return (event.startTime.isAfter(startOfDay) ||
              event.startTime.isAtSameMomentAs(startOfDay)) &&
          (event.startTime.isBefore(endOfDay) ||
              event.startTime.isAtSameMomentAs(endOfDay));
    }).toList();
  }

  // Get events for a specific week
  List<Event> getEventsForWeek(DateTime weekStart) {
    final weekEnd = weekStart.add(const Duration(days: 7));

    return _events.where((event) {
      return (event.startTime.isAfter(weekStart) ||
              event.startTime.isAtSameMomentAs(weekStart)) &&
          event.startTime.isBefore(weekEnd);
    }).toList();
  }

  // Get events for a specific month
  List<Event> getEventsForMonth(DateTime month) {
    return _events.where((event) {
      return event.startTime.year == month.year &&
          event.startTime.month == month.month;
    }).toList();
  }

  // Helper method to parse event from JSON
  Event _parseEventFromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      color: _getCategoryColor(json['category']),
      isAllDay: json['isAllDay'] ?? false,
      location: json['location'] ?? '',
      attendees: json['userName'] != null ? [json['userName']] : [],
      recurrenceRule: json['recurrenceRule'],
    );
  }

  // Helper method to get color based on category
  Color _getCategoryColor(String? category) {
    switch (category) {
      case 'Activities & Therapy':
        return Colors.blue;
      case 'Meal Services':
        return Colors.green;
      case 'Medical Support':
        return Colors.red;
      case 'Night Care':
        return Colors.purple;
      case 'Personal Care':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  // Helper method to convert event to JSON
  Map<String, dynamic> _eventToJson(Event event) {
    return {
      'id': event.id,
      'title': event.title,
      'description': event.description,
      'startTime': event.startTime.toIso8601String(),
      'endTime': event.endTime.toIso8601String(),
      'color': event.color.value.toString(),
      'isAllDay': event.isAllDay,
      'location': event.location,
      'attendees': event.attendees,
      'recurrenceRule': event.recurrenceRule,
    };
  }

  // Helper method to format date as YYYY-MM-DD
  String formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Helper method to get the start of the week (Monday)
  DateTime getWeekStart(DateTime date) {
    final weekday = date.weekday;
    return date.subtract(Duration(days: weekday - 1));
  }

  // Helper method to create Event from schedule data
  Event _createEventFromSchedule(
      String dateStr, String activityName, String timeSlot) {
    final date = DateTime.parse(dateStr);
    final times = timeSlot.split('-');

    DateTime startTime, endTime;

    if (times.length == 2) {
      final startParts = times[0].split(':');
      final endParts = times[1].split(':');

      startTime = DateTime(
        date.year,
        date.month,
        date.day,
        int.parse(startParts[0]),
        int.parse(startParts[1]),
      );

      endTime = DateTime(
        date.year,
        date.month,
        date.day,
        int.parse(endParts[0]),
        int.parse(endParts[1]),
      );
    } else {
      // Default to 8-hour shift if time parsing fails
      startTime = DateTime(date.year, date.month, date.day, 9, 0);
      endTime = DateTime(date.year, date.month, date.day, 17, 0);
    }

    return Event(
      id: '${dateStr}_${activityName.replaceAll(' ', '_')}',
      title: activityName,
      description: 'Healthcare activity: $activityName',
      startTime: startTime,
      endTime: endTime,
      color: _getCategoryColor(activityName),
      isAllDay: false,
      location: 'Healthcare Facility',
      attendees: [], // Could be populated with other assigned employees
    );
  }
}
