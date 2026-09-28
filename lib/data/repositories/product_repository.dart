import 'package:cloud_firestore/cloud_firestore.dart';
import '../dummy_data.dart';
import '../models/product_model.dart';

class ProductRepository {
  final FirebaseFirestore _firestore;

  ProductRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('products');

  Future<List<ProductModel>> getProducts() async {
    try {
      // First attempt: active products
      final snapshot = await _collection.where('active', isEqualTo: true).get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs
            .map((doc) => ProductModel.fromJson(doc.data(), doc.id))
            .toList();
      }

      // Second attempt: all products
      final allSnapshot = await _collection.get();
      if (allSnapshot.docs.isNotEmpty) {
        return allSnapshot.docs
            .map((doc) => ProductModel.fromJson(doc.data(), doc.id))
            .toList();
      }

      // Third attempt: seed if empty
      await seedDefaultProducts();
      final seeded = await _collection.get();
      if (seeded.docs.isNotEmpty) {
        return seeded.docs
            .map((doc) => ProductModel.fromJson(doc.data(), doc.id))
            .toList();
      }

      return DummyData.products;
    } catch (_) {
      return DummyData.products;
    }
  }

  Future<ProductModel?> getProduct(String productId) async {
    try {
      final doc = await _collection.doc(productId).get();
      if (!doc.exists || doc.data() == null) {
        return null;
      }
      return ProductModel.fromJson(doc.data()!, doc.id);
    } catch (_) {
      return null;
    }
  }

  Future<List<ProductModel>> getProductsByCategory(String categoryName) async {
    final all = await getProducts();
    final cleanCategory = categoryName.replaceAll('\n', ' ').toLowerCase().trim();

    return all.where((product) {
      final prodCat = product.category.toLowerCase().trim();
      return prodCat.contains(cleanCategory) || cleanCategory.contains(prodCat);
    }).toList();
  }

  Future<List<ProductModel>> getExclusiveProducts() async {
    final all = await getProducts();
    return all.where((p) => p.isExclusive).toList();
  }

  Future<List<ProductModel>> getBestSellingProducts() async {
    final all = await getProducts();
    return all.where((p) => p.isBestSelling).toList();
  }

  Stream<List<ProductModel>> productsStream() {
    return _collection.snapshots().map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return DummyData.products;
      }
      return snapshot.docs
          .map((doc) => ProductModel.fromJson(doc.data(), doc.id))
          .toList();
    });
  }

  Future<void> seedDefaultProducts() async {
    try {
      for (final p in DummyData.products) {
        await _collection.doc(p.id).set(p.toFirestore());
      }
    } catch (_) {}
  }
}