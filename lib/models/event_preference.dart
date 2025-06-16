import 'package:flutter/material.dart';

/// Represents a user's preference for a particular event category (color).
/// The preference score is a value between 0 and 1, where:
/// - 0: User strongly dislikes this category
/// - 0.5: User is neutral about this category
/// - 1.0: User strongly prefers this category
class EventPreference {
  final String categoryId;
  final Color categoryColor;
  final String categoryName;
  final double preferenceScore; // Ranges from 0.0 (dislike) to 1.0 (prefer)
  final int averageHourPreference; // Preferred hour of day (0-23)
  final List<int> preferredDaysOfWeek; // 1=Monday, 7=Sunday

  EventPreference({
    required this.categoryId,
    required this.categoryColor,
    required this.categoryName,
    this.preferenceScore = 0.5, // Default is neutral
    this.averageHourPreference = 9, // Default is 9 AM
    this.preferredDaysOfWeek = const [1, 2, 3, 4, 5], // Default is weekdays
  });

  factory EventPreference.fromJson(Map<String, dynamic> json) {
    return EventPreference(
      categoryId: json['categoryId'],
      categoryColor: Color(json['categoryColor']),
      categoryName: json['categoryName'],
      preferenceScore: json['preferenceScore'] ?? 0.5,
      averageHourPreference: json['averageHourPreference'] ?? 9,
      preferredDaysOfWeek: json['preferredDaysOfWeek'] != null
          ? List<int>.from(json['preferredDaysOfWeek'])
          : [1, 2, 3, 4, 5],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categoryId': categoryId,
      'categoryColor': categoryColor.value,
      'categoryName': categoryName,
      'preferenceScore': preferenceScore,
      'averageHourPreference': averageHourPreference,
      'preferredDaysOfWeek': preferredDaysOfWeek,
    };
  }

  EventPreference copyWith({
    String? categoryId,
    Color? categoryColor,
    String? categoryName,
    double? preferenceScore,
    int? averageHourPreference,
    List<int>? preferredDaysOfWeek,
  }) {
    return EventPreference(
      categoryId: categoryId ?? this.categoryId,
      categoryColor: categoryColor ?? this.categoryColor,
      categoryName: categoryName ?? this.categoryName,
      preferenceScore: preferenceScore ?? this.preferenceScore,
      averageHourPreference:
          averageHourPreference ?? this.averageHourPreference,
      preferredDaysOfWeek: preferredDaysOfWeek ?? this.preferredDaysOfWeek,
    );
  }
}
