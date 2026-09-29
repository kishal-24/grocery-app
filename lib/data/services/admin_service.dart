import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/product_model.dart';
import 'account_storage_service.dart';

class AdminService {
  static final AdminService _instance = AdminService._internal();
  factory AdminService() => _instance;
  AdminService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== DASHBOARD METRICS ====================

  Future<Map<String, dynamic>> getDashboardMetrics() async {
    double totalRevenue = 0.0;
    int totalOrders = 0;
    int pendingUpiCount = 0;
    int activeOrdersCount = 0;
    int lowStockCount = 0;
    int totalProducts = 0;

    try {
      final ordersSnap = await _firestore.collection('orders').get();
      totalOrders = ordersSnap.docs.length;

      for (final doc in ordersSnap.docs) {
        final data = doc.data();
        final amount = (data['totalAmount'] as num?)?.toDouble() ?? 0.0;
        final status = (data['status'] as String? ?? '').toLowerCase();
        final paymentStatus =
            (data['paymentStatus'] as String? ?? '').toLowerCase();

        // Revenue counts paid or delivered orders
        if (paymentStatus == 'paid' || status == 'delivered') {
          totalRevenue += amount;
        }

        // Pending UPI payments requiring admin verification
        if (paymentStatus == 'pending' && status != 'cancelled') {
          pendingUpiCount++;
        }

        // Active orders (in progress)
        if (status == 'pending' ||
            status == 'confirmed' ||
            status == 'processing' ||
            status == 'in transit') {
          activeOrdersCount++;
        }
      }

      final productsSnap = await _firestore.collection('products').get();
      totalProducts = productsSnap.docs.length;

      for (final doc in productsSnap.docs) {
        final stock = (doc.data()['stock'] as num?)?.toInt() ?? 10;
        if (stock <= 5) {
          lowStockCount++;
        }
      }
    } catch (e) {
      debugPrint('Error getting admin dashboard metrics: $e');
    }

    return {
      'totalRevenue': totalRevenue,
      'totalOrders': totalOrders,
      'pendingUpiCount': pendingUpiCount,
      'activeOrdersCount': activeOrdersCount,
      'totalProducts': totalProducts,
      'lowStockCount': lowStockCount,
    };
  }

  // ==================== ORDERS MANAGEMENT ====================

  Stream<List<OrderModel>> streamAllOrders() {
    return _firestore
        .collection('orders')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => OrderModel.fromJson(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => b.id.compareTo(a.id));
      return list;
    });
  }

  Future<List<OrderModel>> getAllOrders() async {
    try {
      final snapshot = await _firestore.collection('orders').get();
      final list = snapshot.docs
          .map((doc) => OrderModel.fromJson(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => b.id.compareTo(a.id));
      return list;
    } catch (e) {
      debugPrint('Error getting all orders: $e');
      return [];
    }
  }

  Future<bool> updateOrderStatus(String orderId, String newStatus) async {
    try {
      final batch = _firestore.batch();
      final rootRef = _firestore.collection('orders').doc(orderId);
      final orderSnap = await rootRef.get();
      final userId = orderSnap.data()?['userId'] as String?;

      final Map<String, dynamic> updates = {
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (newStatus == 'Confirmed' || newStatus == 'Delivered') {
        // If order confirmed, ensure payment is noted
        final currentPaymentStatus =
            orderSnap.data()?['paymentStatus'] as String?;
        if (currentPaymentStatus == 'pending') {
          updates['paymentStatus'] = 'Paid';
        }
      }

      batch.set(rootRef, updates, SetOptions(merge: true));

      if (userId != null && userId.isNotEmpty) {
        final userOrderRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('orders')
            .doc(orderId);
        batch.set(userOrderRef, updates, SetOptions(merge: true));

        // Create status update notification
        final notifId = 'notif_status_${DateTime.now().millisecondsSinceEpoch}';
        final notifRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('notifications')
            .doc(notifId);
        batch.set(notifRef, {
          'id': notifId,
          'title': 'Order Update: $newStatus 🚚',
          'message': 'Your order #$orderId has been updated to "$newStatus".',
          'time': 'Just now',
          'isRead': false,
          'type': 'order',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      return true;
    } catch (e) {
      debugPrint('Error updating order status: $e');
      return false;
    }
  }

  Future<bool> verifyUpiPayment(String orderId, String? transactionRef) async {
    return await AccountStorageService().verifyOrderPayment(
      orderId: orderId,
      transactionRef: transactionRef,
    );
  }

  // ==================== PRODUCTS CATALOG CRUD ====================

  Stream<List<ProductModel>> streamProducts() {
    return _firestore.collection('products').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => ProductModel.fromJson(doc.data(), doc.id))
          .toList();
    });
  }

  Future<List<ProductModel>> getAllProducts() async {
    try {
      final snapshot = await _firestore.collection('products').get();
      return snapshot.docs
          .map((doc) => ProductModel.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('Error getting all products: $e');
      return [];
    }
  }

  Future<bool> saveProduct(ProductModel product, {int stock = 50}) async {
    try {
      final docId = product.id.isNotEmpty
          ? product.id
          : 'prod_${DateTime.now().millisecondsSinceEpoch}';

      final Map<String, dynamic> data = {
        'id': docId,
        'name': product.name,
        'description': product.description,
        'unit': product.unit,
        'price': product.price,
        'image': product.image,
        'category': product.category,
        'rating': product.rating,
        'reviewsCount': product.reviewsCount,
        'nutritionInfo': product.nutritionInfo,
        'isExclusive': product.isExclusive,
        'isBestSelling': product.isBestSelling,
        'stock': stock,
        'active': true,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('products').doc(docId).set(
            data,
            SetOptions(merge: true),
          );
      return true;
    } catch (e) {
      debugPrint('Error saving product: $e');
      return false;
    }
  }

  Future<bool> updateProductStock(String productId, int newStock) async {
    try {
      await _firestore.collection('products').doc(productId).set({
        'stock': newStock,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return true;
    } catch (e) {
      debugPrint('Error updating stock: $e');
      return false;
    }
  }

  Future<bool> deleteProduct(String productId) async {
    try {
      await _firestore.collection('products').doc(productId).delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting product: $e');
      return false;
    }
  }

  // ==================== PROMO CODES CRUD ====================

  Future<List<PromoModel>> getAllPromos() async {
    return await AccountStorageService().fetchPromos();
  }

  Future<bool> savePromo(PromoModel promo) async {
    try {
      await _firestore.collection('promos').doc(promo.code).set({
        ...promo.toJson(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('Error saving promo: $e');
      return false;
    }
  }

  Future<bool> deletePromo(String code) async {
    try {
      await _firestore.collection('promos').doc(code).delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting promo: $e');
      return false;
    }
  }

  // ==================== CANARA UPI CONFIGURATION ====================

  Future<String> getCanaraUpiId() async {
    return await AccountStorageService().getCanaraUpiId();
  }

  Future<void> saveCanaraUpiId(String upiId) async {
    await AccountStorageService().saveCanaraUpiId(upiId);
  }
}
