import 'package:flutter/material.dart';
import '../models/event.dart';
import '../services/event_service.dart';

class EventManager extends ChangeNotifier {
  final EventService _eventService = EventService();
  List<Event> _events = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Event> get events => _events;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Initialize by loading events from the API
  Future<void> loadEvents() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('EventManager: Loading events from API');
      final response = await _eventService.getEvents();
      if (response.success) {
        _events = response.data!;
        print('EventManager: Loaded ${_events.length} events successfully');
      } else {
        _error = response.error;
        print('EventManager: Error loading events - ${response.error}');
      }
    } catch (e) {
      _error = 'Failed to load events: $e';
      print('EventManager: Exception loading events - $e');
      print('EventManager: Stack trace - ${StackTrace.current}');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add a new event
  Future<void> addEvent(Event event) async {
    _isLoading = true;
    notifyListeners();

    try {
      print(
        'EventManager: Adding new event - ID: ${event.id}, Title: ${event.title}',
      );
      final response = await _eventService.createEvent(event);
      if (response.success) {
        _events.add(response.data!);
        print('EventManager: Event added successfully');
      } else {
        _error = response.error;
        print('EventManager: Error adding event - ${response.error}');
      }
    } catch (e) {
      _error = 'Failed to add event: $e';
      print('EventManager: Exception adding event - $e');
      print('EventManager: Stack trace - ${StackTrace.current}');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update an existing event
  Future<void> updateEvent(Event event) async {
    _isLoading = true;
    notifyListeners();

    try {
      print(
        'EventManager: Updating event - ID: ${event.id}, Title: ${event.title}',
      );
      final response = await _eventService.updateEvent(event);
      if (response.success) {
        final index = _events.indexWhere((e) => e.id == event.id);
        if (index >= 0) {
          _events[index] = response.data!;
          print('EventManager: Event updated successfully');
        } else {
          print('EventManager: Event not found in local list, ID: ${event.id}');
        }
      } else {
        _error = response.error;
        print('EventManager: Error updating event - ${response.error}');
      }
    } catch (e) {
      _error = 'Failed to update event: $e';
      print('EventManager: Exception updating event - $e');
      print('EventManager: Stack trace - ${StackTrace.current}');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete an event
  Future<void> deleteEvent(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      print('EventManager: Deleting event - ID: $id');
      final response = await _eventService.deleteEvent(id);
      if (response.success) {
        _events.removeWhere((e) => e.id == id);
        print('EventManager: Event deleted successfully');
      } else {
        _error = response.error;
        print('EventManager: Error deleting event - ${response.error}');
      }
    } catch (e) {
      _error = 'Failed to delete event: $e';
      print('EventManager: Exception deleting event - $e');
      print('EventManager: Stack trace - ${StackTrace.current}');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get events for a specific day
  List<Event> getEventsForDay(DateTime day) {
    return _events.where((event) {
      final start = DateTime(
        event.startTime.year,
        event.startTime.month,
        event.startTime.day,
      );
      final end = DateTime(
        event.endTime.year,
        event.endTime.month,
        event.endTime.day,
      );

      // Check if the day is between start and end date (inclusive)
      final dayDate = DateTime(day.year, day.month, day.day);
      return (dayDate.isAtSameMomentAs(start) || dayDate.isAfter(start)) &&
          (dayDate.isAtSameMomentAs(end) || dayDate.isBefore(end));
    }).toList();
  }
}
