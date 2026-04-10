import 'package:flutter/material.dart';
import '../models/item_model.dart';
import 'dart:math';

class ItemProvider extends ChangeNotifier {
  final List<ItemModel> _items = [];

  // Pega apenas as tarefas logadas pro usuario ativo no momento
  List<ItemModel> getItemsForUser(String email) {
    return _items.where((item) => item.ownerEmail == email).toList();
  }

  void addItem(String title, String description, String ownerEmail, {DateTime? dueDate}) {
    final newItem = ItemModel(
      id: Random().nextInt(10000).toString(),
      title: title,
      description: description,
      dueDate: dueDate,
      ownerEmail: ownerEmail,
    );
    _items.add(newItem);
    notifyListeners();
  }

  void updateItem(String id, String newTitle, String newDescription, {DateTime? newDueDate}) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index >= 0) {
      _items[index] = _items[index].copyWith(
        title: newTitle,
        description: newDescription,
        dueDate: newDueDate,
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
