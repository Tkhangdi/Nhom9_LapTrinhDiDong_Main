import 'package:flutter/material.dart';
import 'CartItem.dart';

class Cart with ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => _items;

  double get totalPrice =>
      _items.fold(0, (sum, item) => sum + item.gia * item.soLuong);

  void addItem(CartItem item) {
    var existingIndex = _items.indexWhere((element) => element.id == item.id);

    if (existingIndex != -1) {
      _items[existingIndex].soLuong += 1;
    } else {
      _items.add(item);
    }

    notifyListeners();//để UI cập nhật lại
  }

  void removeItem(String id) {
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  void updateQuantity(String id, int quantity) {
    var index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      if (quantity > 0) {
        _items[index].soLuong = quantity;
      } else {
        _items.removeAt(index);
      }
      notifyListeners();
    }
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}
