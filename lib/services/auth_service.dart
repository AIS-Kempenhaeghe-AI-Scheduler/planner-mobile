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
  String?
      _authToken; // Backend API base URL - update this to match your backend server
  static const String _baseUrl = 'http://192.168.178.248:3000/api';

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null && _authToken != null;
  String? get error => _error;
  String? get authToken => _authToken;

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
      final savedUserJson = prefs.getString('currentUser');

      debugPrint('Saved token exists: ${savedToken != null}');
      debugPrint('Saved user exists: ${savedUserJson != null}');

      if (savedToken != null && savedUserJson != null) {
        // Try to restore the user session
        final userData = jsonDecode(savedUserJson) as Map<String, dynamic>;
        _currentUser = User.fromJson(userData);
        _authToken = savedToken;

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
        debugPrint('Auth token: [32m[1m[4m[7m[5m[41m[30m[47m[0m[1m[32m[0m[1m[32m[0m[1m[32m[0m[1m[32m[0m[1m[32m[0m[1m[32m[0m[1m[32m[0m[1m[32m[0m[1m[32m[0m[1m[32m[0m[1m[32m[0m[1m[32m');
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
      await prefs.remove('currentUser');

      _currentUser = null;
      _authToken = null;
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
}
