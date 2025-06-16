import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ScheduleService extends ChangeNotifier {
  static const String _baseUrl = 'http://192.168.178.248:3000/api/schedule';
  String? _authToken;

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

  // Helper method to format date as YYYY-MM-DD
  String formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Helper method to get the start of the week (Monday)
  DateTime getWeekStart(DateTime date) {
    final weekday = date.weekday;
    return date.subtract(Duration(days: weekday - 1));
  }
}
