import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/location/location_bloc.dart';
import '../../bloc/location/location_state.dart';
import '../../core/constants/app_colors.dart';
import '../../data/dummy_data.dart';
import '../../widgets/banner_carousel.dart';
import '../../widgets/product_card.dart';
import '../../widgets/section_header.dart';
import '../shop/shop_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final exclusiveProducts =
        DummyData.products.where((p) => p.isExclusive).toList();
    final bestSellingProducts =
        DummyData.products.where((p) => p.isBestSelling).toList();
    final beverages =
        DummyData.products.where((p) => p.category == 'Beverages').toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
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
                        final locationText = state.selectedLocation ?? 'Dhaka, Banasree';
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
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Banner Carousel
              const BannerCarousel(),

              const SizedBox(height: 20),

              // Exclusive Offer Section
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
              SizedBox(
                height: 245,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  scrollDirection: Axis.horizontal,
                  itemCount: exclusiveProducts.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 14),
                  itemBuilder: (context, index) {
                    return ProductCard(product: exclusiveProducts[index]);
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Best Selling Section
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
              SizedBox(
                height: 245,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  scrollDirection: Axis.horizontal,
                  itemCount: bestSellingProducts.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 14),
                  itemBuilder: (context, index) {
                    return ProductCard(product: bestSellingProducts[index]);
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Groceries / Categories Pill Row
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
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  scrollDirection: Axis.horizontal,
                  itemCount: DummyData.categories.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 14),
                  itemBuilder: (context, index) {
                    final cat = DummyData.categories[index];
                    return Container(
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
                              errorBuilder: (context, error, stackTrace) => Icon(
                                Icons.eco,
                                color: cat.borderColor,
                                size: 36,
                              ),
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
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Groceries Product list
              SizedBox(
                height: 245,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  scrollDirection: Axis.horizontal,
                  itemCount: beverages.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 14),
                  itemBuilder: (context, index) {
                    return ProductCard(product: beverages[index]);
                  },
                ),
              ),


              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
