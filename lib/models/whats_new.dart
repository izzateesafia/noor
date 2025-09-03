import 'package:flutter/material.dart';

class WhatsNew {
  final String id;
  final IconData icon;
  final String title;
  final String subtitle;
  final String? link;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isActive;

  WhatsNew({
    required this.id,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.link,
    this.createdAt,
    this.updatedAt,
    this.isActive = true,
  });

  factory WhatsNew.fromJson(Map<String, dynamic> json) {
    return WhatsNew(
      id: json['id'] ?? '',
      icon: _getIconFromString(json['icon'] ?? 'star'),
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      link: json['link'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'subtitle': subtitle,
      'icon': icon.codePoint.toString(),
      'link': link,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isActive': isActive,
    };
  }

  static IconData _getIconFromString(String iconName) {
    switch (iconName) {
      case 'star':
        return Icons.star;
      case 'tips_and_updates':
        return Icons.tips_and_updates;
      case 'book':
        return Icons.book;
      case 'school':
        return Icons.school;
      case 'favorite':
        return Icons.favorite;
      case 'explore':
        return Icons.explore;
      default:
        return Icons.star;
    }
  }
}
