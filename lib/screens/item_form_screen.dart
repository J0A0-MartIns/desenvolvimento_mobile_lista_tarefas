import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/item_provider.dart';
import '../providers/auth_provider.dart';
import '../models/item_model.dart';
import '../enums/app_spacing.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/primary_button.dart';

class ItemFormScreen extends StatefulWidget {
  final ItemModel? itemToEdit;

  const ItemFormScreen({super.key, this.itemToEdit});

  @override
  State<ItemFormScreen> createState() => _ItemFormScreenState();
}

class _ItemFormScreenState extends State<ItemFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  DateTime? _dueDate;
  String? _category;

  final List<String> _categories = [
    'Trabalho',
    'Pessoal',
    'Estudo',
    'Saúde',
    'Finanças',
    'Casa',
    'Outros',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.itemToEdit != null) {
      _titleController.text = widget.itemToEdit!.title;
      _descController.text = widget.itemToEdit!.description;
      _dueDate = widget.itemToEdit!.dueDate;
      if (_categories.contains(widget.itemToEdit!.category)) {
        _category = widget.itemToEdit!.category;
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _save() async {
    if (_formKey.currentState!.validate()) {
      if (_dueDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor, selecione uma data de vencimento.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      try {
        if (widget.itemToEdit == null) {
          await context.read<ItemProvider>().addItem(
            _titleController.text,
            _descController.text,
            dueDate: _dueDate,
            category: _category,
          );
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Tarefa incluída!')));
          }
        } else {
          await context.read<ItemProvider>().updateItem(
            widget.itemToEdit!.id,
            _titleController.text,
            _descController.text,
            newDueDate: _dueDate,
            newCategory: _category,
          );
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Tarefa editada!')));
          }
        }
        if (mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          final errorMsg = e.toString().replaceFirst('Exception: ', '');
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(errorMsg), backgroundColor: Colors.red));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.itemToEdit != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Editar Tarefa' : 'Nova Tarefa')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.medium.value),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              AuthTextField(
                label: 'Título da Tarefa',
                hint: 'Insira o título (obrigatório)',
                controller: _titleController,
                validator: (val) {
                  if (val == null || val.trim().isEmpty)
                    return 'Título é obrigatório';
                  return null;
                },
              ),
              SizedBox(height: AppSpacing.medium.value),
              AuthTextField(
                label: 'Descrição',
                hint: 'Insira a descrição (obrigatória)',
                controller: _descController,
                validator: (val) {
                  if (val == null || val.trim().isEmpty)
                    return 'Descrição é obrigatória';
                  return null;
                },
              ),
              SizedBox(height: AppSpacing.medium.value),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: InputDecoration(
                  labelText: 'Categoria',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                items: _categories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _category = newValue;
                  });
                },
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return 'Categoria é obrigatória';
                  }
                  return null;
                },
              ),
              SizedBox(height: AppSpacing.medium.value),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _dueDate == null
                          ? 'Sem data'
                          : 'Data: ${_dueDate!.day.toString().padLeft(2, '0')}/${_dueDate!.month.toString().padLeft(2, '0')}/${_dueDate!.year}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today),
                    label: const Text('Calendário'),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _dueDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() {
                          _dueDate = picked;
                        });
                      }
                    },
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.large.value),
              PrimaryButton(text: 'Salvar', onPressed: _save),
            ],
          ),
        ),
      ),
    );
  }
}
