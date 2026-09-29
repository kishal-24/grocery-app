import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/location/location_bloc.dart';
import '../../bloc/location/location_state.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/category_model.dart';
import '../../data/models/product_model.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/repositories/product_repository.dart';
import '../../widgets/banner_carousel.dart';
import '../../widgets/product_card.dart';
import '../../widgets/section_header.dart';
import '../shop/shop_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ProductRepository _productRepository = ProductRepository();
  final CategoryRepository _categoryRepository = CategoryRepository();

  List<ProductModel> _products = [];
  List<CategoryModel> _categories = [];

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        _productRepository.getProducts(),
        _categoryRepository.getCategories(),
      ]);

      if (!mounted) return;

      setState(() {
        _products = results[0] as List<ProductModel>;
        _categories = results[1] as List<CategoryModel>;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Loading state
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Error state
    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 50,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Could not load products',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textGrey,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                      _error = null;
                    });

                    _loadData();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Products loaded from Firestore
    final exclusiveProducts =
    _products.where((p) => p.isExclusive).toList();

    final bestSellingProducts =
    _products.where((p) => p.isBestSelling).toList();

    final beverages =
    _products.where((p) => p.category == 'Beverages').toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),

                // Header: Logo & Location
                Center(
                  child: Column(
                    children: [
                      const Icon(
                        Icons.eco,
                        color: AppColors.primaryGreen,
                        size: 32,
                      ),
                      const SizedBox(height: 6),
                      BlocBuilder<LocationBloc, LocationState>(
                        builder: (context, state) {
                          final locationText =
                              state.selectedLocation ?? 'Dhaka, Banasree';

                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.location_on,
                                size: 18,
                                color: AppColors.textDark,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                locationText,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const TextField(
                      decoration: InputDecoration(
                        hintText: 'Search Store',
                        hintStyle: TextStyle(
                          fontSize: 14,
                          color: AppColors.textGrey,
                          fontWeight: FontWeight.w500,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: AppColors.textDark,
                          size: 22,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Banner Carousel
                const BannerCarousel(),

                const SizedBox(height: 20),

                // =========================================================
                // EXCLUSIVE OFFER
                // =========================================================

                SectionHeader(
                  title: 'Exclusive Offer',
                  onSeeAll: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ShopScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 8),

                if (exclusiveProducts.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 20,
                    ),
                    child: Text(
                      'No exclusive products available.',
                      style: TextStyle(
                        color: AppColors.textGrey,
                      ),
                    ),
                  )
                else
                  SizedBox(
                    height: 245,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                      ),
                      scrollDirection: Axis.horizontal,
                      itemCount: exclusiveProducts.length,
                      separatorBuilder: (context, index) =>
                      const SizedBox(width: 14),
                      itemBuilder: (context, index) {
                        return ProductCard(
                          product: exclusiveProducts[index],
                          heroTag: 'exclusive_${exclusiveProducts[index].id}',
                        );
                      },
                    ),
                  ),

                const SizedBox(height: 24),

                // =========================================================
                // BEST SELLING
                // =========================================================

                SectionHeader(
                  title: 'Best Selling',
                  onSeeAll: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ShopScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 8),

                if (bestSellingProducts.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 20,
                    ),
                    child: Text(
                      'No best selling products available.',
                      style: TextStyle(
                        color: AppColors.textGrey,
                      ),
                    ),
                  )
                else
                  SizedBox(
                    height: 245,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                      ),
                      scrollDirection: Axis.horizontal,
                      itemCount: bestSellingProducts.length,
                      separatorBuilder: (context, index) =>
                      const SizedBox(width: 14),
                      itemBuilder: (context, index) {
                        return ProductCard(
                          product: bestSellingProducts[index],
                          heroTag: 'best_${bestSellingProducts[index].id}',
                        );
                      },
                    ),
                  ),

                const SizedBox(height: 24),

                // =========================================================
                // GROCERIES / CATEGORIES
                // =========================================================

                SectionHeader(
                  title: 'Groceries',
                  onSeeAll: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ShopScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 8),

                SizedBox(
                  height: 105,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                    ),
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    separatorBuilder: (context, index) =>
                    const SizedBox(width: 14),
                    itemBuilder: (context, index) {
                      final cat = _categories[index];

                      return InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CategoryProductsScreen(
                                category: cat,
                                products: _products,
                              ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          width: 240,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: cat.bgColor,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  cat.image,
                                  width: 65,
                                  height: 65,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (context, error, stackTrace) {
                                    return Icon(
                                      Icons.eco,
                                      color: cat.borderColor,
                                      size: 36,
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  cat.name.replaceAll('\n', ' '),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textDark,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // =========================================================
                // BEVERAGES
                // =========================================================

                if (beverages.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 20,
                    ),
                    child: Text(
                      'No beverage products available.',
                      style: TextStyle(
                        color: AppColors.textGrey,
                      ),
                    ),
                  )
                else
                  SizedBox(
                    height: 245,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                      ),
                      scrollDirection: Axis.horizontal,
                      itemCount: beverages.length,
                      separatorBuilder: (context, index) =>
                      const SizedBox(width: 14),
                      itemBuilder: (context, index) {
                        return ProductCard(
                          product: beverages[index],
                          heroTag: 'bev_${beverages[index].id}',
                        );
                      },
                    ),
                  ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}