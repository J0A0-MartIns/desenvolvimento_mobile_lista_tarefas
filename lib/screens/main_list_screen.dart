import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/item_provider.dart';
import '../providers/auth_provider.dart';
import '../enums/app_spacing.dart';
import '../widgets/app_drawer.dart';
import 'item_form_screen.dart';

class MainListScreen extends StatelessWidget {
  const MainListScreen({super.key});

  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Tarefa'),
        content: const Text('Tem certeza que deseja excluir esta tarefa?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              context.read<ItemProvider>().removeItem(id);
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tarefa excluída.')),
              );
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatDueDate(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = target.difference(today).inDays;
    
    if (diff == 0) return 'Vence hoje!';
    if (diff == 1) return 'Vence amanhã';
    if (diff > 1) return 'Vence em $diff dias';
    if (diff == -1) return 'Atrasado 1 dia';
    return 'Atrasado ${-diff} dias';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<ItemProvider>();
    
    // Agora só filtramos as tarefas que cruzam com o email de quem tá acessando
    final items = provider.getItemsForUser(auth.currentUserEmail ?? '');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Tarefas'),
      ),
      drawer: const AppDrawer(), 
      body: items.isEmpty
          ? Center(
              child: Text(
                'Nenhuma tarefa! Adicione uma nova.',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(AppSpacing.small.value),
              itemCount: items.length,
              itemBuilder: (ctx, i) {
                final item = items[i];
                final hasDate = item.dueDate != null;
                final isOverdue = hasDate && item.dueDate!.isBefore(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day));

                return Card(
                  margin: EdgeInsets.symmetric(vertical: AppSpacing.small.value),
                  child: ListTile(
                    leading: Checkbox(
                      value: item.isCompleted,
                      onChanged: (_) {
                        context.read<ItemProvider>().toggleItemCompletion(item.id);
                      },
                    ),
                    title: Text(
                      item.title,
                      style: TextStyle(
                        decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (item.description.isNotEmpty) Text(item.description),
                        if (hasDate)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              _formatDueDate(item.dueDate),
                              style: TextStyle(
                                color: item.isCompleted
                                    ? Colors.grey
                                    : (isOverdue ? Colors.red : Colors.green.shade700),
                                fontWeight: FontWeight.bold,
                                decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                              ),
                            ),
                          ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ItemFormScreen(itemToEdit: item),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _confirmDelete(context, item.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ItemFormScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
