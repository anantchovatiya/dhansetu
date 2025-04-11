import 'package:flutter/material.dart';

class ExpenseCategory {
  final int? id;
  final String name;
  final int color;
  final int icon;

  ExpenseCategory({
    this.id,
    required this.name,
    required this.color,
    required this.icon,
  });

  ExpenseCategory copy({
    int? id,
    String? name,
    int? color,
    int? icon,
  }) =>
      ExpenseCategory(
        id: id ?? this.id,
        name: name ?? this.name,
        color: color ?? this.color,
        icon: icon ?? this.icon,
      );

  static ExpenseCategory fromJson(Map<String, dynamic> json) => ExpenseCategory(
        id: json['id'] as int?,
        name: json['name'] as String,
        color: json['color'] as int,
        icon: json['icon'] as int,
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'name': name,
        'color': color,
        'icon': icon,
      };

  IconData get iconData => IconData(icon, fontFamily: 'MaterialIcons');
  Color get colorValue => Color(color);
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpenseCategory &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
} 