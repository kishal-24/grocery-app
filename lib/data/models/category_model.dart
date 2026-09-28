import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';
import '../../core/constants/app_colors.dart';

class CategoryModel extends Equatable {
  final String id;
  final String name;
  final String image;
  final Color bgColor;
  final Color borderColor;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.image,
    required this.bgColor,
    required this.borderColor,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json, [String? docId]) {
    final id = docId ?? json['id'] as String? ?? '';
    final name = json['name'] as String? ?? '';
    final image = json['image'] as String? ?? '';

    Color bgColor = _parseColor(json['bgColor']) ?? _defaultBgColor(name);
    Color borderColor =
        _parseColor(json['borderColor']) ?? _defaultBorderColor(name);

    return CategoryModel(
      id: id,
      name: name,
      image: image,
      bgColor: bgColor,
      borderColor: borderColor,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'image': image,
      'bgColor': bgColor.toARGB32(),
      'borderColor': borderColor.toARGB32(),
    };
  }

  static Color? _parseColor(dynamic val) {
    if (val == null) return null;
    if (val is int) return Color(val);
    if (val is String) {
      final clean = val.replaceAll('#', '').replaceAll('0x', '');
      final hex = int.tryParse(clean, radix: 16);
      if (hex != null) {
        if (clean.length <= 6) {
          return Color(0xFF000000 | hex);
        }
        return Color(hex);
      }
    }
    return null;
  }

  static Color _defaultBgColor(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('fruit') || lower.contains('veg')) return AppColors.catGreenBg;
    if (lower.contains('oil') || lower.contains('ghee')) return AppColors.catOrangeBg;
    if (lower.contains('meat') || lower.contains('fish')) return AppColors.catRedBg;
    if (lower.contains('bake') || lower.contains('snack')) return AppColors.catPurpleBg;
    if (lower.contains('dairy') || lower.contains('egg')) return AppColors.catYellowBg;
    if (lower.contains('bev')) return AppColors.catBlueBg;
    return AppColors.catGreenBg;
  }

  static Color _defaultBorderColor(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('fruit') || lower.contains('veg')) return AppColors.catGreenBorder;
    if (lower.contains('oil') || lower.contains('ghee')) return AppColors.catOrangeBorder;
    if (lower.contains('meat') || lower.contains('fish')) return AppColors.catRedBorder;
    if (lower.contains('bake') || lower.contains('snack')) return AppColors.catPurpleBorder;
    if (lower.contains('dairy') || lower.contains('egg')) return AppColors.catYellowBorder;
    if (lower.contains('bev')) return AppColors.catBlueBorder;
    return AppColors.catGreenBorder;
  }

  CategoryModel copyWith({
    String? id,
    String? name,
    String? image,
    Color? bgColor,
    Color? borderColor,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      image: image ?? this.image,
      bgColor: bgColor ?? this.bgColor,
      borderColor: borderColor ?? this.borderColor,
    );
  }

  @override
  List<Object?> get props => [id, name, image, bgColor, borderColor];
}
