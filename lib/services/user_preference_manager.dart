import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../models/event_preference.dart';
import '../models/event_category.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class UserPreferenceManager extends ChangeNotifier {
  static const String _baseUrl = 'http://192.168.178.192:3000/api/schedule';
  
  User? _currentUser;
  List<EventCategory> _categories = [];
  bool _isLoading = false;
  String? _error;
  // Getters
  User? get currentUser => _currentUser;
  List<EventCategory> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Fetch activities from the API
  Future<List<EventCategory>> _fetchActivitiesFromAPI() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/activities'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final activities = data['activities'] as List;
        
        // Convert activities to EventCategory objects
        return activities.asMap().entries.map((entry) {
          final index = entry.key;
          final activity = entry.value as String;
          
          // Generate different colors for each activity
          final colors = [
            Colors.blue,
            Colors.green,
            Colors.orange,
            Colors.purple,
            Colors.red,
            Colors.teal,
            Colors.indigo,
            Colors.pink,
          ];
          
          return EventCategory(
            id: activity.toLowerCase().replaceAll(' ', '_').replaceAll('&', 'and'),
            name: activity,
            color: colors[index % colors.length],
            description: 'Healthcare activity: $activity',
          );
        }).toList();
      } else {
        throw Exception('Failed to load activities: ${response.statusCode}');
      }
    } catch (e) {
      print('UserPreferenceManager: Error fetching activities from API - $e');
      // Return fallback categories if API fails
      return _getDefaultCategories();
    }
  }

  // Get default fallback categories
  List<EventCategory> _getDefaultCategories() {
    return [
      EventCategory(
        id: 'personal_care',
        name: 'Personal Care',
        color: Colors.blue,
        description: 'Healthcare activity: Personal Care',
      ),
      EventCategory(
        id: 'medical_support',
        name: 'Medical Support',
        color: Colors.green,
        description: 'Healthcare activity: Medical Support',
      ),
      EventCategory(
        id: 'activities_and_therapy',
        name: 'Activities & Therapy',
        color: Colors.orange,
        description: 'Healthcare activity: Activities & Therapy',
      ),
      EventCategory(
        id: 'meal_services',
        name: 'Meal Services',
        color: Colors.purple,
        description: 'Healthcare activity: Meal Services',
      ),
      EventCategory(
        id: 'night_care',
        name: 'Night Care',
        color: Colors.red,
        description: 'Healthcare activity: Night Care',
      ),
    ];
  }
  // Initialize with activities from API
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Load saved user from local storage
      await _loadUserFromStorage();

      // Fetch activities from API or use cached categories
      if (_categories.isEmpty) {
        _categories = await _fetchActivitiesFromAPI();
      }

      // If no user exists, create a default one
      if (_currentUser == null) {
        _currentUser = User(
          id: 'default_user',
          name: 'Default User',
          username: 'default_user',
          email: 'user@example.com',
          role: 'Employee',
          preferences: [], // No preferences set yet
        );
      }

      _error = null;
    } catch (e) {
      _error = 'Failed to initialize user preferences: $e';
      print('UserPreferenceManager: Error initializing - $_error');
      
      // Fallback to default categories if everything fails
      if (_categories.isEmpty) {
        _categories = _getDefaultCategories();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load user data from local storage
  Future<void> _loadUserFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user_data');

      if (userJson != null) {
        final userData = jsonDecode(userJson) as Map<String, dynamic>;
        _currentUser = User.fromJson(userData);
        print(
            'UserPreferenceManager: Loaded user ${_currentUser!.name} from storage');
      }

      final categoriesJson = prefs.getString('categories');
      if (categoriesJson != null) {
        final categoriesList = jsonDecode(categoriesJson) as List;
        _categories = categoriesList
            .map((cat) => EventCategory.fromJson(cat as Map<String, dynamic>))
            .toList();
        print(
            'UserPreferenceManager: Loaded ${_categories.length} categories from storage');
      }
    } catch (e) {
      print('UserPreferenceManager: Error loading from storage - $e');
      // Silently fail and use defaults
    }
  }

  // Save user data to local storage
  Future<void> _saveUserToStorage() async {
    if (_currentUser == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = jsonEncode(_currentUser!.toJson());
      await prefs.setString('user_data', userJson);

      final categoriesJson =
          jsonEncode(_categories.map((c) => c.toJson()).toList());
      await prefs.setString('categories', categoriesJson);

      print('UserPreferenceManager: Saved user and categories to storage');
    } catch (e) {
      print('UserPreferenceManager: Error saving to storage - $e');
      // Handle error but don't throw to avoid disrupting the app flow
    }
  }

  // Refresh activities from API
  Future<void> refreshActivities() async {
    _isLoading = true;
    notifyListeners();

    try {
      _categories = await _fetchActivitiesFromAPI();
      // Save updated categories to storage
      await _saveUserToStorage();
      _error = null;
    } catch (e) {
      _error = 'Failed to refresh activities: $e';
      print('UserPreferenceManager: Error refreshing activities - $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update a user's preference for a specific category
  Future<void> updatePreference(EventPreference preference) async {
    if (_currentUser == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      // Check if this preference already exists
      final existingIndex = _currentUser!.preferences
          .indexWhere((p) => p.categoryId == preference.categoryId);

      final updatedPreferences =
          List<EventPreference>.from(_currentUser!.preferences);

      if (existingIndex >= 0) {
        // Update existing preference
        updatedPreferences[existingIndex] = preference;
      } else {
        // Add new preference
        updatedPreferences.add(preference);
      }

      // Create updated user
      _currentUser = _currentUser!.copyWith(preferences: updatedPreferences);

      // Save to storage
      await _saveUserToStorage();

      _error = null;
    } catch (e) {
      _error = 'Failed to update preference: $e';
      print('UserPreferenceManager: Error updating preference - $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add a new category
  Future<void> addCategory(EventCategory category) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Check if a category with this ID already exists
      final existingIndex = _categories.indexWhere((c) => c.id == category.id);

      if (existingIndex >= 0) {
        // Update existing category
        _categories[existingIndex] = category;
      } else {
        // Add new category
        _categories.add(category);
      }

      // Save to storage
      await _saveUserToStorage();

      _error = null;
    } catch (e) {
      _error = 'Failed to add category: $e';
      print('UserPreferenceManager: Error adding category - $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete a category
  Future<void> deleteCategory(String categoryId) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Remove the category
      _categories.removeWhere((c) => c.id == categoryId);

      // Also remove any user preferences for this category
      if (_currentUser != null) {
        final updatedPreferences = _currentUser!.preferences
            .where((p) => p.categoryId != categoryId)
            .toList();

        _currentUser = _currentUser!.copyWith(preferences: updatedPreferences);
      }

      // Save to storage
      await _saveUserToStorage();

      _error = null;
    } catch (e) {
      _error = 'Failed to delete category: $e';
      print('UserPreferenceManager: Error deleting category - $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get a specific category by ID
  EventCategory? getCategoryById(String categoryId) {
    try {
      return _categories.firstWhere((c) => c.id == categoryId);
    } catch (e) {
      return null;
    }
  }

  // Get user preference for a specific category
  EventPreference? getPreferenceForCategory(String categoryId) {
    if (_currentUser == null) return null;

    try {
      return _currentUser!.preferences.firstWhere(
        (p) => p.categoryId == categoryId,
      );
    } catch (e) {
      // No preference found for this category
      return null;
    }
  }

  // Update user information
  Future<void> updateUserInfo({
    String? name,
    String? email,
    String? role,
  }) async {
    if (_currentUser == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      _currentUser = _currentUser!.copyWith(
        name: name ?? _currentUser!.name,
        email: email ?? _currentUser!.email,
        role: role ?? _currentUser!.role,
      );

      // Save to storage
      await _saveUserToStorage();

      _error = null;
    } catch (e) {
      _error = 'Failed to update user info: $e';
      print('UserPreferenceManager: Error updating user info - $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
