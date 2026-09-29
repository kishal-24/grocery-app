import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'account_storage_service.dart';

class BackendService {
  static final BackendService _instance = BackendService._internal();
  factory BackendService() => _instance;
  BackendService._internal();

  static const String projectId = 'grocery-db70e';
  static const String region = 'us-central1';

  // Allows setting custom emulator URL or production URL
  static String? customBaseUrl;

  static String get baseUrl {
    if (customBaseUrl != null && customBaseUrl!.isNotEmpty) {
      return customBaseUrl!;
    }

    // If running in debug/local development and emulator is enabled
    // Default emulator mapping: Android emulator uses 10.0.2.2, desktop/web uses 127.0.0.1
    if (kDebugMode && !kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      // In development on Android emulator, can point to 10.0.2.2:5001
      // return 'http://10.0.2.2:5001/$projectId/$region';
    }

    return 'https://$region-$projectId.cloudfunctions.net';
  }

  /// Securely create an order by validating items, prices, promos, and stock on the server.
  Future<OrderModel?> createSecureOrder({
    required List<OrderItemModel> items,
    required String deliveryAddress,
    required String paymentMethod,
    String? deliverySpeed,
    String? promoCode,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('You must be logged in to place an order.');
    }

    final idToken = await user.getIdToken();

    final payload = {
      'items': items
          .map((i) => {
                'productId': i.id,
                'quantity': i.quantity,
              })
          .toList(),
      'deliveryAddress': deliveryAddress,
      'paymentMethod': paymentMethod,
      'deliverySpeed': deliverySpeed ?? 'Standard',
      if (promoCode != null && promoCode.isNotEmpty) 'promoCode': promoCode,
    };

    final url = Uri.parse('$baseUrl/createOrderApi');

    try {
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['order'] != null) {
          final serverOrderJson = Map<String, dynamic>.from(data['order']);
          final validatedOrder = OrderModel.fromJson(serverOrderJson, data['orderId']);
          return validatedOrder;
        }
      } else {
        final errorBody = jsonDecode(response.body);
        final errorMessage = errorBody['error'] ?? 'Server rejected order';
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is Exception && !e.toString().contains('Failed to connect') && !e.toString().contains('SocketException')) {
        rethrow;
      }
      // If server is unreachable (offline fallback for demo mode), log and rethrow
      debugPrint('BackendService createOrder error: $e');
      rethrow;
    }

    return null;
  }

  /// Securely cancel an order on the server.
  Future<bool> cancelSecureOrder(String orderId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('You must be logged in to cancel an order.');
    }

    final idToken = await user.getIdToken();
    final url = Uri.parse('$baseUrl/cancelOrderApi');

    try {
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
            body: jsonEncode({'orderId': orderId}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['error'] ?? 'Failed to cancel order');
      }
    } catch (e) {
      debugPrint('BackendService cancelOrder error: $e');
      rethrow;
    }
  }

  /// Resolve email from username via Cloud Function
  Future<String?> resolveUsername(String username) async {
    final url = Uri.parse('$baseUrl/resolveUsernameApi?username=${Uri.encodeComponent(username)}');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['email'] as String?;
      }
    } catch (_) {}
    return null;
  }
}
