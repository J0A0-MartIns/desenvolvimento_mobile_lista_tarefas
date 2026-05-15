import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/item_model.dart';
import '../api_constants.dart';

class ItemProvider extends ChangeNotifier {
  List<ItemModel> _items = [];
  bool _isLoading = false;

  List<ItemModel> get items => _items;
  bool get isLoading => _isLoading;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> fetchItems() async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await _getToken();
      if (token == null) return;

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/tasks'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _items = data.map((json) => ItemModel.fromJson(json)).toList();
      }
    } catch (e) {
      print('Erro ao carregar tarefas: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addItem(String title, String description, {DateTime? dueDate}) async {
    try {
      final token = await _getToken();
      if (token == null) return;

      final newItem = ItemModel(
        id: '', // Será substituído pelo ID da API
        title: title,
        description: description,
        dueDate: dueDate,
      );

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/tasks'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(newItem.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        _items.add(ItemModel.fromJson(data));
        notifyListeners();
      }
    } catch (e) {
      print('Erro ao adicionar tarefa: $e');
    }
  }

  Future<void> updateItem(String id, String newTitle, String newDescription, {DateTime? newDueDate}) async {
    try {
      final token = await _getToken();
      if (token == null) return;

      final response = await http.patch(
        Uri.parse('${ApiConstants.baseUrl}/tasks/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'title': newTitle,
          'description': newDescription,
          'dueDate': newDueDate?.toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final updatedItem = ItemModel.fromJson(data);
        final index = _items.indexWhere((item) => item.id == id);
        if (index >= 0) {
          _items[index] = updatedItem;
          notifyListeners();
        }
      }
    } catch (e) {
      print('Erro ao atualizar tarefa: $e');
    }
  }

  Future<void> removeItem(String id) async {
    try {
      final token = await _getToken();
      if (token == null) return;

      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}/tasks/$id'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        _items.removeWhere((item) => item.id == id);
        notifyListeners();
      }
    } catch (e) {
      print('Erro ao remover tarefa: $e');
    }
  }

  Future<void> toggleItemCompletion(String id) async {
    final index = _items.indexWhere((item) => item.id == id);
    if (index < 0) return;

    final currentItem = _items[index];
    final newStatus = !currentItem.isCompleted;

    // Atualiza otimisticamente na UI
    _items[index] = currentItem.copyWith(isCompleted: newStatus);
    notifyListeners();

    try {
      final token = await _getToken();
      if (token == null) return;

      final response = await http.patch(
        Uri.parse('${ApiConstants.baseUrl}/tasks/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'isCompleted': newStatus,
        }),
      );

      if (response.statusCode != 200) {
        // Reverte se falhou
        _items[index] = currentItem;
        notifyListeners();
      }
    } catch (e) {
      // Reverte se falhou
      _items[index] = currentItem;
      notifyListeners();
      print('Erro ao completar tarefa: $e');
    }
  }
}
