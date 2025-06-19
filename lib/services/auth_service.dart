import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../models/user.dart';

class AuthService extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _error;
  String? _authToken;
  String? _refreshToken; // Add refresh token storage
  static const String _baseUrl = 'http://192.168.178.192:3000/api';

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null && _authToken != null;
  String? get error => _error;
  String? get authToken => _authToken;

  // Public method to refresh auth token
  Future<bool> refreshAuthToken() async {
    return await _refreshAuthToken();
  }

  AuthService() {
    _initializeAuthService();
  }

  Future<void> _initializeAuthService() async {
    try {
      debugPrint('Initializing AuthService...');
      await _checkSavedAuthState();
      debugPrint('AuthService initialized successfully');
    } catch (e) {
      debugPrint('Error initializing AuthService: $e');
      _error = 'Failed to initialize authentication service: $e';
      notifyListeners();
    }
  }

  Future<void> _checkSavedAuthState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString('authToken');
      final savedRefreshToken = prefs.getString('refreshToken');
      final savedUserJson = prefs.getString('currentUser');

      debugPrint('Saved token exists: ${savedToken != null}');
      debugPrint('Saved refresh token exists: ${savedRefreshToken != null}');
      debugPrint('Saved user exists: ${savedUserJson != null}');

      if (savedToken != null &&
          savedRefreshToken != null &&
          savedUserJson != null) {
        // Try to restore the user session
        final userData = jsonDecode(savedUserJson) as Map<String, dynamic>;
        _currentUser = User.fromJson(userData);
        _authToken = savedToken;
        _refreshToken = savedRefreshToken;

        debugPrint(
            'User session restored successfully for: ${_currentUser!.name}');
        notifyListeners();
      } else {
        debugPrint('No saved authentication state found');
      }
    } catch (e) {
      debugPrint('Error checking saved auth state: $e');
      _error = 'Failed to restore login session: $e';
      notifyListeners();
    }
  }

  Future<List<Map<String, dynamic>>> getUsers() async {
    try {
      debugPrint('Fetching users from backend...');

      final headers = <String, String>{
        'Content-Type': 'application/json',
      };

      // Add authorization header if token is available
      if (_authToken != null) {
        headers['Authorization'] = 'Bearer $_authToken';
      }

      final response = await http
          .get(
            Uri.parse('$_baseUrl/admin/users'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 401) {
        // Token expired, try to refresh
        if (await _refreshAuthToken()) {
          // Retry the request with new token
          return await getUsers();
        } else {
          throw Exception('Failed to refresh token');
        }
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final users = List<Map<String, dynamic>>.from(data['users']);
        debugPrint('Loaded ${users.length} users from backend');
        return users;
      } else {
        debugPrint('Failed to fetch users: ${response.statusCode}');
        throw Exception('Failed to fetch users: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error fetching users: $e');
      // Return empty list to prevent app crash
      return [];
    }
  }

  Future<bool> login(String username, String pincode) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('Attempting login with username: $username');

      final response = await http
          .post(
            Uri.parse('$_baseUrl/admin/user-login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'username': username,
              'pincode': pincode,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _authToken = data['token'];
        _refreshToken = data['refreshToken'];
        debugPrint('Login successful with tokens received');

        // Create User object from backend response
        final userData = data['user'];
        _currentUser = User(
          id: userData['id'].toString(),
          name: userData['name'],
          email: userData['email'],
          role: userData['role'],
          username: userData['email'], // Using email as username for now
          preferences: [], // Will be loaded separately if needed
        );

        debugPrint('Login successful for user: ${_currentUser!.name}');

        // Save authentication state
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('authToken', _authToken!);
        await prefs.setString('refreshToken', _refreshToken!);
        await prefs.setString(
            'currentUser', jsonEncode(_currentUser!.toJson()));

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        _error = errorData['message'] ?? 'Login failed';
        debugPrint('Login failed: $_error');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('Login error: $e');
      _error = 'Network error: Unable to connect to server';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      debugPrint('Logging out...');
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('authToken');
      await prefs.remove('refreshToken');
      await prefs.remove('currentUser');

      _currentUser = null;
      _authToken = null;
      _refreshToken = null;
      notifyListeners();
      debugPrint('Logout successful');
    } catch (e) {
      debugPrint('Logout failed: $e');
      _error = 'Logout failed: $e';
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<bool> _refreshAuthToken() async {
    if (_refreshToken == null) {
      debugPrint('No refresh token available');
      return false;
    }

    try {
      debugPrint('Attempting to refresh auth token...');

      final response = await http
          .post(
            Uri.parse('$_baseUrl/admin/refresh-token'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refreshToken': _refreshToken}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _authToken = data['token'];
        _refreshToken = data['refreshToken'];

        // Save new tokens
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('authToken', _authToken!);
        await prefs.setString('refreshToken', _refreshToken!);

        debugPrint('Token refreshed successfully');
        notifyListeners();
        return true;
      } else {
        debugPrint('Failed to refresh token: ${response.statusCode}');
        // Refresh token is invalid, log out user
        await logout();
        return false;
      }
    } catch (e) {
      debugPrint('Error refreshing token: $e');
      // Network error or other issue, log out user
      await logout();
      return false;
    }
  }

  Future<Map<String, dynamic>> resetPin(
      String currentPin, String newPin) async {
    try {
      debugPrint('Attempting to reset PIN...');

      if (_authToken == null) {
        throw Exception('Not authenticated');
      }

      // Validate new PIN format
      if (newPin.length != 6 || !RegExp(r'^\d{6}$').hasMatch(newPin)) {
        return {
          'success': false,
          'message': 'New PIN must be exactly 6 digits'
        };
      }

      final response = await http
          .post(
            Uri.parse('$_baseUrl/admin/reset-pin'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_authToken',
            },
            body: jsonEncode({
              'currentPin': currentPin,
              'newPin': newPin,
            }),
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        debugPrint('PIN reset successful');
        return {
          'success': true,
          'message': data['message'] ?? 'PIN reset successfully'
        };
      } else if (response.statusCode == 401) {
        // Try to refresh token and retry
        final refreshed = await _refreshAuthToken();
        if (refreshed) {
          return resetPin(currentPin, newPin);
        } else {
          return {
            'success': false,
            'message': 'Authentication failed. Please log in again.'
          };
        }
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to reset PIN'
        };
      }
    } catch (e) {
      debugPrint('PIN reset error: $e');
      return {'success': false, 'message': 'Network error. Please try again.'};
    }
  }
}
