import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddressModel {
  final String id;
  final String title;
  final String recipientName;
  final String phone;
  final String street;
  final String city;
  final String state;
  final String zipCode;
  final bool isDefault;

  AddressModel({
    required this.id,
    required this.title,
    required this.recipientName,
    required this.phone,
    required this.street,
    required this.city,
    required this.state,
    required this.zipCode,
    this.isDefault = false,
  });

  String get fullAddress => '$street, $city, $state $zipCode';

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'recipientName': recipientName,
        'phone': phone,
        'street': street,
        'city': city,
        'state': state,
        'zipCode': zipCode,
        'isDefault': isDefault,
      };

  factory AddressModel.fromJson(Map<String, dynamic> json, [String? docId]) =>
      AddressModel(
        id: docId ?? json['id'] ?? '',
        title: json['title'] ?? 'Home',
        recipientName: json['recipientName'] ?? '',
        phone: json['phone'] ?? '',
        street: json['street'] ?? '',
        city: json['city'] ?? '',
        state: json['state'] ?? '',
        zipCode: json['zipCode'] ?? '',
        isDefault: json['isDefault'] ?? false,
      );

  AddressModel copyWith({
    String? id,
    String? title,
    String? recipientName,
    String? phone,
    String? street,
    String? city,
    String? state,
    String? zipCode,
    bool? isDefault,
  }) {
    return AddressModel(
      id: id ?? this.id,
      title: title ?? this.title,
      recipientName: recipientName ?? this.recipientName,
      phone: phone ?? this.phone,
      street: street ?? this.street,
      city: city ?? this.city,
      state: state ?? this.state,
      zipCode: zipCode ?? this.zipCode,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}

class PaymentCardModel {
  final String id;
  final String cardNumber;
  final String cardHolder;
  final String expiry;
  final String cardType;
  final bool isDefault;

  PaymentCardModel({
    required this.id,
    required this.cardNumber,
    required this.cardHolder,
    required this.expiry,
    required this.cardType,
    this.isDefault = false,
  });

  String get maskedNumber {
    final clean = cardNumber.replaceAll(' ', '');
    if (clean.length < 4) return clean;
    final last4 = clean.substring(clean.length - 4);
    return '•••• •••• •••• $last4';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'cardNumber': cardNumber,
        'cardHolder': cardHolder,
        'expiry': expiry,
        'cardType': cardType,
        'isDefault': isDefault,
      };

  factory PaymentCardModel.fromJson(Map<String, dynamic> json, [String? docId]) =>
      PaymentCardModel(
        id: docId ?? json['id'] ?? '',
        cardNumber: json['cardNumber'] ?? '',
        cardHolder: json['cardHolder'] ?? '',
        expiry: json['expiry'] ?? '',
        cardType: json['cardType'] ?? 'Visa',
        isDefault: json['isDefault'] ?? false,
      );

  PaymentCardModel copyWith({
    String? id,
    String? cardNumber,
    String? cardHolder,
    String? expiry,
    String? cardType,
    bool? isDefault,
  }) {
    return PaymentCardModel(
      id: id ?? this.id,
      cardNumber: cardNumber ?? this.cardNumber,
      cardHolder: cardHolder ?? this.cardHolder,
      expiry: expiry ?? this.expiry,
      cardType: cardType ?? this.cardType,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}

class OrderItemModel {
  final String id;
  final String name;
  final double price;
  final int quantity;
  final String image;
  final String unit;

  OrderItemModel({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    required this.image,
    required this.unit,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'price': price,
        'quantity': quantity,
        'image': image,
        'unit': unit,
      };

  factory OrderItemModel.fromJson(Map<String, dynamic> json) => OrderItemModel(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        price: (json['price'] as num?)?.toDouble() ?? 0.0,
        quantity: json['quantity'] ?? 1,
        image: json['image'] ?? '',
        unit: json['unit'] ?? '',
      );
}

class OrderModel {
  final String id;
  final String date;
  final String status; // 'Processing', 'In Transit', 'Delivered', 'Cancelled'
  final List<OrderItemModel> items;
  final double totalAmount;
  final String deliveryAddress;
  final String paymentMethod;

  OrderModel({
    required this.id,
    required this.date,
    required this.status,
    required this.items,
    required this.totalAmount,
    required this.deliveryAddress,
    required this.paymentMethod,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date,
        'status': status,
        'items': items.map((e) => e.toJson()).toList(),
        'totalAmount': totalAmount,
        'deliveryAddress': deliveryAddress,
        'paymentMethod': paymentMethod,
      };

  factory OrderModel.fromJson(Map<String, dynamic> json, [String? docId]) =>
      OrderModel(
        id: docId ?? json['id'] ?? '',
        date: json['date'] ?? '',
        status: json['status'] ?? 'Delivered',
        items: (json['items'] as List<dynamic>?)
                ?.map((e) => OrderItemModel.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList() ??
            [],
        totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
        deliveryAddress: json['deliveryAddress'] ?? 'Home Address',
        paymentMethod: json['paymentMethod'] ?? 'Cash on Delivery',
      );

  OrderModel copyWith({
    String? id,
    String? date,
    String? status,
    List<OrderItemModel>? items,
    double? totalAmount,
    String? deliveryAddress,
    String? paymentMethod,
  }) {
    return OrderModel(
      id: id ?? this.id,
      date: date ?? this.date,
      status: status ?? this.status,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      paymentMethod: paymentMethod ?? this.paymentMethod,
    );
  }
}

class PromoModel {
  final String code;
  final String title;
  final String description;
  final double discountAmount;
  final int discountPercent;
  final double minSpend;
  final String expiryDate;

  PromoModel({
    required this.code,
    required this.title,
    required this.description,
    this.discountAmount = 0,
    this.discountPercent = 0,
    required this.minSpend,
    required this.expiryDate,
  });

  Map<String, dynamic> toJson() => {
        'code': code,
        'title': title,
        'description': description,
        'discountAmount': discountAmount,
        'discountPercent': discountPercent,
        'minSpend': minSpend,
        'expiryDate': expiryDate,
      };

  factory PromoModel.fromJson(Map<String, dynamic> json, [String? docId]) =>
      PromoModel(
        code: docId ?? json['code'] ?? '',
        title: json['title'] ?? '',
        description: json['description'] ?? '',
        discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0.0,
        discountPercent: (json['discountPercent'] as num?)?.toInt() ?? 0,
        minSpend: (json['minSpend'] as num?)?.toDouble() ?? 0.0,
        expiryDate: json['expiryDate'] ?? '',
      );
}

class NotificationItemModel {
  final String id;
  final String title;
  final String message;
  final String time;
  final bool isRead;
  final String type; // 'order', 'promo', 'delivery', 'system'

  NotificationItemModel({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    this.isRead = false,
    required this.type,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'message': message,
        'time': time,
        'isRead': isRead,
        'type': type,
      };

  factory NotificationItemModel.fromJson(
          Map<String, dynamic> json, [String? docId]) =>
      NotificationItemModel(
        id: docId ?? json['id'] ?? '',
        title: json['title'] ?? '',
        message: json['message'] ?? '',
        time: json['time'] ?? '',
        isRead: json['isRead'] ?? false,
        type: json['type'] ?? 'system',
      );

  NotificationItemModel copyWith({bool? isRead}) {
    return NotificationItemModel(
      id: id,
      title: title,
      message: message,
      time: time,
      isRead: isRead ?? this.isRead,
      type: type,
    );
  }
}

class AccountStorageService {
  static const _keyAddresses = 'account_addresses';
  static const _keyCards = 'account_cards';
  static const _keyOrders = 'account_orders';
  static const _keyNotifications = 'account_notifications';
  static const _keyUserName = 'account_user_name';
  static const _keyUserPhone = 'account_user_phone';
  static const _keyUserGender = 'account_user_gender';
  static const _keyUserDob = 'account_user_dob';
  static const _keyUserAvatar = 'account_user_avatar';
  static const _keyUserCustomImage = 'account_user_custom_image';

  // Notification toggles
  static const _keyNotifOrders = 'notif_orders';
  static const _keyNotifPromos = 'notif_promos';
  static const _keyNotifDelivery = 'notif_delivery';
  static const _keyNotifNewsletter = 'notif_newsletter';

  // Saved Checkout Preferences
  static const _keySavedCheckoutAddressId = 'checkout_saved_address_id';
  static const _keySavedCheckoutSpeed = 'checkout_saved_speed';
  static const _keySavedCheckoutPaymentMethod = 'checkout_saved_payment_method';
  static const _keySavedCheckoutPaymentIconCode =
      'checkout_saved_payment_icon_code';

  static final AccountStorageService _instance =
      AccountStorageService._internal();
  factory AccountStorageService() => _instance;
  AccountStorageService._internal();

  bool get _isFirebaseReady {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  FirebaseFirestore? _customFirestore;
  FirebaseFirestore get _firestore =>
      _customFirestore ?? FirebaseFirestore.instance;

  User? get _currentUser {
    if (!_isFirebaseReady) return null;
    try {
      return FirebaseAuth.instance.currentUser;
    } catch (_) {
      return null;
    }
  }

  // ValueNotifier so UI can reactively update when profile changes
  final ValueNotifier<int> profileUpdateNotifier = ValueNotifier<int>(0);

  void notifyProfileChanged() {
    profileUpdateNotifier.value++;
  }

  // ==================== USER PROFILE ====================

  Future<Map<String, String>> getUserProfile() async {
    final user = _currentUser;
    final prefs = await SharedPreferences.getInstance();

    if (user != null) {
      try {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          final profile = {
            'name': (data['name'] as String?)?.isNotEmpty == true
                ? data['name'] as String
                : (user.displayName ?? ''),
            'email': (data['email'] as String?) ?? (user.email ?? ''),
            'phone': (data['phone'] as String?) ??
                (user.phoneNumber ?? '+1 234 567 8900'),
            'gender': (data['gender'] as String?) ?? 'Prefer not to say',
            'dob': (data['dob'] as String?) ?? '15 May 1995',
            'avatar': (data['avatar'] as String?) ?? '0',
            'customImage': (data['customImage'] as String?) ?? '',
          };

          // Cache locally
          if (profile['name']!.isNotEmpty) {
            await prefs.setString(_keyUserName, profile['name']!);
          }
          await prefs.setString(_keyUserPhone, profile['phone']!);
          await prefs.setString(_keyUserGender, profile['gender']!);
          await prefs.setString(_keyUserDob, profile['dob']!);
          await prefs.setString(_keyUserAvatar, profile['avatar']!);
          if (profile['customImage']!.isNotEmpty) {
            await prefs.setString(_keyUserCustomImage, profile['customImage']!);
          }

          return profile;
        }
      } catch (_) {}
    }

    return {
      'name': prefs.getString(_keyUserName) ?? (user?.displayName ?? ''),
      'email': user?.email ?? '',
      'phone': prefs.getString(_keyUserPhone) ??
          (user?.phoneNumber ?? '+1 234 567 8900'),
      'gender': prefs.getString(_keyUserGender) ?? 'Prefer not to say',
      'dob': prefs.getString(_keyUserDob) ?? '15 May 1995',
      'avatar': prefs.getString(_keyUserAvatar) ?? '0',
      'customImage': prefs.getString(_keyUserCustomImage) ?? '',
    };
  }

  Future<void> saveUserProfile({
    String? name,
    String? phone,
    String? gender,
    String? dob,
    String? avatar,
    String? customImage,
    bool clearCustomImage = false,
  }) async {
    final user = _currentUser;
    final prefs = await SharedPreferences.getInstance();

    final Map<String, dynamic> firestoreUpdates = {
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (name != null) {
      await prefs.setString(_keyUserName, name);
      firestoreUpdates['name'] = name;
      try {
        await user?.updateDisplayName(name);
      } catch (_) {}
    }
    if (phone != null) {
      await prefs.setString(_keyUserPhone, phone);
      firestoreUpdates['phone'] = phone;
    }
    if (gender != null) {
      await prefs.setString(_keyUserGender, gender);
      firestoreUpdates['gender'] = gender;
    }
    if (dob != null) {
      await prefs.setString(_keyUserDob, dob);
      firestoreUpdates['dob'] = dob;
    }
    if (avatar != null) {
      await prefs.setString(_keyUserAvatar, avatar);
      firestoreUpdates['avatar'] = avatar;
    }
    if (clearCustomImage || customImage == '') {
      await prefs.remove(_keyUserCustomImage);
      firestoreUpdates['customImage'] = '';
    } else if (customImage != null) {
      await prefs.setString(_keyUserCustomImage, customImage);
      firestoreUpdates['customImage'] = customImage;
    }

    if (user != null) {
      try {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .set(firestoreUpdates, SetOptions(merge: true));
      } catch (_) {}
    }

    notifyProfileChanged();
  }

  // ==================== ADDRESSES ====================

  Future<List<AddressModel>> getAddresses() async {
    final user = _currentUser;
    if (user != null) {
      try {
        final snap = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('addresses')
            .get();

        if (snap.docs.isNotEmpty) {
          final list = snap.docs
              .map((d) => AddressModel.fromJson(d.data(), d.id))
              .toList();
          list.sort((a, b) =>
              (b.isDefault ? 1 : 0).compareTo(a.isDefault ? 1 : 0));
          await saveAddressesLocally(list);
          return list;
        }
      } catch (_) {}
    }

    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keyAddresses);
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final list = (jsonDecode(jsonStr) as List<dynamic>)
            .map((e) => AddressModel.fromJson(e as Map<String, dynamic>))
            .toList();
        return list;
      } catch (_) {}
    }

    return [];
  }

  Future<void> saveAddressesLocally(List<AddressModel> addresses) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(addresses.map((e) => e.toJson()).toList());
    await prefs.setString(_keyAddresses, jsonStr);
  }

  Future<void> addAddress(AddressModel address) async {
    final user = _currentUser;
    final list = await getAddresses();

    if (address.isDefault) {
      for (var i = 0; i < list.length; i++) {
        list[i] = list[i].copyWith(isDefault: false);
      }
    }
    list.insert(0, address);
    await saveAddressesLocally(list);

    if (user != null) {
      try {
        final batch = _firestore.batch();
        final addrRef = _firestore
            .collection('users')
            .doc(user.uid)
            .collection('addresses');

        if (address.isDefault) {
          for (final existing in list) {
            if (existing.id != address.id) {
              batch.set(addrRef.doc(existing.id), {'isDefault': false},
                  SetOptions(merge: true));
            }
          }
        }

        batch.set(addrRef.doc(address.id), {
          ...address.toJson(),
          'createdAt': FieldValue.serverTimestamp(),
        });

        await batch.commit();
      } catch (_) {}
    }
  }

  Future<void> updateAddress(AddressModel updated) async {
    final user = _currentUser;
    final list = await getAddresses();
    final index = list.indexWhere((e) => e.id == updated.id);
    if (index != -1) {
      if (updated.isDefault) {
        for (var i = 0; i < list.length; i++) {
          list[i] = list[i].copyWith(isDefault: false);
        }
      }
      list[index] = updated;
      await saveAddressesLocally(list);
    }

    if (user != null) {
      try {
        final batch = _firestore.batch();
        final addrRef = _firestore
            .collection('users')
            .doc(user.uid)
            .collection('addresses');

        if (updated.isDefault) {
          for (final a in list) {
            if (a.id != updated.id) {
              batch.set(addrRef.doc(a.id), {'isDefault': false},
                  SetOptions(merge: true));
            }
          }
        }

        batch.set(
            addrRef.doc(updated.id), updated.toJson(), SetOptions(merge: true));
        await batch.commit();
      } catch (_) {}
    }
  }

  Future<void> deleteAddress(String id) async {
    final user = _currentUser;
    final list = await getAddresses();
    list.removeWhere((e) => e.id == id);
    if (list.isNotEmpty && !list.any((e) => e.isDefault)) {
      list[0] = list[0].copyWith(isDefault: true);
    }
    await saveAddressesLocally(list);

    if (user != null) {
      try {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('addresses')
            .doc(id)
            .delete();
      } catch (_) {}
    }
  }

  Future<void> setDefaultAddress(String id) async {
    final user = _currentUser;
    final list = await getAddresses();
    for (var i = 0; i < list.length; i++) {
      list[i] = list[i].copyWith(isDefault: list[i].id == id);
    }
    await saveAddressesLocally(list);

    if (user != null) {
      try {
        final batch = _firestore.batch();
        final addrRef = _firestore
            .collection('users')
            .doc(user.uid)
            .collection('addresses');

        for (final a in list) {
          batch.set(addrRef.doc(a.id), {'isDefault': a.id == id},
              SetOptions(merge: true));
        }
        await batch.commit();
      } catch (_) {}
    }
  }

  // ==================== PAYMENT METHODS ====================

  Future<List<PaymentCardModel>> getCards() async {
    final user = _currentUser;
    if (user != null) {
      try {
        final snap = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('cards')
            .get();

        if (snap.docs.isNotEmpty) {
          final list = snap.docs
              .map((d) => PaymentCardModel.fromJson(d.data(), d.id))
              .toList();
          list.sort((a, b) =>
              (b.isDefault ? 1 : 0).compareTo(a.isDefault ? 1 : 0));
          await saveCardsLocally(list);
          return list;
        }
      } catch (_) {}
    }

    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keyCards);
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final list = (jsonDecode(jsonStr) as List<dynamic>)
            .map((e) => PaymentCardModel.fromJson(e as Map<String, dynamic>))
            .toList();
        return list;
      } catch (_) {}
    }

    return [];
  }

  Future<void> saveCardsLocally(List<PaymentCardModel> cards) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(cards.map((e) => e.toJson()).toList());
    await prefs.setString(_keyCards, jsonStr);
  }

  Future<void> addCard(PaymentCardModel card) async {
    final user = _currentUser;
    final list = await getCards();
    if (card.isDefault) {
      for (var i = 0; i < list.length; i++) {
        list[i] = list[i].copyWith(isDefault: false);
      }
    }
    list.insert(0, card);
    await saveCardsLocally(list);

    if (user != null) {
      try {
        final batch = _firestore.batch();
        final cardRef = _firestore
            .collection('users')
            .doc(user.uid)
            .collection('cards');

        if (card.isDefault) {
          for (final existing in list) {
            if (existing.id != card.id) {
              batch.set(cardRef.doc(existing.id), {'isDefault': false},
                  SetOptions(merge: true));
            }
          }
        }

        batch.set(cardRef.doc(card.id), {
          ...card.toJson(),
          'createdAt': FieldValue.serverTimestamp(),
        });
        await batch.commit();
      } catch (_) {}
    }
  }

  Future<void> deleteCard(String id) async {
    final user = _currentUser;
    final list = await getCards();
    list.removeWhere((e) => e.id == id);
    if (list.isNotEmpty && !list.any((e) => e.isDefault)) {
      list[0] = list[0].copyWith(isDefault: true);
    }
    await saveCardsLocally(list);

    if (user != null) {
      try {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('cards')
            .doc(id)
            .delete();
      } catch (_) {}
    }
  }

  Future<void> setDefaultCard(String id) async {
    final user = _currentUser;
    final list = await getCards();
    for (var i = 0; i < list.length; i++) {
      list[i] = list[i].copyWith(isDefault: list[i].id == id);
    }
    await saveCardsLocally(list);

    if (user != null) {
      try {
        final batch = _firestore.batch();
        final cardRef = _firestore
            .collection('users')
            .doc(user.uid)
            .collection('cards');

        for (final c in list) {
          batch.set(cardRef.doc(c.id), {'isDefault': c.id == id},
              SetOptions(merge: true));
        }
        await batch.commit();
      } catch (_) {}
    }
  }

  // ==================== ORDERS ====================

  Future<List<OrderModel>> getOrders() async {
    final user = _currentUser;
    if (user != null) {
      try {
        final snap = await _firestore
            .collection('orders')
            .where('userId', isEqualTo: user.uid)
            .get();

        if (snap.docs.isNotEmpty) {
          final orders = snap.docs
              .map((d) => OrderModel.fromJson(d.data(), d.id))
              .toList();
          await saveOrdersLocally(orders);
          return orders;
        }

        // Also check user subcollection fallback
        final subSnap = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('orders')
            .get();

        if (subSnap.docs.isNotEmpty) {
          final orders = subSnap.docs
              .map((d) => OrderModel.fromJson(d.data(), d.id))
              .toList();
          await saveOrdersLocally(orders);
          return orders;
        }
      } catch (_) {}
    }

    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keyOrders);
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        return (jsonDecode(jsonStr) as List<dynamic>)
            .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }

    return [];
  }

  Future<void> saveOrdersLocally(List<OrderModel> orders) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(orders.map((e) => e.toJson()).toList());
    await prefs.setString(_keyOrders, jsonStr);
  }

  Future<void> addOrder(OrderModel order) async {
    final user = _currentUser;
    final list = await getOrders();
    list.insert(0, order);
    await saveOrdersLocally(list);

    if (user != null) {
      try {
        final orderData = {
          ...order.toJson(),
          'userId': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
        };

        // Write to root 'orders' collection
        await _firestore.collection('orders').doc(order.id).set(orderData);

        // Also write to user subcollection
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('orders')
            .doc(order.id)
            .set(orderData);

        // Automatically trigger an in-app notification in Firestore
        final notif = NotificationItemModel(
          id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
          title: 'Order Placed Successfully! 🎉',
          message:
              'Your order #${order.id} for \$${order.totalAmount.toStringAsFixed(2)} has been placed and is being prepared.',
          time: 'Just now',
          isRead: false,
          type: 'order',
        );
        await addNotification(notif);
      } catch (_) {}
    }
  }

  Future<void> cancelOrder(String id) async {
    final user = _currentUser;
    final list = await getOrders();
    final index = list.indexWhere((e) => e.id == id);
    if (index != -1) {
      list[index] = list[index].copyWith(status: 'Cancelled');
      await saveOrdersLocally(list);
    }

    if (user != null) {
      try {
        await _firestore
            .collection('orders')
            .doc(id)
            .set({'status': 'Cancelled'}, SetOptions(merge: true));

        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('orders')
            .doc(id)
            .set({'status': 'Cancelled'}, SetOptions(merge: true));

        // Create cancellation notification
        final notif = NotificationItemModel(
          id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
          title: 'Order Cancelled 🚫',
          message: 'Order #$id has been cancelled.',
          time: 'Just now',
          isRead: false,
          type: 'order',
        );
        await addNotification(notif);
      } catch (_) {}
    }
  }

  // ==================== PROMO CARDS ====================

  List<PromoModel> _cachedPromos = [];

  List<PromoModel> getPromos() {
    if (_cachedPromos.isNotEmpty) {
      return _cachedPromos;
    }
    // Fetch in background to populate cache
    fetchPromos();
    return _defaultPromos;
  }

  Future<List<PromoModel>> fetchPromos() async {
    if (!_isFirebaseReady) {
      return _cachedPromos.isNotEmpty ? _cachedPromos : _defaultPromos;
    }
    try {
      final snap = await _firestore.collection('promos').get();
      if (snap.docs.isNotEmpty) {
        _cachedPromos = snap.docs
            .map((d) => PromoModel.fromJson(d.data(), d.id))
            .toList();
        return _cachedPromos;
      }

      // If empty in Firestore, seed and return defaults
      for (final p in _defaultPromos) {
        await _firestore.collection('promos').doc(p.code).set(p.toJson());
      }
      _cachedPromos = List.from(_defaultPromos);
      return _cachedPromos;
    } catch (_) {
      return _cachedPromos.isNotEmpty ? _cachedPromos : _defaultPromos;
    }
  }

  static final List<PromoModel> _defaultPromos = [
    PromoModel(
      code: 'FRESH20',
      title: '20% OFF Fresh Produce',
      description: 'Get 20% off on all organic vegetables and fresh fruits.',
      discountPercent: 20,
      minSpend: 25.0,
      expiryDate: '30 Oct 2026',
    ),
    PromoModel(
      code: 'WELCOME10',
      title: '\$10 OFF First Order',
      description: 'Enjoy \$10 discount on your grocery haul over \$40.',
      discountAmount: 10.0,
      minSpend: 40.0,
      expiryDate: '15 Nov 2026',
    ),
    PromoModel(
      code: 'FREEDEL',
      title: 'Free Express Delivery',
      description: 'Free instant contactless delivery on any order today.',
      discountAmount: 5.0,
      minSpend: 20.0,
      expiryDate: '01 Nov 2026',
    ),
    PromoModel(
      code: 'HEALTHY15',
      title: '15% OFF Dairy & Eggs',
      description:
          'Save 15% on dairy, artisan bakery and pasture-raised eggs.',
      discountPercent: 15,
      minSpend: 30.0,
      expiryDate: '25 Nov 2026',
    ),
  ];

  // ==================== NOTIFICATIONS ====================

  Future<List<NotificationItemModel>> getNotifications() async {
    final user = _currentUser;
    if (user != null) {
      try {
        final snap = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('notifications')
            .get();

        if (snap.docs.isNotEmpty) {
          final list = snap.docs
              .map((d) => NotificationItemModel.fromJson(d.data(), d.id))
              .toList();
          await saveNotificationsLocally(list);
          return list;
        }
      } catch (_) {}
    }

    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keyNotifications);
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        return (jsonDecode(jsonStr) as List<dynamic>)
            .map((e) =>
                NotificationItemModel.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }

    return [];
  }

  Future<void> saveNotificationsLocally(
      List<NotificationItemModel> items) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(items.map((e) => e.toJson()).toList());
    await prefs.setString(_keyNotifications, jsonStr);
  }

  Future<void> addNotification(NotificationItemModel item) async {
    final user = _currentUser;
    final list = await getNotifications();
    list.insert(0, item);
    await saveNotificationsLocally(list);

    if (user != null) {
      try {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('notifications')
            .doc(item.id)
            .set({
          ...item.toJson(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {}
    }
  }

  Future<void> markNotificationAsRead(String id) async {
    final user = _currentUser;
    final list = await getNotifications();
    final index = list.indexWhere((e) => e.id == id);
    if (index != -1) {
      list[index] = list[index].copyWith(isRead: true);
      await saveNotificationsLocally(list);
    }

    if (user != null) {
      try {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('notifications')
            .doc(id)
            .set({'isRead': true}, SetOptions(merge: true));
      } catch (_) {}
    }
  }

  Future<void> markAllNotificationsAsRead() async {
    final user = _currentUser;
    final list = await getNotifications();
    final updated = list.map((e) => e.copyWith(isRead: true)).toList();
    await saveNotificationsLocally(updated);

    if (user != null) {
      try {
        final batch = _firestore.batch();
        final ref = _firestore
            .collection('users')
            .doc(user.uid)
            .collection('notifications');

        for (final notif in updated) {
          batch.set(ref.doc(notif.id), {'isRead': true},
              SetOptions(merge: true));
        }
        await batch.commit();
      } catch (_) {}
    }
  }

  Future<void> clearAllNotifications() async {
    final user = _currentUser;
    await saveNotificationsLocally([]);

    if (user != null) {
      try {
        final snap = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('notifications')
            .get();

        final batch = _firestore.batch();
        for (final doc in snap.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      } catch (_) {}
    }
  }

  // ==================== NOTIFICATION SETTINGS ====================

  Future<Map<String, bool>> getNotificationSettings() async {
    final user = _currentUser;
    if (user != null) {
      try {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists && doc.data()?['notifSettings'] != null) {
          final s = Map<String, dynamic>.from(doc.data()!['notifSettings']);
          return {
            'orders': s['orders'] as bool? ?? true,
            'promos': s['promos'] as bool? ?? true,
            'delivery': s['delivery'] as bool? ?? true,
            'newsletter': s['newsletter'] as bool? ?? false,
          };
        }
      } catch (_) {}
    }

    final prefs = await SharedPreferences.getInstance();
    return {
      'orders': prefs.getBool(_keyNotifOrders) ?? true,
      'promos': prefs.getBool(_keyNotifPromos) ?? true,
      'delivery': prefs.getBool(_keyNotifDelivery) ?? true,
      'newsletter': prefs.getBool(_keyNotifNewsletter) ?? false,
    };
  }

  Future<void> setNotificationSetting(String key, bool value) async {
    final user = _currentUser;
    final prefs = await SharedPreferences.getInstance();
    if (key == 'orders') await prefs.setBool(_keyNotifOrders, value);
    if (key == 'promos') await prefs.setBool(_keyNotifPromos, value);
    if (key == 'delivery') await prefs.setBool(_keyNotifDelivery, value);
    if (key == 'newsletter') await prefs.setBool(_keyNotifNewsletter, value);

    if (user != null) {
      try {
        await _firestore.collection('users').doc(user.uid).set({
          'notifSettings': {
            key: value,
          },
        }, SetOptions(merge: true));
      } catch (_) {}
    }
  }

  // ==================== CHECKOUT PREFERENCES ====================

  Future<void> saveCheckoutPreferences({
    String? addressId,
    String? deliverySpeed,
    String? paymentMethod,
    int? paymentIconCode,
  }) async {
    final user = _currentUser;
    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> updates = {};

    if (addressId != null) {
      await prefs.setString(_keySavedCheckoutAddressId, addressId);
      updates['addressId'] = addressId;
    }
    if (deliverySpeed != null) {
      await prefs.setString(_keySavedCheckoutSpeed, deliverySpeed);
      updates['deliverySpeed'] = deliverySpeed;
    }
    if (paymentMethod != null) {
      await prefs.setString(_keySavedCheckoutPaymentMethod, paymentMethod);
      updates['paymentMethod'] = paymentMethod;
    }
    if (paymentIconCode != null) {
      await prefs.setInt(_keySavedCheckoutPaymentIconCode, paymentIconCode);
      updates['paymentIconCode'] = paymentIconCode;
    }

    if (user != null && updates.isNotEmpty) {
      try {
        await _firestore.collection('users').doc(user.uid).set({
          'checkoutPreferences': updates,
        }, SetOptions(merge: true));
      } catch (_) {}
    }
  }

  Future<Map<String, dynamic>> getSavedCheckoutPreferences() async {
    final user = _currentUser;
    if (user != null) {
      try {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists && doc.data()?['checkoutPreferences'] != null) {
          final cp =
              Map<String, dynamic>.from(doc.data()!['checkoutPreferences']);
          return {
            'addressId': cp['addressId'] as String?,
            'deliverySpeed': cp['deliverySpeed'] as String?,
            'paymentMethod': cp['paymentMethod'] as String?,
            'paymentIconCode': cp['paymentIconCode'] as int?,
          };
        }
      } catch (_) {}
    }

    final prefs = await SharedPreferences.getInstance();
    return {
      'addressId': prefs.getString(_keySavedCheckoutAddressId),
      'deliverySpeed': prefs.getString(_keySavedCheckoutSpeed),
      'paymentMethod': prefs.getString(_keySavedCheckoutPaymentMethod),
      'paymentIconCode': prefs.getInt(_keySavedCheckoutPaymentIconCode),
    };
  }
}
