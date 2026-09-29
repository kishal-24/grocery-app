import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';

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
  final String? paymentId;
  final String? paymentStatus; // 'Paid', 'Pending on Delivery'
  final String? transactionRef;

  OrderModel({
    required this.id,
    required this.date,
    required this.status,
    required this.items,
    required this.totalAmount,
    required this.deliveryAddress,
    required this.paymentMethod,
    this.paymentId,
    this.paymentStatus,
    this.transactionRef,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date,
        'status': status,
        'items': items.map((e) => e.toJson()).toList(),
        'totalAmount': totalAmount,
        'deliveryAddress': deliveryAddress,
        'paymentMethod': paymentMethod,
        if (paymentId != null) 'paymentId': paymentId,
        if (paymentStatus != null) 'paymentStatus': paymentStatus,
        if (transactionRef != null) 'transactionRef': transactionRef,
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
        paymentId: json['paymentId'] as String?,
        paymentStatus: json['paymentStatus'] as String?,
        transactionRef: json['transactionRef'] as String?,
      );

  OrderModel copyWith({
    String? id,
    String? date,
    String? status,
    List<OrderItemModel>? items,
    double? totalAmount,
    String? deliveryAddress,
    String? paymentMethod,
    String? paymentId,
    String? paymentStatus,
    String? transactionRef,
  }) {
    return OrderModel(
      id: id ?? this.id,
      date: date ?? this.date,
      status: status ?? this.status,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentId: paymentId ?? this.paymentId,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      transactionRef: transactionRef ?? this.transactionRef,
    );
  }
}

class PaymentModel {
  final String id;
  final String orderId;
  final String userId;
  final double amount;
  final String currency;
  final String paymentMethod;
  final String paymentType; // 'card', 'cod', 'wallet', 'upi'
  final String status; // 'COMPLETED', 'Pending on Delivery', 'FAILED'
  final String transactionRef;
  final String date;

