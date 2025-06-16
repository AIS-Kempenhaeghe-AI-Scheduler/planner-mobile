import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/event.dart';

class ApiConfig {
  // API server address configured for actual device connections
  // Using the host machine's direct IP address for direct connection
  static const String baseUrl = 'http://192.168.178.109:3000/api';
}

class ApiResponse<T> {
  final T? data;
  final String? error;
  final bool success;

  ApiResponse({this.data, this.error, required this.success});

  factory ApiResponse.success(T data) {
    return ApiResponse(data: data, success: true);
  }

  factory ApiResponse.error(String message) {
    return ApiResponse(error: message, success: false);
  }
}

class EventService {
  final String _eventsUrl = '${ApiConfig.baseUrl}/events';

  // Get all events
  Future<ApiResponse<List<Event>>> getEvents() async {
    try {
      final response = await http.get(Uri.parse(_eventsUrl));

      if (response.statusCode == 200) {
        final List<dynamic> eventsJson = jsonDecode(response.body);
        final events =
            eventsJson.map((json) => _parseEventFromJson(json)).toList();
        return ApiResponse.success(events);
      } else {
        final errorMessage = _getErrorMessage(response);
        print('Error fetching events: $errorMessage');
        print('Response status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        return ApiResponse.error(errorMessage);
      }
    } catch (e) {
      print('Exception in getEvents: $e');
      print('Stack trace: ${StackTrace.current}');
      return ApiResponse.error('Failed to connect to the server: $e');
    }
  }

  // Get a single event by ID
  Future<ApiResponse<Event>> getEvent(String id) async {
    try {
      final response = await http.get(Uri.parse('$_eventsUrl/$id'));

      if (response.statusCode == 200) {
        final eventJson = jsonDecode(response.body);
        final event = _parseEventFromJson(eventJson);
        return ApiResponse.success(event);
      } else {
        final errorMessage = _getErrorMessage(response);
        print('Error fetching event $id: $errorMessage');
        print('Response status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        return ApiResponse.error(errorMessage);
      }
    } catch (e) {
      print('Exception in getEvent for id $id: $e');
      print('Stack trace: ${StackTrace.current}');
      return ApiResponse.error('Failed to connect to the server: $e');
    }
  }

  // Create a new event
  Future<ApiResponse<Event>> createEvent(Event event) async {
    try {
      final eventJson = _eventToJson(event);
      print('Creating event with data: $eventJson');

      final response = await http.post(
        Uri.parse(_eventsUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(eventJson),
      );

      if (response.statusCode == 201) {
        final eventJson = jsonDecode(response.body);
        final createdEvent = _parseEventFromJson(eventJson);
        return ApiResponse.success(createdEvent);
      } else {
        final errorMessage = _getErrorMessage(response);
        print('Error creating event: $errorMessage');
        print('Response status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        return ApiResponse.error(errorMessage);
      }
    } catch (e) {
      print('Exception in createEvent: $e');
      print('Stack trace: ${StackTrace.current}');
      return ApiResponse.error('Failed to connect to the server: $e');
    }
  }

  // Update an existing event
  Future<ApiResponse<Event>> updateEvent(Event event) async {
    try {
      final eventJson = _eventToJson(event);
      print('Updating event with id: ${event.id}');
      print('Update data: $eventJson');

      final response = await http.put(
        Uri.parse('$_eventsUrl/${event.id}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(eventJson),
      );

      print('Update response status code: ${response.statusCode}');
      print('Update response body: ${response.body}');

      if (response.statusCode == 200) {
        final eventJson = jsonDecode(response.body);
        final updatedEvent = _parseEventFromJson(eventJson);
        return ApiResponse.success(updatedEvent);
      } else {
        final errorMessage = _getErrorMessage(response);
        print('Error updating event: $errorMessage');
        return ApiResponse.error(errorMessage);
      }
    } catch (e) {
      print('Exception in updateEvent for id ${event.id}: $e');
      print('Stack trace: ${StackTrace.current}');
      return ApiResponse.error('Failed to connect to the server: $e');
    }
  }

  // Delete an event
  Future<ApiResponse<bool>> deleteEvent(String id) async {
    try {
      final response = await http.delete(Uri.parse('$_eventsUrl/$id'));

      if (response.statusCode == 200) {
        return ApiResponse.success(true);
      } else {
        final errorMessage = _getErrorMessage(response);
        return ApiResponse.error(errorMessage);
      }
    } catch (e) {
      return ApiResponse.error('Failed to connect to the server: $e');
    }
  }

  // Helper method to parse event from JSON
  Event _parseEventFromJson(Map<String, dynamic> json) {
    // Handle color that might come as either string or int
    Color eventColor;
    if (json['color'] == null) {
      // Use a default color if no color is provided
      eventColor = Colors.blue;
    } else if (json['color'] is String) {
      // If color is a string, parse it to an integer
      try {
        eventColor = Color(int.parse(json['color']));
      } catch (e) {
        // Fallback to default color if parsing fails
        print('Error parsing color: ${json['color']}');
        eventColor = Colors.blue;
      }
    } else {
      // If color is already an integer
      eventColor = Color(json['color']);
    }

    return Event(
      id: json['id'],
      title: json['title'],
      description: json['description'] ?? '',
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      color: eventColor,
      isAllDay: json['isAllDay'] ?? false,
      attendees: List<String>.from(json['attendees'] ?? []),
      location: json['location'] ?? '',
      recurrenceRule: json['recurrenceRule'],
    );
  }

  // Helper method to convert event to JSON
  Map<String, dynamic> _eventToJson(Event event) {
    return {
      'id': event.id,
      'title': event.title,
      'description': event.description,
      'startTime': event.startTime.toIso8601String(),
      'endTime': event.endTime.toIso8601String(),
      'color': event.color.value,
      'isAllDay': event.isAllDay,
      'attendees': event.attendees,
      'location': event.location,
      'recurrenceRule': event.recurrenceRule,
    };
  }

  // Helper method to extract error message from response
  String _getErrorMessage(http.Response response) {
    try {
      final jsonBody = jsonDecode(response.body);
      return jsonBody['error'] ?? 'Error: ${response.statusCode}';
    } catch (e) {
      return 'Error: ${response.statusCode}';
    }
  }
}
