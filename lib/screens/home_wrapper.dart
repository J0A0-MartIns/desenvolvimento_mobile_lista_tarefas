import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/ai_assistant_modal.dart';
import 'login_screen.dart';
import 'main_list_screen.dart';
import 'statistics_screen.dart';

class HomeWrapper extends StatefulWidget {
  const HomeWrapper({super.key});

  @override
  State<HomeWrapper> createState() => _HomeWrapperState();
}

class _HomeWrapperState extends State<HomeWrapper> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    MainListScreen(),
    StatisticsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAiInsights();
    });
  }

  void _checkAiInsights() {
    final auth = context.read<AuthProvider>();
    final insights = auth.aiInsights;
    if (insights != null && _isValidInsights(insights)) {
      _showInsightsModal(insights);
      auth.clearAiInsights();
    }
  }

  bool _isValidInsights(Map<String, dynamic> insights) {
    final delayedTasks = insights['delayed_tasks'] as List<dynamic>?;
    final priorityTask = insights['priority_task'] as String?;
    final suggestion = insights['suggestion'] as String?;

    bool hasDelayed = delayedTasks != null && delayedTasks.isNotEmpty;
    bool hasPriority = priorityTask != null && priorityTask.toString().isNotEmpty;
    bool hasSuggestion = suggestion != null && suggestion.toString().isNotEmpty;

    return hasDelayed || hasPriority || hasSuggestion;
  }

  void _showInsightsModal(Map<String, dynamic> insights) {
    showDialog(
      context: context,
      builder: (context) {
        final delayedTasks = insights['delayed_tasks'] as List<dynamic>? ?? [];
        final priorityTask = insights['priority_task']?.toString() ?? '';
        final suggestion = insights['suggestion']?.toString() ?? '';

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.psychology, color: Colors.purple),
              ),
              const SizedBox(width: 12),
              const Expanded(child: Text('Sugestão do Dia')),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (suggestion.isNotEmpty) ...[
                  const Text(
                    'Sugestão',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(suggestion, style: TextStyle(color: Colors.grey.shade800)),
                  const SizedBox(height: 16),
                ],
                if (priorityTask.isNotEmpty) ...[
                  const Text(
                    'Tarefa Prioritária',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.orange, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(priorityTask, style: TextStyle(color: Colors.grey.shade800)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                if (delayedTasks.isNotEmpty) ...[
                  const Text(
                    'Tarefas Atrasadas',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red),
                  ),
                  const SizedBox(height: 4),
                  ...delayedTasks.map((task) => Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        Expanded(child: Text(task.toString(), style: TextStyle(color: Colors.grey.shade800))),
                      ],
                    ),
                  )).toList(),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Entendi'),
            ),
          ],
        );
      },
    );
  }

  void _openAiModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AiAssistantModal(),
    );
  }

  Future<void> _logout(BuildContext context) async {
    await context.read<AuthProvider>().logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF6200EA);
    final email = context.watch<AuthProvider>().currentUserEmail ?? '';
    // Exibe só a parte antes do '@', ou o email completo se não tiver '@'
    final displayName = email.contains('@') ? email.split('@').first : email;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white.withOpacity(0.25),
              child: Text(
                displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              displayName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Sair',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                // Botão Tarefas
                Expanded(
                  child: _BottomNavItem(
                    icon: Icons.checklist_rounded,
                    label: 'Tarefas',
                    isSelected: _currentIndex == 0,
                    selectedColor: primaryColor,
                    onTap: () => setState(() => _currentIndex = 0),
                  ),
                ),

                // Botão central da IA (fora do menu, sobreposto)
                SizedBox(
                  width: 72,
                  child: Center(
                    child: GestureDetector(
                      onTap: _openAiModal,
                      child: Container(
                        width: 56,
                        height: 56,
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6200EA), Color(0xFF9C27B0)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.psychology,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ),

                // Botão Estatísticas
                Expanded(
                  child: _BottomNavItem(
                    icon: Icons.bar_chart_rounded,
                    label: 'Estatísticas',
                    isSelected: _currentIndex == 1,
                    selectedColor: primaryColor,
                    onTap: () => setState(() => _currentIndex = 1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final Color selectedColor;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.selectedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                icon,
                key: ValueKey(isSelected),
                color: isSelected ? selectedColor : Colors.grey.shade500,
                size: isSelected ? 26 : 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? selectedColor : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