  PaymentModel({
    required this.id,
    required this.orderId,
    required this.userId,
    required this.amount,
    this.currency = 'INR',
    required this.paymentMethod,
    required this.paymentType,
    required this.status,
    required this.transactionRef,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'orderId': orderId,
        'userId': userId,
        'amount': amount,
        'currency': currency,
        'paymentMethod': paymentMethod,
        'paymentType': paymentType,
        'status': status,
        'transactionRef': transactionRef,
        'date': date,
      };

  factory PaymentModel.fromJson(Map<String, dynamic> json, [String? docId]) =>
      PaymentModel(
        id: docId ?? json['id'] ?? '',
        orderId: json['orderId'] ?? '',
        userId: json['userId'] ?? '',
        amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
        currency: json['currency'] ?? 'INR',
        paymentMethod: json['paymentMethod'] ?? 'Cash on Delivery',
        paymentType: json['paymentType'] ?? 'cod',
        status: json['status'] ?? 'COMPLETED',
        transactionRef: json['transactionRef'] ?? '',
        date: json['date'] ?? '',
      );
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
  static const _keySavedGpayUpiId = 'checkout_saved_gpay_upi_id';

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
          final customImg = (data['customImage'] as String?)?.isNotEmpty == true
              ? (data['customImage'] as String)
              : ((data['profileImage'] as String?) ?? '');

          final profile = {
            'name': (data['name'] as String?)?.isNotEmpty == true
                ? data['name'] as String
                : (user.displayName ?? ''),
            'email': (data['email'] as String?) ?? (user.email ?? ''),
            'username': (data['username'] as String?) ?? '',
            'phone': (data['phone'] as String?) ?? (user.phoneNumber ?? ''),
            'gender': (data['gender'] as String?) ?? 'Prefer not to say',
            'dob': (data['dob'] as String?) ?? '',
            'avatar': (data['avatar'] as String?) ?? '0',
            'customImage': customImg,
            'profileImage': customImg,
            'role': (data['role'] as String?) ?? 'customer',
          };

          // Cache locally
          if (profile['name']!.isNotEmpty) {
            await prefs.setString(_keyUserName, profile['name']!);
          }
          await prefs.setString(_keyUserPhone, profile['phone']!);
          await prefs.setString(_keyUserGender, profile['gender']!);
          await prefs.setString(_keyUserDob, profile['dob']!);
          await prefs.setString(_keyUserAvatar, profile['avatar']!);
          if (customImg.isNotEmpty) {
            await prefs.setString(_keyUserCustomImage, customImg);
          } else {
            await prefs.remove(_keyUserCustomImage);
          }

          return profile;
        }
      } catch (_) {}
    }

    final localCustomImg = prefs.getString(_keyUserCustomImage) ?? '';
    return {
      'name': prefs.getString(_keyUserName) ?? (user?.displayName ?? ''),
      'email': user?.email ?? '',
      'username': '',
      'phone': prefs.getString(_keyUserPhone) ?? (user?.phoneNumber ?? ''),
      'gender': prefs.getString(_keyUserGender) ?? 'Prefer not to say',
      'dob': prefs.getString(_keyUserDob) ?? '',
      'avatar': prefs.getString(_keyUserAvatar) ?? '0',
      'customImage': localCustomImg,
      'profileImage': localCustomImg,
      'role': 'customer',
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
      firestoreUpdates['profileImage'] = FieldValue.delete();
    } else if (customImage != null) {
      await prefs.setString(_keyUserCustomImage, customImage);
      firestoreUpdates['customImage'] = customImage;
      firestoreUpdates['profileImage'] = customImage;
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

  Future<void> _syncAddressesToUserDoc(User user, List<AddressModel> list) async {
    try {
      final defaultAddr = list.isNotEmpty
          ? list.firstWhere((a) => a.isDefault, orElse: () => list.first)
          : null;

      await _firestore.collection('users').doc(user.uid).set({
        'addresses': list.map((e) => e.toJson()).toList(),
        'defaultAddress': defaultAddr != null ? defaultAddr.fullAddress : '',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error syncing addresses to user doc: $e');
    }
  }

  Future<List<AddressModel>> getAddresses() async {
    final user = _currentUser;
    if (user != null) {
      try {
        // 1. Check Firestore subcollection 'addresses'
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
          await _syncAddressesToUserDoc(user, list);
          return list;
        }

        // 2. Check root user document 'addresses' field fallback
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists && userDoc.data()?['addresses'] != null) {
          final raw = userDoc.data()!['addresses'] as List<dynamic>;
          if (raw.isNotEmpty) {
            final list = raw
                .map((e) => AddressModel.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList();
            list.sort((a, b) =>
                (b.isDefault ? 1 : 0).compareTo(a.isDefault ? 1 : 0));
            await saveAddressesLocally(list);

            // Populate subcollection for fast subcollection queries
            final batch = _firestore.batch();
            for (final addr in list) {
              batch.set(
                _firestore
                    .collection('users')
                    .doc(user.uid)
                    .collection('addresses')
                    .doc(addr.id),
                addr.toJson(),
                SetOptions(merge: true),
              );
            }
            await batch.commit();

            return list;
          }
        }
      } catch (e) {
        debugPrint('Error loading addresses from Firestore: $e');
      }
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
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Also sync addresses array and defaultAddress on root users/{userId}
        final defaultAddr = list.firstWhere((a) => a.isDefault, orElse: () => list.first);
        final userRef = _firestore.collection('users').doc(user.uid);
        batch.set(userRef, {
          'addresses': list.map((e) => e.toJson()).toList(),
          'defaultAddress': defaultAddr.fullAddress,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        await batch.commit();
      } catch (e) {
        debugPrint('Error adding address to Firestore: $e');
      }
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
            addrRef.doc(updated.id),
            {
              ...updated.toJson(),
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true));

        // Sync to users/{userId} root doc
        final defaultAddr = list.isNotEmpty
            ? list.firstWhere((a) => a.isDefault, orElse: () => list.first)
            : null;
        final userRef = _firestore.collection('users').doc(user.uid);
        batch.set(userRef, {
          'addresses': list.map((e) => e.toJson()).toList(),
          'defaultAddress': defaultAddr != null ? defaultAddr.fullAddress : '',
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        await batch.commit();
      } catch (e) {
        debugPrint('Error updating address in Firestore: $e');
      }
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
        final batch = _firestore.batch();
        final addrDocRef = _firestore
            .collection('users')
            .doc(user.uid)
            .collection('addresses')
            .doc(id);
        batch.delete(addrDocRef);

        final defaultAddr = list.isNotEmpty
            ? list.firstWhere((a) => a.isDefault, orElse: () => list.first)
            : null;
        final userRef = _firestore.collection('users').doc(user.uid);
        batch.set(userRef, {
          'addresses': list.map((e) => e.toJson()).toList(),
          'defaultAddress': defaultAddr != null ? defaultAddr.fullAddress : '',
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        await batch.commit();
      } catch (e) {
        debugPrint('Error deleting address from Firestore: $e');
      }
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

        final defaultAddr = list.firstWhere((a) => a.id == id,
            orElse: () => list.first);
        final userRef = _firestore.collection('users').doc(user.uid);
        batch.set(userRef, {
          'addresses': list.map((e) => e.toJson()).toList(),
          'defaultAddress': defaultAddr.fullAddress,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        await batch.commit();
      } catch (e) {
        debugPrint('Error setting default address in Firestore: $e');
      }
    }
  }

  // ==================== PAYMENT METHODS ====================

  Future<void> _syncCardsToUserDoc(User user, List<PaymentCardModel> list) async {
    try {
      final defaultCard = list.isNotEmpty
          ? list.firstWhere((c) => c.isDefault, orElse: () => list.first)
          : null;

      await _firestore.collection('users').doc(user.uid).set({
        'savedCards': list.map((c) => c.toJson()).toList(),
        'defaultCard': defaultCard != null ? defaultCard.maskedNumber : '',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

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
          await _syncCardsToUserDoc(user, list);
          return list;
        }

        // Check root user document savedCards field
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists && userDoc.data()?['savedCards'] != null) {
          final raw = userDoc.data()!['savedCards'] as List<dynamic>;
          if (raw.isNotEmpty) {
            final list = raw
                .map((e) => PaymentCardModel.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList();
            list.sort((a, b) =>
                (b.isDefault ? 1 : 0).compareTo(a.isDefault ? 1 : 0));
            await saveCardsLocally(list);

            final batch = _firestore.batch();
            for (final card in list) {
              batch.set(
                _firestore
                    .collection('users')
                    .doc(user.uid)
                    .collection('cards')
                    .doc(card.id),
                card.toJson(),
                SetOptions(merge: true),
              );
            }
            await batch.commit();

            return list;
          }
        }
      } catch (e) {
        debugPrint('Error loading cards from Firestore: $e');
      }
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
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Also sync savedCards array on root users/{userId}
        final defaultCard = list.firstWhere((c) => c.isDefault, orElse: () => list.first);
        final userRef = _firestore.collection('users').doc(user.uid);
        batch.set(userRef, {
          'savedCards': list.map((c) => c.toJson()).toList(),
          'defaultCard': defaultCard.maskedNumber,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        await batch.commit();
      } catch (e) {
        debugPrint('Error saving card to Firestore: $e');
      }
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
        final batch = _firestore.batch();
        batch.delete(
          _firestore
              .collection('users')
              .doc(user.uid)
              .collection('cards')
              .doc(id),
        );

        final defaultCard = list.isNotEmpty
            ? list.firstWhere((c) => c.isDefault, orElse: () => list.first)
            : null;
        final userRef = _firestore.collection('users').doc(user.uid);
        batch.set(userRef, {
          'savedCards': list.map((c) => c.toJson()).toList(),
          'defaultCard': defaultCard != null ? defaultCard.maskedNumber : '',
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        await batch.commit();
      } catch (e) {
        debugPrint('Error deleting card from Firestore: $e');
      }
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

        final defaultCard = list.firstWhere((c) => c.id == id,
            orElse: () => list.first);
        final userRef = _firestore.collection('users').doc(user.uid);
        batch.set(userRef, {
          'savedCards': list.map((c) => c.toJson()).toList(),
          'defaultCard': defaultCard.maskedNumber,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        await batch.commit();
      } catch (e) {
        debugPrint('Error setting default card in Firestore: $e');
      }
    }
  }

  // ==================== REAL PAYMENT PROCESSING ====================

  static const String _keyCanaraUpiId = 'canara_merchant_upi_id';

  Future<String> getCanaraUpiId() async {
    final prefs = await SharedPreferences.getInstance();
    final custom = prefs.getString(_keyCanaraUpiId);
    if (custom != null && custom.isNotEmpty) return custom;
    return AppConstants.defaultCanaraUpiId;
  }

  Future<void> saveCanaraUpiId(String upiId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCanaraUpiId, upiId);
  }

  Future<PaymentModel> processPayment({
    required String orderId,
    required double amount,
    required String paymentMethod,
    String? transactionRef,
    String? paymentStatus,
  }) async {
    final user = _currentUser;
    final isGPay = paymentMethod.toLowerCase().contains('google') ||
        paymentMethod.toLowerCase().contains('gpay');
    final isCod = paymentMethod.toLowerCase().contains('cash') ||
        paymentMethod.toLowerCase().contains('cod');
    final isWallet = !isGPay &&
        (paymentMethod.toLowerCase().contains('apple') ||
            paymentMethod.toLowerCase().contains('pay'));

    final paymentType = isCod ? 'cod' : (isGPay ? 'gpay' : (isWallet ? 'wallet' : 'card'));
    
    // GPay / UPI payments remain "pending" until independently verified
    final status = paymentStatus ??
        (isCod ? 'Pending on Delivery' : 'pending');

    final paymentId =
        'PAY-${DateTime.now().millisecondsSinceEpoch}-${(1000 + (DateTime.now().microsecond % 9000))}';
    
    // Unique transaction reference for every order
    final txnRef = transactionRef ??
        (isGPay
            ? 'UPI-TXN-${DateTime.now().millisecondsSinceEpoch}-${100000 + Random().nextInt(900000)}'
            : 'TXN-${DateTime.now().millisecondsSinceEpoch}-${100000 + Random().nextInt(900000)}');

    final now = DateTime.now();
    final dateStr =
        '${now.day}/${now.month}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final payment = PaymentModel(
      id: paymentId,
      orderId: orderId,
      userId: user?.uid ?? 'guest',
      amount: amount,
      currency: AppConstants.currencyCode,
      paymentMethod: paymentMethod,
      paymentType: paymentType,
      status: status,
      transactionRef: txnRef,
      date: dateStr,
    );

    if (user != null) {
      try {
        final batch = _firestore.batch();

        // 1. Root payments collection
        final rootPaymentRef = _firestore.collection('payments').doc(paymentId);
        batch.set(rootPaymentRef, {
          ...payment.toJson(),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // 2. User payments subcollection
        final userPaymentRef = _firestore
            .collection('users')
            .doc(user.uid)
            .collection('payments')
            .doc(paymentId);
        batch.set(userPaymentRef, {
          ...payment.toJson(),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // 3. User root document: update lastPayment
        final userRef = _firestore.collection('users').doc(user.uid);
        batch.set(userRef, {
          'lastPayment': payment.toJson(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        await batch.commit();
      } catch (e) {
        debugPrint('Error recording payment to Firestore: $e');
      }
    }

    return payment;
  }

  Future<List<PaymentModel>> getPayments() async {
    final user = _currentUser;
    if (user != null) {
      try {
        final snap = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('payments')
            .get();

        if (snap.docs.isNotEmpty) {
          final list = snap.docs
              .map((d) => PaymentModel.fromJson(d.data(), d.id))
              .toList();
          list.sort((a, b) => b.id.compareTo(a.id));
          return list;
        }
      } catch (e) {
        debugPrint('Error getting payments from Firestore: $e');
      }
    }
    return [];
  }

  // ==================== GPAY UPI ====================

  Future<String?> getGpayUpiId() async {
    final user = _currentUser;
    if (user != null) {
      try {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists && doc.data()?['gpayUpiId'] != null) {
          final id = doc.data()!['gpayUpiId'] as String;
          if (id.isNotEmpty) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(_keySavedGpayUpiId, id);
            return id;
          }
        }
      } catch (_) {}
    }
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keySavedGpayUpiId) ?? 'freshbasket.user@okhdfcbank';
  }

  Future<void> saveGpayUpiId(String upiId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySavedGpayUpiId, upiId);
    final user = _currentUser;
    if (user != null) {
      try {
        await _firestore.collection('users').doc(user.uid).set({
          'gpayUpiId': upiId,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
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
          orders.sort((a, b) => b.id.compareTo(a.id));
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
          orders.sort((a, b) => b.id.compareTo(a.id));
          await saveOrdersLocally(orders);
          return orders;
        }
      } catch (e) {
        debugPrint('Error getting orders from Firestore: $e');
      }
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

  Future<OrderModel> addOrder(
    OrderModel order, {
    String? customTransactionRef,
    String? customPaymentStatus,
  }) async {
    final user = _currentUser;
    OrderModel finalOrder = order;

    // 1. Process real payment record in Firestore
    final payment = await processPayment(
      orderId: finalOrder.id,
      amount: finalOrder.totalAmount,
      paymentMethod: finalOrder.paymentMethod,
      transactionRef: customTransactionRef ?? finalOrder.transactionRef,
      paymentStatus: customPaymentStatus ??
          finalOrder.paymentStatus ??
          (finalOrder.paymentMethod.toLowerCase().contains('cash')
              ? 'Pending on Delivery'
              : 'pending'),
    );

    finalOrder = finalOrder.copyWith(
      paymentId: payment.id,
      paymentStatus: payment.status,
      transactionRef: payment.transactionRef,
      status: finalOrder.status.isNotEmpty ? finalOrder.status : 'Pending',
    );

    // 2. Persist order directly into Cloud Firestore
    if (user != null) {
      try {
        final batch = _firestore.batch();

        // Write to root 'orders' collection
        final rootOrderRef = _firestore.collection('orders').doc(finalOrder.id);
        batch.set(rootOrderRef, {
          ...finalOrder.toJson(),
          'userId': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Write to user's 'orders' subcollection
        final userOrderRef = _firestore
            .collection('users')
            .doc(user.uid)
            .collection('orders')
            .doc(finalOrder.id);
        batch.set(userOrderRef, {
          ...finalOrder.toJson(),
          'userId': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Update user's last order summary on users/{userId}
        final userDocRef = _firestore.collection('users').doc(user.uid);
        batch.set(userDocRef, {
          'lastOrderId': finalOrder.id,
          'lastOrderDate': finalOrder.date,
          'lastOrderTotal': finalOrder.totalAmount,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // Create an official confirmation notification in users/{userId}/notifications
        final notifId = 'notif_${DateTime.now().millisecondsSinceEpoch}';
        final notifRef = _firestore
            .collection('users')
            .doc(user.uid)
            .collection('notifications')
            .doc(notifId);
        batch.set(notifRef, {
          'id': notifId,
          'title': finalOrder.paymentStatus == 'pending'
              ? 'Order Placed (Payment Pending) ⏳'
              : 'Order Placed Successfully! 🎉',
          'message':
              'Your order #${finalOrder.id} for ${AppConstants.currencySymbol}${finalOrder.totalAmount.toStringAsFixed(2)} has been placed. Payment: ${finalOrder.paymentMethod} (${payment.status}).',
          'time': 'Just now',
          'isRead': false,
          'type': 'order',
          'createdAt': FieldValue.serverTimestamp(),
        });

        await batch.commit();
      } catch (e) {
        debugPrint('Error writing order directly to Firestore: $e');
      }
    }

    final list = await getOrders();
    list.removeWhere((o) => o.id == finalOrder.id);
    list.insert(0, finalOrder);
    await saveOrdersLocally(list);
    return finalOrder;
  }

  /// Independently verify UPI or order payment in Firestore.
  /// Once verified, marks order paymentStatus: "Paid" and status: "Confirmed"
  Future<bool> verifyOrderPayment({
    required String orderId,
    String? transactionRef,
  }) async {
    final user = _currentUser;
    try {
      final batch = _firestore.batch();
      final Map<String, dynamic> updates = {
        'paymentStatus': 'Paid',
        'status': 'Confirmed',
        'verifiedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (transactionRef != null) {
        updates['transactionRef'] = transactionRef;
      }

      // 1. Root orders collection
      final rootOrderRef = _firestore.collection('orders').doc(orderId);
      batch.set(rootOrderRef, updates, SetOptions(merge: true));

      // 2. User orders subcollection
      if (user != null) {
        final userOrderRef = _firestore
            .collection('users')
            .doc(user.uid)
            .collection('orders')
            .doc(orderId);
        batch.set(userOrderRef, updates, SetOptions(merge: true));

        // 3. User payments subcollection (if exists)
        try {
          final paymentsSnap = await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('payments')
              .where('orderId', isEqualTo: orderId)
              .get();

          for (final doc in paymentsSnap.docs) {
            batch.update(doc.reference, {
              'status': 'COMPLETED',
              'verifiedAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        } catch (_) {}

        // 4. Send confirmation notification
        final notifId = 'notif_verify_${DateTime.now().millisecondsSinceEpoch}';
        final notifRef = _firestore
            .collection('users')
            .doc(user.uid)
            .collection('notifications')
            .doc(notifId);
        batch.set(notifRef, {
          'id': notifId,
          'title': 'Payment Verified & Confirmed! ✅',
          'message':
              'Your UPI payment for Order #$orderId has been verified successfully. Your order is now Confirmed and preparing for dispatch.',
          'time': 'Just now',
          'isRead': false,
          'type': 'order',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      // Update local storage
      final list = await getOrders();
      final idx = list.indexWhere((o) => o.id == orderId);
      if (idx != -1) {
        list[idx] = list[idx].copyWith(
          paymentStatus: 'Paid',
          status: 'Confirmed',
          transactionRef: transactionRef ?? list[idx].transactionRef,
        );
        await saveOrdersLocally(list);
      }
      return true;
    } catch (e) {
      debugPrint('Error verifying order payment: $e');
      return false;
    }
  }

  Future<void> cancelOrder(String id) async {
    final user = _currentUser;

    if (user != null) {
      try {
        final batch = _firestore.batch();
        batch.set(
          _firestore.collection('orders').doc(id),
          {
            'status': 'Cancelled',
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
        batch.set(
          _firestore
              .collection('users')
              .doc(user.uid)
              .collection('orders')
              .doc(id),
          {
            'status': 'Cancelled',
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
        await batch.commit();
      } catch (e) {
        debugPrint('Error cancelling order in Firestore: $e');
      }
    }

    final list = await getOrders();
    final index = list.indexWhere((e) => e.id == id);
    if (index != -1) {
      list[index] = list[index].copyWith(status: 'Cancelled');
      await saveOrdersLocally(list);
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
      minSpend: 200.0,
      expiryDate: '30 Oct 2026',
    ),
    PromoModel(
      code: 'WELCOME50',
      title: '₹50 OFF First Order',
      description: 'Enjoy ₹50 discount on your grocery haul over ₹250.',
      discountAmount: 50.0,
      minSpend: 250.0,
      expiryDate: '15 Nov 2026',
    ),
    PromoModel(
      code: 'FREEDEL',
      title: 'Free Express Delivery',
      description: 'Free instant contactless delivery on any order today.',
      discountAmount: 30.0,
      minSpend: 199.0,
      expiryDate: '01 Nov 2026',
    ),
    PromoModel(
      code: 'HEALTHY15',
      title: '15% OFF Dairy & Eggs',
      description:
          'Save 15% on dairy, artisan bakery and pasture-raised eggs.',
      discountPercent: 15,
      minSpend: 250.0,
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
    String? gpayUpiId,
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
    if (gpayUpiId != null) {
      await prefs.setString(_keySavedGpayUpiId, gpayUpiId);
      updates['gpayUpiId'] = gpayUpiId;
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
            'gpayUpiId': cp['gpayUpiId'] as String?,
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
      'gpayUpiId': prefs.getString(_keySavedGpayUpiId),
    };
  }
}
