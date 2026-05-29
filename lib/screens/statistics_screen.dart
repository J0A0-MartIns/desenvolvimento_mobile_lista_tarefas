import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/item_provider.dart';
import '../providers/ai_provider.dart';
import '../models/item_model.dart';
import '../enums/app_spacing.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  String? _aiInsight;
  bool _loadingInsight = false;

  @override
  void initState() {
    super.initState();
    // Gera insights automaticamente se o usuário tiver chave configurada
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final aiProvider = context.read<AiProvider>();
      if (aiProvider.apiKey != null && aiProvider.apiKey!.isNotEmpty) {
        _generateInsight();
      }
    });
  }

  Future<void> _generateInsight() async {
    setState(() {
      _loadingInsight = true;
    });

    try {
      final itemProvider = context.read<ItemProvider>();
      final aiProvider = context.read<AiProvider>();
      final insight = await aiProvider.generateStatisticsInsights(itemProvider.items);
      setState(() {
        _aiInsight = insight;
      });
    } catch (e) {
      setState(() {
        _aiInsight = 'Não foi possível carregar os conselhos da IA.';
      });
    } finally {
      setState(() {
        _loadingInsight = false;
      });
    }
  }

  int _calculateOverdue(List<ItemModel> items) {
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    return items.where((item) {
      if (item.isCompleted || item.dueDate == null) return false;
      final target = DateTime(item.dueDate!.year, item.dueDate!.month, item.dueDate!.day);
      return target.isBefore(today);
    }).length;
  }

  List<ItemModel> _getOverdueList(List<ItemModel> items) {
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    return items.where((item) {
      if (item.isCompleted || item.dueDate == null) return false;
      final target = DateTime(item.dueDate!.year, item.dueDate!.month, item.dueDate!.day);
      return target.isBefore(today);
    }).toList();
  }

  Map<String, int> _getCategoryDistribution(List<ItemModel> items) {
    final Map<String, int> dist = {};
    for (var item in items) {
      final category = item.category ?? 'Outros';
      dist[category] = (dist[category] ?? 0) + 1;
    }
    return dist;
  }

  @override
  Widget build(BuildContext context) {
    final itemProvider = context.watch<ItemProvider>();
    final items = itemProvider.items;
    final total = items.length;
    final completed = items.where((item) => item.isCompleted).length;
    final pending = total - completed;
    final overdue = _calculateOverdue(items);
    final overdueList = _getOverdueList(items);
    final categoryDistribution = _getCategoryDistribution(items);

    final double completionRate = total > 0 ? (completed / total) : 0.0;
    final String completionPercentage = (completionRate * 100).toStringAsFixed(0);

    return Scaffold(
      body: itemProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                final aiProvider = context.read<AiProvider>();
                await itemProvider.fetchItems();
                if (aiProvider.apiKey != null) {
                  await _generateInsight();
                }
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(AppSpacing.medium.value),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Grid de Métricas Principais
                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: AppSpacing.small.value,
                      mainAxisSpacing: AppSpacing.small.value,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildMetricCard(
                          title: 'Total de Tarefas',
                          value: total.toString(),
                          icon: Icons.assignment_outlined,
                          colors: [const Color(0xFF6200EA), const Color(0xFF7C4DFF)],
                        ),
                        _buildMetricCard(
                          title: 'Concluídas',
                          value: completed.toString(),
                          icon: Icons.check_circle_outline,
                          colors: [const Color(0xFF00BFA5), const Color(0xFF00E676)],
                        ),
                        _buildMetricCard(
                          title: 'Pendentes',
                          value: pending.toString(),
                          icon: Icons.hourglass_empty,
                          colors: [const Color(0xFFFF9100), const Color(0xFFFFB300)],
                        ),
                        _buildMetricCard(
                          title: 'Atrasadas',
                          value: overdue.toString(),
                          icon: Icons.error_outline,
                          colors: [const Color(0xFFFF1744), const Color(0xFFFF5252)],
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.medium.value),

                    // Taxa de Conclusão (Circular gauge)
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.medium.value),
                        child: Row(
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 80,
                                  height: 80,
                                  child: CircularProgressIndicator(
                                    value: total > 0 ? completionRate : 0,
                                    strokeWidth: 8,
                                    backgroundColor: Colors.grey.shade200,
                                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6200EA)),
                                  ),
                                ),
                                Text(
                                  '$completionPercentage%',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF6200EA),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Média de Conclusão',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    total > 0
                                        ? 'Você completou $completed de $total tarefas criadas.'
                                        : 'Nenhuma tarefa cadastrada no momento.',
                                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                                  ),
                                  const SizedBox(height: 8),
                                  _buildCompletionFeedback(completionRate),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: AppSpacing.medium.value),

                    // Insights da IA
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      color: Colors.purple.shade50,
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.medium.value),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.psychology, color: Color(0xFF6200EA), size: 28),
                                const SizedBox(width: 8),
                                const Text(
                                  'Insights de Produtividade (IA)',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF6200EA),
                                  ),
                                ),
                                const Spacer(),
                                if (_aiInsight != null && !_loadingInsight)
                                  IconButton(
                                    icon: const Icon(Icons.refresh, color: Color(0xFF6200EA), size: 20),
                                    onPressed: _generateInsight,
                                  ),
                              ],
                            ),
                            const Divider(color: Colors.purple),
                            const SizedBox(height: 8),
                            if (_loadingInsight)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                      SizedBox(width: 12),
                                      Text('Gerando análise personalizada...'),
                                    ],
                                  ),
                                ),
                              )
                            else if (_aiInsight != null)
                              Text(
                                _aiInsight!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                  height: 1.4,
                                ),
                              )
                            else
                              Center(
                                child: Column(
                                  children: [
                                    const Text(
                                      'Obtenha uma análise inteligente das suas tarefas.',
                                      style: TextStyle(fontSize: 13, color: Colors.black54),
                                    ),
                                    const SizedBox(height: 12),
                                    ElevatedButton.icon(
                                      onPressed: _generateInsight,
                                      icon: const Icon(Icons.auto_awesome, size: 16),
                                      label: const Text('Analisar com IA'),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: AppSpacing.medium.value),

                    // Distribuição por Categoria
                    const Text(
                      'Distribuição por Categoria',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: AppSpacing.small.value),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.medium.value),
                        child: categoryDistribution.isEmpty
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Text('Nenhuma categoria cadastrada.'),
                                ),
                              )
                            : Column(
                                children: categoryDistribution.entries.map((entry) {
                                  final double pct = total > 0 ? (entry.value / total) : 0.0;
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 80,
                                          child: Text(
                                            entry.key,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Expanded(
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: LinearProgressIndicator(
                                              value: pct,
                                              minHeight: 12,
                                              backgroundColor: Colors.grey.shade100,
                                              valueColor: const AlwaysStoppedAnimation<Color>(
                                                Color(0xFF6200EA),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          '${entry.value} (${(pct * 100).toStringAsFixed(0)}%)',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade700,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                      ),
                    ),
                    SizedBox(height: AppSpacing.medium.value),

                    // Tarefas Atrasadas
                    const Text(
                      'Tarefas Atrasadas',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: AppSpacing.small.value),
                    if (overdueList.isEmpty)
                      Card(
                        elevation: 1,
                        child: Padding(
                          padding: EdgeInsets.all(AppSpacing.medium.value),
                          child: const Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.green),
                              SizedBox(width: 12),
                              Text('Excelente! Nenhuma tarefa atrasada.'),
                            ],
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: overdueList.length,
                        itemBuilder: (ctx, i) {
                          final item = overdueList[i];
                          final int diff = DateTime.now()
                              .difference(DateTime(
                                  item.dueDate!.year, item.dueDate!.month, item.dueDate!.day))
                              .inDays;

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Color(0xFFFFCDD2),
                                child: Icon(Icons.warning, color: Colors.red),
                              ),
                              title: Text(
                                item.title,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                item.category != null
                                    ? '${item.category} • Atrasada há $diff dia(s)'
                                    : 'Atrasada há $diff dia(s)',
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.check, color: Colors.green),
                                onPressed: () {
                                  context.read<ItemProvider>().toggleItemCompletion(item.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Tarefa concluída!')),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required List<Color> colors,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors.first.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionFeedback(double rate) {
    String text = '';
    Color color = Colors.grey;

    if (rate == 1.0) {
      text = 'Incrível! Tudo pronto!';
      color = Colors.green.shade700;
    } else if (rate >= 0.7) {
      text = 'Ótimo ritmo!';
      color = Colors.blue.shade700;
    } else if (rate >= 0.4) {
      text = 'Bom progresso, continue!';
      color = Colors.orange.shade700;
    } else {
      text = 'Vamos começar a produzir?';
      color = Colors.red.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}
