import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/dummy_data.dart';
import 'cart_event.dart';
import 'cart_state.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc()
      : super(CartState(
          items: [
            CartItem(product: DummyData.products[0], quantity: 1), // Bananas
            CartItem(product: DummyData.products[1], quantity: 1), // Red Apple
            CartItem(product: DummyData.products[2], quantity: 2), // Bell Pepper
          ],
          favorites: [
            DummyData.products[0],
            DummyData.products[1],
            DummyData.products[6],
          ],
        )) {
    on<AddToCartEvent>(_onAddToCart);
    on<UpdateQuantityEvent>(_onUpdateQuantity);
    on<RemoveFromCartEvent>(_onRemoveFromCart);
    on<ClearCartEvent>(_onClearCart);
    on<ToggleFavoriteEvent>(_onToggleFavorite);
  }

  void _onAddToCart(AddToCartEvent event, Emitter<CartState> emit) {
    final existingIndex =
        state.items.indexWhere((item) => item.product.id == event.product.id);

    List<CartItem> updatedItems = List.from(state.items);
    if (existingIndex >= 0) {
      final current = updatedItems[existingIndex];
      updatedItems[existingIndex] = current.copyWith(
        quantity: current.quantity + event.quantity,
      );
    } else {
      updatedItems.add(CartItem(
        product: event.product,
        quantity: event.quantity,
      ));
    }

    emit(state.copyWith(items: updatedItems));
  }

  void _onUpdateQuantity(UpdateQuantityEvent event, Emitter<CartState> emit) {
    List<CartItem> updatedItems = [];
    for (final item in state.items) {
      if (item.product.id == event.productId) {
        if (event.quantity > 0) {
          updatedItems.add(item.copyWith(quantity: event.quantity));
        }
      } else {
        updatedItems.add(item);
      }
    }
    emit(state.copyWith(items: updatedItems));
  }

  void _onRemoveFromCart(RemoveFromCartEvent event, Emitter<CartState> emit) {
    final updatedItems =
        state.items.where((item) => item.product.id != event.productId).toList();
    emit(state.copyWith(items: updatedItems));
  }

  void _onClearCart(ClearCartEvent event, Emitter<CartState> emit) {
    emit(state.copyWith(items: const []));
  }

  void _onToggleFavorite(ToggleFavoriteEvent event, Emitter<CartState> emit) {
    final isFav = state.isFavorite(event.product.id);
    List<dynamic> updatedFavs = List.from(state.favorites);

    if (isFav) {
      updatedFavs.removeWhere((p) => p.id == event.product.id);
    } else {
      updatedFavs.add(event.product);
    }

    emit(state.copyWith(favorites: updatedFavs.cast()));
  }
}
