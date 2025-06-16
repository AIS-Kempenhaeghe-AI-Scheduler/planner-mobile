import 'dart:convert';
import 'package:flutter/material.dart'; // Added import for Color class
import 'package:http/http.dart' as http;
import 'dart:async';
import '../models/user.dart';
import '../models/event.dart';
import '../models/event_preference.dart';
import '../models/event_category.dart';

/// Service for communicating with the Python neural network API
class NeuralNetworkService {
  // API Endpoint - using the developer machine's IP address
  // This needs to be the actual IP address of the computer running the API
  final String baseUrl =
      'http://192.168.178.109:5000/api'; // Using your PC's IP address

  // Default timeout duration for network requests
  final Duration _timeout = const Duration(seconds: 5);

  /// Initialize the neural network and connection
  Future<bool> initialize() async {
    try {
      // Check if the neural network API is running with a timeout
      final response = await http
          .get(Uri.parse('$baseUrl/health'))
          .timeout(_timeout, onTimeout: () {
        print('Neural network API connection timed out');
        return http.Response('{"status":"timeout"}', 408);
      });

      if (response.statusCode == 200) {
        print('Neural network API is running');
        return true;
      } else {
        print('Neural network API returned status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      // Safely catch all exceptions to prevent app crashes
      print('Error connecting to neural network API: $e');
      return false;
    }
  }

  /// Send user preferences to the neural network
  Future<bool> updatePreferences(User user) async {
    try {
      // Convert the user preferences to the format expected by the API
      final List<Map<String, dynamic>> preferencesJson = [];

      for (var pref in user.preferences) {
        preferencesJson.add({
          'category_id': pref.categoryId,
          'category_name': pref.categoryName,
          'category_color': _colorToHex(pref.categoryColor),
          'preference_score': pref.preferenceScore,
          'average_hour_preference': pref.averageHourPreference,
          'preferred_days_of_week': pref.preferredDaysOfWeek,
        });
      }

      final data = {
        'user_id': user.id,
        'preferences': preferencesJson,
      };

      final response = await http
          .post(
        Uri.parse('$baseUrl/preferences'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      )
          .timeout(_timeout, onTimeout: () {
        print('Update preferences request timed out');
        return http.Response('{"status":"timeout"}', 408);
      });

      if (response.statusCode == 200) {
        print('Preferences updated in neural network');
        return true;
      } else {
        print('Failed to update preferences: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error updating preferences: $e');
      return false;
    }
  }

  /// Submit feedback about an event to train the neural network
  Future<bool> submitFeedback({
    required String userId,
    required String eventId,
    required String categoryId,
    required DateTime eventTime,
    required double rating,
  }) async {
    try {
      final data = {
        'user_id': userId,
        'event_id': eventId,
        'category_id': categoryId,
        'event_time': eventTime.toIso8601String(),
        'rating': rating,
      };

      final response = await http
          .post(
        Uri.parse('$baseUrl/feedback'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      )
          .timeout(_timeout, onTimeout: () {
        print('Submit feedback request timed out');
        return http.Response('{"status":"timeout"}', 408);
      });

      if (response.statusCode == 200) {
        print('Feedback submitted to neural network');
        return true;
      } else {
        print('Failed to submit feedback: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error submitting feedback: $e');
      return false;
    }
  }

  /// Update neural network weights manually
  Future<bool> updateNetworkWeights(Map<String, double> scoreData) async {
    try {
      // Map Flutter-specific scores to a generalized rating
      // Combine the different metrics into a single rating
      final combinedRating = (scoreData['timeAccuracy'] ?? 0.5) * 0.4 +
          (scoreData['dayAccuracy'] ?? 0.5) * 0.3 +
          (scoreData['categoryAccuracy'] ?? 0.5) * 0.3;

      // The REST endpoint expects a full event feedback
      final data = {
        'user_id':
            'current_user', // Placeholder, should be replaced with actual user ID
        'event_id': 'manual_feedback_${DateTime.now().millisecondsSinceEpoch}',
        'category_id': 'general', // General category for manual feedback
        'event_time': DateTime.now().toIso8601String(),
        'rating': combinedRating,
      };

      final response = await http
          .post(
        Uri.parse('$baseUrl/feedback'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      )
          .timeout(_timeout, onTimeout: () {
        print('Update network weights request timed out');
        return http.Response('{"status":"timeout"}', 408);
      });

      if (response.statusCode == 200) {
        print('Neural network weights updated');
        return true;
      } else {
        print('Failed to update neural network weights: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error updating neural network weights: $e');
      return false;
    }
  }

  /// Get schedule recommendations from the neural network
  Future<List<Event>> suggestSchedule({
    required User user,
    required List<Map<String, dynamic>> requiredEvents,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // Format the request for the neural network API
      final data = {
        'user_id': user.id,
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
        'categories': requiredEvents,
      };

      final response = await http
          .post(
        Uri.parse('$baseUrl/recommend'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      )
          .timeout(_timeout, onTimeout: () {
        print('Suggest schedule request timed out');
        return http.Response('{"recommendations": []}', 408);
      });

      if (response.statusCode == 200) {
        final dynamic result = json.decode(response.body);

        // Handle case where the response doesn't contain recommendations
        if (result == null || !result.containsKey('recommendations')) {
          print('Invalid response format: missing recommendations key');
          return [];
        }

        final recommendations = result['recommendations'] as List;

        // Convert recommendations to Event objects
        final events = <Event>[];

        for (var rec in recommendations) {
          try {
            final time = DateTime.parse(rec['time']);
            final endTime =
                time.add(const Duration(hours: 1)); // Default 1-hour duration

            events.add(Event(
              id: rec['suggested_id'] ??
                  'suggested_${DateTime.now().millisecondsSinceEpoch}_${events.length}',
              title:
                  '${rec['category_name'] ?? 'Event'} - ${_formatWeekday(time.weekday)} at ${_formatTime(time)}',
              description:
                  'AI suggested event with score: ${((rec['score'] ?? 0.5) * 100).toStringAsFixed(1)}%',
              startTime: time,
              endTime: endTime,
              color: _hexToColor(rec['category_color'] ??
                  '#4285F4'), // Default blue if no color
              isAllDay: false,
              location: '',
              attendees: [],
            ));
          } catch (e) {
            print('Error parsing recommendation: $e');
            // Skip this recommendation and continue with others
            continue;
          }
        }

        return events;
      } else {
        print('Failed to get schedule recommendations: ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error getting schedule recommendations: $e');
      return [];
    }
  }

  // Helper methods
  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
  }

  Color _hexToColor(String hex) {
    try {
      // Remove the hash if present
      final hexCode = hex.startsWith('#') ? hex.substring(1) : hex;

      // Parse the hex code with error handling
      return Color(int.parse('FF$hexCode', radix: 16));
    } catch (e) {
      print('Error parsing color hex: $e');
      // Return a default color (blue) if parsing fails
      return const Color(0xFF4285F4);
    }
  }

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
    // Ensure weekday is in range 1-7
    final safeWeekday = (weekday < 1 || weekday > 7) ? 1 : weekday;
    return days[safeWeekday - 1]; // weekday is 1-7, array is 0-6
  }

  String _formatTime(DateTime time) {
    final hour =
        time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:${time.minute.toString().padLeft(2, '0')} $period';
  }
}
