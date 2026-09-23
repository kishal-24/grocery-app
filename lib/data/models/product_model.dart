import 'package:equatable/equatable.dart';

class ProductModel extends Equatable {
  final String id;
  final String name;
  final String description;
  final String unit; // e.g. "1kg, Price", "7pcs, Price"
  final double price;
  final String image;
  final String category;
  final double rating;
  final int reviewsCount;
  final String nutritionInfo;
  final bool isExclusive;
  final bool isBestSelling;

  const ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.unit,
    required this.price,
    required this.image,
    required this.category,
    this.rating = 4.8,
    this.reviewsCount = 120,
    this.nutritionInfo = '100gr ~ 52 kcal',
    this.isExclusive = false,
    this.isBestSelling = false,
  });

  ProductModel copyWith({
    String? id,
    String? name,
    String? description,
    String? unit,
    double? price,
    String? image,
    String? category,
    double? rating,
    int? reviewsCount,
    String? nutritionInfo,
    bool? isExclusive,
    bool? isBestSelling,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      unit: unit ?? this.unit,
      price: price ?? this.price,
      image: image ?? this.image,
      category: category ?? this.category,
      rating: rating ?? this.rating,
      reviewsCount: reviewsCount ?? this.reviewsCount,
      nutritionInfo: nutritionInfo ?? this.nutritionInfo,
      isExclusive: isExclusive ?? this.isExclusive,
      isBestSelling: isBestSelling ?? this.isBestSelling,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        unit,
        price,
        image,
        category,
        rating,
        reviewsCount,
        nutritionInfo,
        isExclusive,
        isBestSelling,
      ];
}
