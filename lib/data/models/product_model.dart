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

  factory ProductModel.fromJson(Map<String, dynamic> json, [String? docId]) {
    dynamic getValue(String key) {
      if (json.containsKey(key)) return json[key];
      for (final entry in json.entries) {
        if (entry.key.trim().toLowerCase() == key.toLowerCase()) {
          return entry.value;
        }
      }
      return null;
    }

    final id = docId ?? (getValue('id') as String? ?? '');
    final name = (getValue('name') as String?) ?? '';
    final description = (getValue('description') as String?) ?? '';
    final unit = (getValue('unit') as String?) ?? '1kg, Price';

    final rawPrice = getValue('price');
    double price = 0.0;
    if (rawPrice is num) {
      price = rawPrice.toDouble();
    } else if (rawPrice is String) {
      final numStr = rawPrice.replaceAll(RegExp(r'[^0-9.]'), '');
      price = double.tryParse(numStr) ?? 0.0;
    }

    final image = (getValue('image') as String?) ?? '';
    final category = (getValue('category') as String?) ?? '';

    final rawRating = getValue('rating');
    final rating = rawRating is num
        ? rawRating.toDouble()
        : (double.tryParse(rawRating?.toString() ?? '') ?? 4.8);

    final rawReviews = getValue('reviewsCount') ?? getValue('reviews');
    final reviewsCount = rawReviews is num
        ? rawReviews.toInt()
        : (int.tryParse(rawReviews?.toString() ?? '') ?? 120);

    final nutritionInfo =
        (getValue('nutritionInfo') as String?) ?? '100gr ~ 52 kcal';
    final isExclusive = getValue('isExclusive') == true ||
        getValue('isExclusive')?.toString() == 'true';
    final isBestSelling = getValue('isBestSelling') == true ||
        getValue('isBestSelling')?.toString() == 'true';

    return ProductModel(
      id: id,
      name: name,
      description: description,
      unit: unit,
      price: price,
      image: image,
      category: category,
      rating: rating,
      reviewsCount: reviewsCount,
      nutritionInfo: nutritionInfo,
      isExclusive: isExclusive,
      isBestSelling: isBestSelling,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'unit': unit,
      'price': price,
      'image': image,
      'category': category,
      'rating': rating,
      'reviewsCount': reviewsCount,
      'nutritionInfo': nutritionInfo,
      'isExclusive': isExclusive,
      'isBestSelling': isBestSelling,
      'active': true,
    };
  }

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
