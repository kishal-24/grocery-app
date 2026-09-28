import 'package:cloud_firestore/cloud_firestore.dart';
import '../dummy_data.dart';
import '../models/category_model.dart';

class CategoryRepository {
  final FirebaseFirestore _firestore;

  CategoryRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('categories');

  Future<List<CategoryModel>> getCategories() async {
    try {
      final snapshot = await _collection.get();
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs
            .map((doc) => CategoryModel.fromJson(doc.data(), doc.id))
            .toList();
      }

      // If empty in Firestore, seed with default categories
      await seedDefaultCategories();
      final seededSnapshot = await _collection.get();
      return seededSnapshot.docs
          .map((doc) => CategoryModel.fromJson(doc.data(), doc.id))
          .toList();
    } catch (_) {
      // Fallback in case of network issue
      return DummyData.categories;
    }
  }

  Stream<List<CategoryModel>> categoriesStream() {
    return _collection.snapshots().map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return DummyData.categories;
      }
      return snapshot.docs
          .map((doc) => CategoryModel.fromJson(doc.data(), doc.id))
          .toList();
    });
  }

  Future<void> seedDefaultCategories() async {
    try {
      for (final cat in DummyData.categories) {
        await _collection.doc(cat.id).set(cat.toFirestore());
      }
    } catch (_) {}
  }
}
