import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/item_provider.dart';
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

  @override
  void initState() {
    super.initState();
    if (widget.itemToEdit != null) {
      _titleController.text = widget.itemToEdit!.title;
      _descController.text = widget.itemToEdit!.description;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      if (widget.itemToEdit == null) {
        context.read<ItemProvider>().addItem(
              _titleController.text,
              _descController.text,
            );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tarefa incluída!')),
        );
      } else {
        context.read<ItemProvider>().updateItem(
              widget.itemToEdit!.id,
              _titleController.text,
              _descController.text,
            );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tarefa editada!')),
        );
      }
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.itemToEdit != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Tarefa' : 'Nova Tarefa'),
      ),
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
                  if (val == null || val.trim().isEmpty) return 'Título é obrigatório';
                  return null;
                },
              ),
              SizedBox(height: AppSpacing.medium.value),
              AuthTextField(
                label: 'Descrição',
                hint: 'Detalhes adicionais (opcional)',
                controller: _descController,
                validator: (_) => null,
              ),
              SizedBox(height: AppSpacing.large.value),
              PrimaryButton(
                text: 'Salvar',
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
