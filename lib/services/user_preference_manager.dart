import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/event_preference.dart';
import '../models/event_category.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class UserPreferenceManager extends ChangeNotifier {
  User? _currentUser;
  List<EventCategory> _categories = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  User? get currentUser => _currentUser;
  List<EventCategory> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Initialize with some default categories
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Load saved user from local storage
      await _loadUserFromStorage();

      // Initialize with default categories if none exist
      if (_categories.isEmpty) {
        _categories = [
          EventCategory(
            id: 'meeting',
            name: 'Meeting',
            color: Colors.blue,
            description: 'Regular team or client meetings',
          ),
          EventCategory(
            id: 'training',
            name: 'Training',
            color: Colors.green,
            description: 'Learning and development sessions',
          ),
          EventCategory(
            id: 'break',
            name: 'Break',
            color: Colors.orange,
            description: 'Scheduled breaks and rest times',
          ),
          EventCategory(
            id: 'admin',
            name: 'Admin Work',
            color: Colors.purple,
            description: 'Administrative tasks and paperwork',
          ),
          EventCategory(
            id: 'client',
            name: 'Client Session',
            color: Colors.red,
            description: 'One-on-one sessions with clients',
          ),
        ];
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
