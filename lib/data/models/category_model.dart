import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';

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

  @override
  List<Object?> get props => [id, name, image, bgColor, borderColor];
}
