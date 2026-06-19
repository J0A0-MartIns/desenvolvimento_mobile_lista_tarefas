import 'package:flutter/material.dart';

/// Modal bonito para exibir insights de IA retornados pelo backend no login.
///
/// Campos esperados em [insights]:
///   - `delayed_tasks`  : `List<dynamic>`  (lista de tarefas atrasadas)
///   - `priority_task`   : `String`         (tarefa prioritária ou "Nenhuma tarefa pendente")
///   - `suggestion`      : `String`         (sugestão da IA)
class AiInsightsModal extends StatelessWidget {
  final Map<String, dynamic> insights;

  const AiInsightsModal({super.key, required this.insights});

  /// Verifica se o objeto de insights possui conteúdo válido para exibir.
  /// Se todos os campos forem nulos, vazios ou listas vazias, retorna false.
  static bool hasValidData(Map<String, dynamic>? insights) {
    if (insights == null) return false;

    final delayedTasks = insights['delayed_tasks'];
    final priorityTask = insights['priority_task'];
    final suggestion = insights['suggestion'];

    final hasDelayed = delayedTasks != null &&
        delayedTasks is List &&
        delayedTasks.isNotEmpty;

    final hasPriority = priorityTask != null &&
        priorityTask is String &&
        priorityTask.trim().isNotEmpty;

    final hasSuggestion = suggestion != null &&
        suggestion is String &&
        suggestion.trim().isNotEmpty;

    return hasDelayed || hasPriority || hasSuggestion;
  }

  @override
  Widget build(BuildContext context) {
    final delayedTasks = insights['delayed_tasks'];
    final priorityTask = insights['priority_task'];
    final suggestion = insights['suggestion'];

    final hasDelayed = delayedTasks != null &&
        delayedTasks is List &&
        delayedTasks.isNotEmpty;
    final hasPriority = priorityTask != null &&
        priorityTask is String &&
        priorityTask.trim().isNotEmpty;
    final hasSuggestion = suggestion != null &&
        suggestion is String &&
        suggestion.trim().isNotEmpty;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
              Color(0xFF0F3460),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6200EA).withValues(alpha: 0.3),
              blurRadius: 30,
              spreadRadius: 2,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──────────────────────────────────────────────
            _buildHeader(context),

            // ── Body ────────────────────────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tarefa prioritária
                    if (hasPriority) ...[
                      _InsightCard(
                        icon: Icons.flag_rounded,
                        iconColor: const Color(0xFFFFB74D),
                        title: 'Tarefa Prioritária',
                        content: priorityTask,
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Tarefas atrasadas
                    if (hasDelayed) ...[
                      _InsightCard(
                        icon: Icons.warning_amber_rounded,
                        iconColor: const Color(0xFFEF5350),
                        title: 'Tarefas Atrasadas',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: delayedTasks
                              .map<Widget>((task) => Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 3),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          '• ',
                                          style: TextStyle(
                                            color: Color(0xFFEF5350),
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            task.toString(),
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 14,
                                              height: 1.4,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Sugestão da IA
                    if (hasSuggestion) ...[
                      _InsightCard(
                        icon: Icons.lightbulb_rounded,
                        iconColor: const Color(0xFF66BB6A),
                        title: 'Sugestão da IA',
                        content: suggestion,
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
            ),

            // ── Footer / botão ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6200EA),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Entendi!',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Column(
        children: [
          // Ícone animado de IA
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF6200EA), Color(0xFF9C27B0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6200EA).withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Insights para Você',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Veja o que a IA preparou com base nas suas tarefas',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Card individual para cada insight ─────────────────────────────────────
class _InsightCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? content;
  final Widget? child;

  const _InsightCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.content,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título do card
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Conteúdo
          if (child != null) child!,
          // ignore: use_null_aware_elements
          if (content != null)
            Text(
              content!,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.5,
              ),
            ),
        ],
      ),
    );
  }
}
