import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/product_model.dart';
import 'cart_event.dart';
import 'cart_state.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  StreamSubscription<User?>? _authSubscription;

  CartBloc() : super(const CartState(items: [], favorites: [])) {
    on<LoadCartAndFavoritesEvent>(_onLoadCartAndFavorites);
    on<AddToCartEvent>(_onAddToCart);
    on<UpdateQuantityEvent>(_onUpdateQuantity);
    on<RemoveFromCartEvent>(_onRemoveFromCart);
    on<ClearCartEvent>(_onClearCart);
    on<ToggleFavoriteEvent>(_onToggleFavorite);

    // Initial load from Firestore
    add(const LoadCartAndFavoritesEvent());

    // Listen to authentication changes and reload user cart/favorites
    _authSubscription = _auth.authStateChanges().listen((_) {
      add(const LoadCartAndFavoritesEvent());
    });
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }

  Future<void> _onLoadCartAndFavorites(
      LoadCartAndFavoritesEvent event, Emitter<CartState> emit) async {
    final user = _auth.currentUser;
    if (user == null) {
      emit(state.copyWith(items: const [], favorites: const []));
      return;
    }

    try {
      // 1. Fetch Cart from Firestore
      final cartSnap = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('cart')
          .get();

      List<CartItem> loadedItems = [];
      for (final doc in cartSnap.docs) {
        final data = doc.data();
        final rawProd = data['product'] as Map<String, dynamic>? ?? data;
        final product = ProductModel.fromJson(rawProd, doc.id);
        final quantity = (data['quantity'] as num?)?.toInt() ?? 1;
        loadedItems.add(CartItem(product: product, quantity: quantity));
      }

      // 2. Fetch Favorites from Firestore
      final favSnap = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .get();

      List<ProductModel> loadedFavs = [];
      for (final doc in favSnap.docs) {
        final data = doc.data();
        final product = ProductModel.fromJson(data, doc.id);
        loadedFavs.add(product);
      }

      emit(state.copyWith(items: loadedItems, favorites: loadedFavs));
    } catch (_) {}
  }

  Future<void> _onAddToCart(
      AddToCartEvent event, Emitter<CartState> emit) async {
    final existingIndex =
        state.items.indexWhere((item) => item.product.id == event.product.id);

    List<CartItem> updatedItems = List.from(state.items);
    int newQuantity = event.quantity;
    if (existingIndex >= 0) {
      final current = updatedItems[existingIndex];
      newQuantity = current.quantity + event.quantity;
      updatedItems[existingIndex] = current.copyWith(quantity: newQuantity);
    } else {
      updatedItems.add(CartItem(
        product: event.product,
        quantity: event.quantity,
      ));
    }

    emit(state.copyWith(items: updatedItems));

    // Sync to Firestore
    final user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('cart')
            .doc(event.product.id)
            .set({
          'quantity': newQuantity,
          'product': event.product.toFirestore(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (_) {}
    }
  }

  Future<void> _onUpdateQuantity(
      UpdateQuantityEvent event, Emitter<CartState> emit) async {
    List<CartItem> updatedItems = [];
    CartItem? targetItem;

    for (final item in state.items) {
      if (item.product.id == event.productId) {
        if (event.quantity > 0) {
          final updated = item.copyWith(quantity: event.quantity);
          updatedItems.add(updated);
          targetItem = updated;
        }
      } else {
        updatedItems.add(item);
      }
    }
    emit(state.copyWith(items: updatedItems));

    // Sync to Firestore
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final docRef = _firestore
            .collection('users')
            .doc(user.uid)
            .collection('cart')
            .doc(event.productId);

        if (event.quantity > 0 && targetItem != null) {
          await docRef.set({
            'quantity': event.quantity,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        } else {
          await docRef.delete();
        }
      } catch (_) {}
    }
  }

  Future<void> _onRemoveFromCart(
      RemoveFromCartEvent event, Emitter<CartState> emit) async {
    final updatedItems = state.items
        .where((item) => item.product.id != event.productId)
        .toList();
    emit(state.copyWith(items: updatedItems));

    // Sync to Firestore
    final user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('cart')
            .doc(event.productId)
            .delete();
      } catch (_) {}
    }
  }

  Future<void> _onClearCart(
      ClearCartEvent event, Emitter<CartState> emit) async {
    emit(state.copyWith(items: const []));

    // Sync to Firestore
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final snap = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('cart')
            .get();

        final batch = _firestore.batch();
        for (final doc in snap.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      } catch (_) {}
    }
  }

  Future<void> _onToggleFavorite(
      ToggleFavoriteEvent event, Emitter<CartState> emit) async {
    final isFav = state.isFavorite(event.product.id);
    List<ProductModel> updatedFavs = List.from(state.favorites);

    if (isFav) {
      updatedFavs.removeWhere((p) => p.id == event.product.id);
    } else {
      updatedFavs.add(event.product);
    }

    emit(state.copyWith(favorites: updatedFavs));

    // Sync to Firestore
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final docRef = _firestore
            .collection('users')
            .doc(user.uid)
            .collection('favorites')
            .doc(event.product.id);

        if (isFav) {
          await docRef.delete();
        } else {
          await docRef.set({
            ...event.product.toFirestore(),
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      } catch (_) {}
    }
  }
}
