import 'package:flutter/material.dart';

class PatrimoineCategory {
  final int id;
  final String name;
  final String icon;
  final Color color;

  PatrimoineCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });

  factory PatrimoineCategory.fromJson(Map<String, dynamic> json) {
    return PatrimoineCategory(
      id: json['id'],
      name: json['name'],
      icon: json['icon'],
      color: Color(int.parse(json['color'])),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'icon': icon,
    'color':
    '0x${color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}',
  };

  IconData getIconData() {
    switch (icon) {
      case 'account_balance_wallet':
        return Icons.account_balance_wallet;
      case 'savings':
        return Icons.savings;
      case 'trending_up':
        return Icons.trending_up;
      case 'card_giftcard':
        return Icons.card_giftcard;
      default:
        return Icons.account_balance;
    }
  }
}