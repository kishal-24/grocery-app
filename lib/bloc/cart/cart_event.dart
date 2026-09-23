import 'package:equatable/equatable.dart';
import '../../data/models/product_model.dart';

abstract class CartEvent extends Equatable {
  const CartEvent();

  @override
  List<Object?> get props => [];
}

class AddToCartEvent extends CartEvent {
  final ProductModel product;
  final int quantity;

  const AddToCartEvent({required this.product, this.quantity = 1});

  @override
  List<Object?> get props => [product, quantity];
}

class UpdateQuantityEvent extends CartEvent {
  final String productId;
  final int quantity;

  const UpdateQuantityEvent({required this.productId, required this.quantity});

  @override
  List<Object?> get props => [productId, quantity];
}

class RemoveFromCartEvent extends CartEvent {
  final String productId;

  const RemoveFromCartEvent({required this.productId});

  @override
  List<Object?> get props => [productId];
}

class ClearCartEvent extends CartEvent {
  const ClearCartEvent();
}

class ToggleFavoriteEvent extends CartEvent {
  final ProductModel product;

  const ToggleFavoriteEvent({required this.product});

  @override
  List<Object?> get props => [product];
}
