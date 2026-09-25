import 'dart:convert';
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

  factory AddressModel.fromJson(Map<String, dynamic> json) => AddressModel(
        id: json['id'] ?? '',
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

  factory PaymentCardModel.fromJson(Map<String, dynamic> json) =>
      PaymentCardModel(
        id: json['id'] ?? '',
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

  factory OrderModel.fromJson(Map<String, dynamic> json) => OrderModel(
        id: json['id'] ?? '',
        date: json['date'] ?? '',
        status: json['status'] ?? 'Delivered',
        items: (json['items'] as List<dynamic>?)
                ?.map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
        deliveryAddress: json['deliveryAddress'] ?? 'Home Address',
        paymentMethod: json['paymentMethod'] ?? 'Mastercard (ending 4242)',
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

  factory NotificationItemModel.fromJson(Map<String, dynamic> json) =>
      NotificationItemModel(
        id: json['id'] ?? '',
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

  // Notification toggles
  static const _keyNotifOrders = 'notif_orders';
  static const _keyNotifPromos = 'notif_promos';
  static const _keyNotifDelivery = 'notif_delivery';
  static const _keyNotifNewsletter = 'notif_newsletter';

  static final AccountStorageService _instance =
      AccountStorageService._internal();
  factory AccountStorageService() => _instance;
  AccountStorageService._internal();

  // ValueNotifier so UI can reactively update when profile changes
  final ValueNotifier<int> profileUpdateNotifier = ValueNotifier<int>(0);

  void notifyProfileChanged() {
    profileUpdateNotifier.value++;
  }

  // ==================== USER PROFILE ====================

  Future<Map<String, String>> getUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'name': prefs.getString(_keyUserName) ?? '',
      'phone': prefs.getString(_keyUserPhone) ?? '+1 234 567 8900',
      'gender': prefs.getString(_keyUserGender) ?? 'Prefer not to say',
      'dob': prefs.getString(_keyUserDob) ?? '15 May 1995',
      'avatar': prefs.getString(_keyUserAvatar) ?? '0',
    };
  }

  Future<void> saveUserProfile({
    String? name,
    String? phone,
    String? gender,
    String? dob,
    String? avatar,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (name != null) await prefs.setString(_keyUserName, name);
    if (phone != null) await prefs.setString(_keyUserPhone, phone);
    if (gender != null) await prefs.setString(_keyUserGender, gender);
    if (dob != null) await prefs.setString(_keyUserDob, dob);
    if (avatar != null) await prefs.setString(_keyUserAvatar, avatar);
    notifyProfileChanged();
  }

  // ==================== ADDRESSES ====================

  Future<List<AddressModel>> getAddresses() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keyAddresses);
    if (jsonStr == null || jsonStr.isEmpty) {
      final initial = _defaultAddresses;
      await saveAddresses(initial);
      return initial;
    }
    try {
      final list = jsonDecode(jsonStr) as List<dynamic>;
      return list.map((e) => AddressModel.fromJson(e)).toList();
    } catch (_) {
      return _defaultAddresses;
    }
  }

  Future<void> saveAddresses(List<AddressModel> addresses) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(addresses.map((e) => e.toJson()).toList());
    await prefs.setString(_keyAddresses, jsonStr);
  }

  Future<void> addAddress(AddressModel address) async {
    final list = await getAddresses();
    if (address.isDefault) {
      for (var i = 0; i < list.length; i++) {
        list[i] = list[i].copyWith(isDefault: false);
      }
    }
    list.insert(0, address);
    await saveAddresses(list);
  }

  Future<void> updateAddress(AddressModel updated) async {
    final list = await getAddresses();
    final index = list.indexWhere((e) => e.id == updated.id);
    if (index != -1) {
      if (updated.isDefault) {
        for (var i = 0; i < list.length; i++) {
          list[i] = list[i].copyWith(isDefault: false);
        }
      }
      list[index] = updated;
      await saveAddresses(list);
    }
  }

  Future<void> deleteAddress(String id) async {
    final list = await getAddresses();
    list.removeWhere((e) => e.id == id);
    if (list.isNotEmpty && !list.any((e) => e.isDefault)) {
      list[0] = list[0].copyWith(isDefault: true);
    }
    await saveAddresses(list);
  }

  Future<void> setDefaultAddress(String id) async {
    final list = await getAddresses();
    for (var i = 0; i < list.length; i++) {
      list[i] = list[i].copyWith(isDefault: list[i].id == id);
    }
    await saveAddresses(list);
  }

  static final List<AddressModel> _defaultAddresses = [
    AddressModel(
      id: 'addr_1',
      title: 'Home',
      recipientName: 'Alex Johnson',
      phone: '+1 (555) 234-5678',
      street: '742 Evergreen Terrace',
      city: 'Springfield',
      state: 'OR',
      zipCode: '97477',
      isDefault: true,
    ),
    AddressModel(
      id: 'addr_2',
      title: 'Work / Office',
      recipientName: 'Alex Johnson',
      phone: '+1 (555) 987-6543',
      street: '100 Innovation Way, Suite 400',
      city: 'Portland',
      state: 'OR',
      zipCode: '97201',
      isDefault: false,
    ),
  ];

  // ==================== PAYMENT METHODS ====================

  Future<List<PaymentCardModel>> getCards() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keyCards);
    if (jsonStr == null || jsonStr.isEmpty) {
      final initial = _defaultCards;
      await saveCards(initial);
      return initial;
    }
    try {
      final list = jsonDecode(jsonStr) as List<dynamic>;
      return list.map((e) => PaymentCardModel.fromJson(e)).toList();
    } catch (_) {
      return _defaultCards;
    }
  }

  Future<void> saveCards(List<PaymentCardModel> cards) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(cards.map((e) => e.toJson()).toList());
    await prefs.setString(_keyCards, jsonStr);
  }

  Future<void> addCard(PaymentCardModel card) async {
    final list = await getCards();
    if (card.isDefault) {
      for (var i = 0; i < list.length; i++) {
        list[i] = list[i].copyWith(isDefault: false);
      }
    }
    list.insert(0, card);
    await saveCards(list);
  }

  Future<void> deleteCard(String id) async {
    final list = await getCards();
    list.removeWhere((e) => e.id == id);
    if (list.isNotEmpty && !list.any((e) => e.isDefault)) {
      list[0] = list[0].copyWith(isDefault: true);
    }
    await saveCards(list);
  }

  Future<void> setDefaultCard(String id) async {
    final list = await getCards();
    for (var i = 0; i < list.length; i++) {
      list[i] = list[i].copyWith(isDefault: list[i].id == id);
    }
    await saveCards(list);
  }

  static final List<PaymentCardModel> _defaultCards = [
    PaymentCardModel(
      id: 'card_1',
      cardNumber: '5412 7534 8921 4242',
      cardHolder: 'ALEX JOHNSON',
      expiry: '12/28',
      cardType: 'Mastercard',
      isDefault: true,
    ),
    PaymentCardModel(
      id: 'card_2',
      cardNumber: '4242 4242 4242 8891',
      cardHolder: 'ALEX JOHNSON',
      expiry: '08/27',
      cardType: 'Visa',
      isDefault: false,
    ),
  ];

  // ==================== ORDERS ====================

  Future<List<OrderModel>> getOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keyOrders);
    if (jsonStr == null || jsonStr.isEmpty) {
      final initial = _defaultOrders;
      await saveOrders(initial);
      return initial;
    }
    try {
      final list = jsonDecode(jsonStr) as List<dynamic>;
      return list.map((e) => OrderModel.fromJson(e)).toList();
    } catch (_) {
      return _defaultOrders;
    }
  }

  Future<void> saveOrders(List<OrderModel> orders) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(orders.map((e) => e.toJson()).toList());
    await prefs.setString(_keyOrders, jsonStr);
  }

  Future<void> addOrder(OrderModel order) async {
    final list = await getOrders();
    list.insert(0, order);
    await saveOrders(list);
  }

  Future<void> cancelOrder(String id) async {
    final list = await getOrders();
    final index = list.indexWhere((e) => e.id == id);
    if (index != -1) {
      list[index] = list[index].copyWith(status: 'Cancelled');
      await saveOrders(list);
    }
  }

  static final List<OrderModel> _defaultOrders = [
    OrderModel(
      id: 'ORD-89241',
      date: 'Today, 11:30 AM',
      status: 'In Transit',
      deliveryAddress: '742 Evergreen Terrace, Springfield',
      paymentMethod: 'Mastercard ending in 4242',
      totalAmount: 18.96,
      items: [
        OrderItemModel(
          id: 'p_1',
          name: 'Organic Bananas',
          price: 4.99,
          quantity: 2,
          image:
              'https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e?w=400',
          unit: '7pcs, Priceg',
        ),
        OrderItemModel(
          id: 'p_2',
          name: 'Red Apple',
          price: 4.99,
          quantity: 1,
          image:
              'https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6?w=400',
          unit: '1kg, Priceg',
        ),
        OrderItemModel(
          id: 'p_3',
          name: 'Bell Pepper Red',
          price: 2.99,
          quantity: 1,
          image:
              'https://images.unsplash.com/photo-1563565375-f3fdfdbefa83?w=400',
          unit: '1kg, Priceg',
        ),
      ],
    ),
    OrderModel(
      id: 'ORD-76318',
      date: 'Yesterday, 04:15 PM',
      status: 'Delivered',
      deliveryAddress: '742 Evergreen Terrace, Springfield',
      paymentMethod: 'Visa ending in 8891',
      totalAmount: 26.97,
      items: [
        OrderItemModel(
          id: 'p_6',
          name: 'Broiler Chicken',
          price: 5.49,
          quantity: 2,
          image:
              'https://images.unsplash.com/photo-1587593810167-a84920ea0781?w=400',
          unit: '1kg, Priceg',
        ),
        OrderItemModel(
          id: 'p_9',
          name: 'Apple & Grape Juice',
          price: 15.99,
          quantity: 1,
          image:
              'https://images.unsplash.com/photo-1556881286-fc6915169721?w=400',
          unit: '2L, Price',
        ),
      ],
    ),
    OrderModel(
      id: 'ORD-65120',
      date: '20 Sep 2026, 02:40 PM',
      status: 'Delivered',
      deliveryAddress: '100 Innovation Way, Suite 400',
      paymentMethod: 'Mastercard ending in 4242',
      totalAmount: 11.47,
      items: [
        OrderItemModel(
          id: 'p_10',
          name: 'Fresh Farm Eggs',
          price: 3.49,
          quantity: 1,
          image:
              'https://images.unsplash.com/photo-1506976785307-8732e854ad03?w=400',
          unit: '12pcs, Price',
        ),
        OrderItemModel(
          id: 'p_5',
          name: 'Beef Bone',
          price: 7.99,
          quantity: 1,
          image:
              'https://images.unsplash.com/photo-1588168333986-5078d3ae3976?w=400',
          unit: '1kg, Priceg',
        ),
      ],
    ),
  ];

  // ==================== PROMO CARDS ====================

  List<PromoModel> getPromos() {
    return [
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
        description: 'Save 15% on dairy, artisan bakery and pasture-raised eggs.',
        discountPercent: 15,
        minSpend: 30.0,
        expiryDate: '25 Nov 2026',
      ),
    ];
  }

  // ==================== NOTIFICATIONS ====================

  Future<List<NotificationItemModel>> getNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keyNotifications);
    if (jsonStr == null || jsonStr.isEmpty) {
      final initial = _defaultNotifications;
      await saveNotifications(initial);
      return initial;
    }
    try {
      final list = jsonDecode(jsonStr) as List<dynamic>;
      return list.map((e) => NotificationItemModel.fromJson(e)).toList();
    } catch (_) {
      return _defaultNotifications;
    }
  }

  Future<void> saveNotifications(List<NotificationItemModel> items) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(items.map((e) => e.toJson()).toList());
    await prefs.setString(_keyNotifications, jsonStr);
  }

  Future<void> markNotificationAsRead(String id) async {
    final list = await getNotifications();
    final index = list.indexWhere((e) => e.id == id);
    if (index != -1) {
      list[index] = list[index].copyWith(isRead: true);
      await saveNotifications(list);
    }
  }

  Future<void> markAllNotificationsAsRead() async {
    final list = await getNotifications();
    final updated = list.map((e) => e.copyWith(isRead: true)).toList();
    await saveNotifications(updated);
  }

  Future<void> clearAllNotifications() async {
    await saveNotifications([]);
  }

  static final List<NotificationItemModel> _defaultNotifications = [
    NotificationItemModel(
      id: 'notif_1',
      title: 'Order Out for Delivery 🚚',
      message: 'Your order #ORD-89241 is on its way with driver David. Estimated arrival: 25 mins.',
      time: '15 mins ago',
      isRead: false,
      type: 'delivery',
    ),
    NotificationItemModel(
      id: 'notif_2',
      title: 'Special Weekend Discount! 🥑',
      message: 'Get 20% off on all organic vegetables with code FRESH20 this weekend.',
      time: '2 hours ago',
      isRead: false,
      type: 'promo',
    ),
    NotificationItemModel(
      id: 'notif_3',
      title: 'Order Delivered Successfully ✅',
      message: 'Order #ORD-76318 was delivered at your front door. Thanks for shopping with us!',
      time: 'Yesterday',
      isRead: true,
      type: 'order',
    ),
    NotificationItemModel(
      id: 'notif_4',
      title: 'Welcome to Fresh Basket! 🎉',
      message: 'We are thrilled to have you here. Explore our daily harvested produce and quick delivery.',
      time: '3 days ago',
      isRead: true,
      type: 'system',
    ),
  ];

  // Notification Preferences
  Future<Map<String, bool>> getNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'orders': prefs.getBool(_keyNotifOrders) ?? true,
      'promos': prefs.getBool(_keyNotifPromos) ?? true,
      'delivery': prefs.getBool(_keyNotifDelivery) ?? true,
      'newsletter': prefs.getBool(_keyNotifNewsletter) ?? false,
    };
  }

  Future<void> setNotificationSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    if (key == 'orders') await prefs.setBool(_keyNotifOrders, value);
    if (key == 'promos') await prefs.setBool(_keyNotifPromos, value);
    if (key == 'delivery') await prefs.setBool(_keyNotifDelivery, value);
    if (key == 'newsletter') await prefs.setBool(_keyNotifNewsletter, value);
  }
}
