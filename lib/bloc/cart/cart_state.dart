import 'package:equatable/equatable.dart';
import '../../data/models/product_model.dart';

class CartItem extends Equatable {
  final ProductModel product;
  final int quantity;

  const CartItem({
    required this.product,
    required this.quantity,
  });

  double get totalPrice => product.price * quantity;

  CartItem copyWith({
    ProductModel? product,
    int? quantity,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }

  @override
  List<Object?> get props => [product, quantity];
}

class CartState extends Equatable {
  final List<CartItem> items;
  final List<ProductModel> favorites;

  const CartState({
    this.items = const [],
    this.favorites = const [],
  });

  double get subtotal =>
      items.fold(0.0, (sum, item) => sum + item.totalPrice);

  int get totalItemCount =>
      items.fold(0, (sum, item) => sum + item.quantity);

  bool isFavorite(String productId) {
    return favorites.any((p) => p.id == productId);
  }

  int getQuantity(String productId) {
    final item = items.where((i) => i.product.id == productId);
    return item.isEmpty ? 0 : item.first.quantity;
  }

  CartState copyWith({
    List<CartItem>? items,
    List<ProductModel>? favorites,
  }) {
    return CartState(
      items: items ?? this.items,
      favorites: favorites ?? this.favorites,
    );
  }

  @override
  List<Object?> get props => [items, favorites];
}
