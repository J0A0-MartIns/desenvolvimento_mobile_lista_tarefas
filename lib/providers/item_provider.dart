import 'package:flutter/material.dart';
import '../models/item_model.dart';
import 'dart:math';

class ItemProvider extends ChangeNotifier {
  final List<ItemModel> _items = [];

  List<ItemModel> get items => List.unmodifiable(_items);

  void addItem(String title, String description) {
    final newItem = ItemModel(
      id: Random().nextInt(10000).toString(),
      title: title,
      description: description,
    );
    _items.add(newItem);
    notifyListeners();
  }

  void updateItem(String id, String newTitle, String newDescription) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index >= 0) {
      _items[index] = _items[index].copyWith(
        title: newTitle,
        description: newDescription,
      );
      notifyListeners();
    }
  }

  void removeItem(String id) {
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  void toggleItemCompletion(String id) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index >= 0) {
      _items[index] = _items[index].copyWith(
        isCompleted: !_items[index].isCompleted,
      );
      notifyListeners();
    }
  }
}
