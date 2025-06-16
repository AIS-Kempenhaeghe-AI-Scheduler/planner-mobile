import 'package:flutter/material.dart';

class EventCategory {
  final String id;
  final String name;
  final Color color;
  final String description;

  EventCategory({
    required this.id,
    required this.name,
    required this.color,
    this.description = '',
  });

  factory EventCategory.fromJson(Map<String, dynamic> json) {
    return EventCategory(
      id: json['id'],
      name: json['name'],
      color: Color(json['color']),
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color.value,
      'description': description,
    };
  }

  EventCategory copyWith({
    String? id,
    String? name,
    Color? color,
    String? description,
  }) {
    return EventCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      description: description ?? this.description,
    );
  }
}
