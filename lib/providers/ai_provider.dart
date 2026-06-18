import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/item_model.dart';
import 'item_provider.dart';

class AiProvider extends ChangeNotifier {
  String? _apiKey;
  final List<Map<String, String>> _messages = [];
  bool _isThinking = false;
  String? _error;

  String? get apiKey => _apiKey;
  List<Map<String, String>> get messages => _messages;
  bool get isThinking => _isThinking;
  String? get error => _error;

  AiProvider() {
    loadApiKey();
  }

  Future<void> loadApiKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _apiKey = prefs.getString('gemini_api_key');
      notifyListeners();
    } catch (e) {
      print('Erro ao carregar API Key: $e');
    }
  }

  Future<void> saveApiKey(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (key.trim().isEmpty) {
        await prefs.remove('gemini_api_key');
        _apiKey = null;
      } else {
        await prefs.setString('gemini_api_key', key.trim());
        _apiKey = key.trim();
      }
      _error = null;
      notifyListeners();
    } catch (e) {
      print('Erro ao salvar API Key: $e');
    }
  }

  void clearChat() {
    _messages.clear();
    _error = null;
    notifyListeners();
  }

  Future<void> sendCommand(String userText, ItemProvider itemProvider) async {
    if (userText.trim().isEmpty) return;
    if (_apiKey == null || _apiKey!.isEmpty) {
      _error = 'Configure sua API Key do Gemini antes de continuar.';
      notifyListeners();
      return;
    }

    // Adiciona mensagem do usuário ao chat
    _messages.add({'role': 'user', 'content': userText});
    _isThinking = true;
    _error = null;
    notifyListeners();

    try {
      // Constrói o histórico do chat em formato legível para o prompt
      final chatHistoryString = _messages.take(_messages.length - 1).map((m) {
        return '${m['role'] == 'user' ? 'Usuário' : 'Assistente'}: ${m['content']}';
      }).join('\n');

      // Serializa as tarefas atuais
      final tasksJson = itemProvider.items.map((item) => {
        'id': item.id,
        'title': item.title,
        'description': item.description,
        'isCompleted': item.isCompleted,
        'dueDate': item.dueDate?.toIso8601String(),
        'category': item.category,
      }).toList();

      final systemPrompt = '''
Você é o assistente inteligente integrado ao aplicativo de tarefas (ToDo List). Seu objetivo é ajudar o usuário a gerenciar suas tarefas através de comandos em linguagem natural (por texto ou fala).

Informações de Contexto Importantes:
1. Data/Hora Atual: ${DateTime.now().toIso8601String()} (Use isso para resolver termos relativos como "hoje", "amanhã", "segunda-feira", "semana que vem", etc.).
2. Categorias Válidas: "Trabalho", "Pessoal", "Estudo", "Saúde", "Finanças", "Casa", "Outros". Qualquer tarefa criada ou atualizada deve ter uma destas categorias.
3. Lista de Tarefas Atuais do Usuário:
${jsonEncode(tasksJson)}

Histórico recente da conversa:
$chatHistoryString

Instruções:
- Identifique a intenção do usuário: adicionar uma nova tarefa (create), alterar uma existente (update), excluir uma existente (delete), marcar/concluir/desmarcar uma tarefa (complete), ou se é apenas uma dúvida/conversa sobre as tarefas (none).
- Se a intenção for atualizar, completar ou deletar, procure na Lista de Tarefas Atuais pela tarefa mais próxima à descrição fornecida pelo usuário para obter o "id" correto.
- Retorne obrigatoriamente um objeto JSON contendo:
  1. "action": "create", "update", "delete", "complete" ou "none".
  2. "task": Objeto contendo os dados da tarefa a ser criada ou modificada. 
     - Para "create": "title" é obrigatório, "description" e "dueDate" e "category" são opcionais (se ausentes, preencha com valores sugeridos ou padrão, usando "Outros" para categoria).
     - Para "update": o "id" é obrigatório e inclua apenas os campos que mudaram (se o usuário pedir para alterar ou definir a data, inclua o campo "dueDate").
     - Para "complete": o "id" é obrigatório e "isCompleted" (booleano) é obrigatório.
     - Para "delete": apenas o "id" é obrigatório.
     - Para o campo "dueDate": SEMPRE calcule a data correta baseada na Data/Hora Atual e retorne no formato ISO 8601 "YYYY-MM-DD". Se o usuário pedir para remover a data de entrega, defina "dueDate" como null.
  3. "feedback": Uma resposta curta e amigável em português explicando o que foi feito ou respondendo à dúvida do usuário de forma clara.
''';

      final response = await http.post(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': systemPrompt},
                {'text': 'Comando do Usuário: "$userText"'}
              ]
            }
          ],
          'generationConfig': {
            'responseMimeType': 'application/json',
            'responseSchema': {
              'type': 'OBJECT',
              'properties': {
                'action': {
                  'type': 'STRING',
                  'enum': ['create', 'update', 'delete', 'complete', 'none']
                },
                'task': {
                  'type': 'OBJECT',
                  'properties': {
                    'id': {'type': 'STRING'},
                    'title': {'type': 'STRING'},
                    'description': {'type': 'STRING'},
                    'dueDate': {'type': 'STRING'},
                    'category': {'type': 'STRING'},
                    'isCompleted': {'type': 'BOOLEAN'}
                  }
                },
                'feedback': {'type': 'STRING'}
              },
              'required': ['action', 'feedback']
            }
          }
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final String textResponse = data['candidates'][0]['content']['parts'][0]['text'];
        print('AI Provider - Raw Response: $textResponse');
        final Map<String, dynamic> parsedResponse = jsonDecode(textResponse);

        final String action = parsedResponse['action'] ?? 'none';
        final String feedback = parsedResponse['feedback'] ?? 'Comando processado.';
        final Map<String, dynamic>? taskData = parsedResponse['task'];
        const allowedCategories = ['Trabalho', 'Pessoal', 'Estudo', 'Saúde', 'Finanças', 'Casa', 'Outros'];

        print('AI Provider - Parsed Action: $action, TaskData: $taskData');

        // Executa a ação do CRUD
        if (action == 'create' && taskData != null) {
          String title = taskData['title'] ?? 'Nova tarefa sem título';
          String description = taskData['description'] ?? '';
          
          if (title.length > 255) {
            description = description.isEmpty ? title : '$title\n\n$description';
            title = '${title.substring(0, 250)}...';
          }

          DateTime? dueDate;
          if (taskData.containsKey('dueDate')) {
            final rawDueDate = taskData['dueDate'];
            if (rawDueDate != null) {
              dueDate = _parseAiDate(rawDueDate.toString());
            }
          }
          
          String category = taskData['category'] ?? 'Outros';
          if (!allowedCategories.contains(category)) {
            category = allowedCategories.firstWhere(
              (c) => c.toLowerCase() == category.toLowerCase(),
              orElse: () => 'Outros',
            );
          }

          await itemProvider.addItem(title, description, dueDate: dueDate, category: category);
        } else if (action == 'update' && taskData != null && taskData['id'] != null) {
          final String id = taskData['id'].toString();
          // Localiza tarefa existente para mesclar valores não alterados
          final existingTask = itemProvider.items.firstWhere((item) => item.id == id);

          String title = taskData['title'] ?? existingTask.title;
          String description = taskData['description'] ?? existingTask.description;

          if (title.length > 255) {
            description = description.isEmpty ? title : '$title\n\n$description';
            title = '${title.substring(0, 250)}...';
          }

          DateTime? dueDate = existingTask.dueDate;
          if (taskData.containsKey('dueDate')) {
            final rawDueDate = taskData['dueDate'];
            if (rawDueDate == null) {
              dueDate = null;
            } else {
              final parsed = _parseAiDate(rawDueDate.toString());
              if (parsed != null) {
                dueDate = parsed;
              }
            }
          }
          
          String category = taskData['category'] ?? existingTask.category ?? 'Outros';
          if (!allowedCategories.contains(category)) {
            category = allowedCategories.firstWhere(
              (c) => c.toLowerCase() == category.toLowerCase(),
              orElse: () => 'Outros',
            );
          }

          bool? isCompleted;
          if (taskData.containsKey('isCompleted')) {
            final rawIsCompleted = taskData['isCompleted'];
            if (rawIsCompleted is bool) {
              isCompleted = rawIsCompleted;
            } else if (rawIsCompleted is String) {
              isCompleted = rawIsCompleted.toLowerCase() == 'true';
            }
          } else if (taskData.containsKey('completed')) {
            final rawCompleted = taskData['completed'];
            if (rawCompleted is bool) {
              isCompleted = rawCompleted;
            } else if (rawCompleted is String) {
              isCompleted = rawCompleted.toLowerCase() == 'true';
            }
          }

          await itemProvider.updateItem(
            id,
            title,
            description,
            newDueDate: dueDate,
            newCategory: category,
            newIsCompleted: isCompleted,
          );
        } else if (action == 'complete' && taskData != null && taskData['id'] != null) {
          final String id = taskData['id'].toString();
          final existingTask = itemProvider.items.firstWhere((item) => item.id == id);

          bool isCompleted = true;
          if (taskData.containsKey('isCompleted')) {
            final rawIsCompleted = taskData['isCompleted'];
            if (rawIsCompleted is bool) {
              isCompleted = rawIsCompleted;
            } else if (rawIsCompleted is String) {
              isCompleted = rawIsCompleted.toLowerCase() == 'true';
            }
          } else if (taskData.containsKey('completed')) {
            final rawCompleted = taskData['completed'];
            if (rawCompleted is bool) {
              isCompleted = rawCompleted;
            } else if (rawCompleted is String) {
              isCompleted = rawCompleted.toLowerCase() == 'true';
            }
          }

          if (existingTask.isCompleted != isCompleted) {
            await itemProvider.toggleItemCompletion(id);
          }
        } else if (action == 'delete' && taskData != null && taskData['id'] != null) {
          final String id = taskData['id'].toString();
          await itemProvider.removeItem(id);
        }

        // Adiciona a resposta da IA no chat
        _messages.add({'role': 'model', 'content': feedback});
      } else {
        final Map<String, dynamic> errData = jsonDecode(response.body);
        final errMsg = errData['error']?['message'] ?? 'Erro desconhecido na API do Gemini.';
        _error = 'Erro na API (${response.statusCode}): $errMsg';
        _messages.add({'role': 'model', 'content': 'Não consegui processar o comando devido a um erro na API.'});
      }
    } catch (e) {
      _error = 'Ocorreu uma falha na comunicação: $e';
      _messages.add({'role': 'model', 'content': 'Desculpe, ocorreu um erro ao tentar processar seu comando.'});
    } finally {
      _isThinking = false;
      notifyListeners();
    }
  }

  Future<String> generateStatisticsInsights(List<ItemModel> tasks) async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      return 'Configure sua API Key nas configurações do Assistente de IA para visualizar insights personalizados.';
    }

    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final completed = tasks.where((t) => t.isCompleted).length;
      final pending = tasks.where((t) => !t.isCompleted).length;
      final overdue = tasks.where((t) {
        if (t.isCompleted || t.dueDate == null) return false;
        final target = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
        return target.isBefore(today);
      }).length;

      final Map<String, int> categories = {};
      for (var t in tasks) {
        final cat = t.category ?? 'Outros';
        categories[cat] = (categories[cat] ?? 0) + 1;
      }

      final prompt = '''
Você é o assistente inteligente do aplicativo de tarefas. Analise de forma bem resumida o progresso atual do usuário:
- Total de tarefas: ${tasks.length}
- Tarefas concluídas: $completed
- Tarefas pendentes: $pending
- Tarefas atrasadas: $overdue
- Divisão por categoria: ${categories.toString()}

Escreva de forma sucinta (no máximo 3 frases), motivadora e direta ao ponto em português. Diga a ele como está indo e dê uma sugestão prática de ação para melhorar a produtividade hoje.
''';

      final response = await http.post(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [{'text': prompt}]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return data['candidates'][0]['content']['parts'][0]['text'] ?? 'Nenhum insight disponível.';
      } else {
        return 'Não foi possível buscar insights de IA no momento (Código ${response.statusCode}).';
      }
    } catch (e) {
      return 'Erro de conexão ao buscar insights: $e';
    }
  }

  DateTime? _parseAiDate(String? dateStr) {
    if (dateStr == null || dateStr.trim().isEmpty) return null;
    
    // Tenta parse normal (ISO 8601)
    final parsed = DateTime.tryParse(dateStr);
    if (parsed != null) return parsed;

    final normalized = dateStr.trim().toLowerCase();

    // Datas relativas em português
    if (normalized.contains('amanhã') || normalized.contains('amanha')) {
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day + 1);
    }
    if (normalized.contains('hoje')) {
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day);
    }
    if (normalized.contains('ontem')) {
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day - 1);
    }

    // Tenta formato brasileiro DD/MM/YYYY ou DD-MM-YYYY
    final regExpBr = RegExp(r'^(\d{1,2})[-/](\d{1,2})[-/](\d{4})');
    final matchBr = regExpBr.firstMatch(dateStr);
    if (matchBr != null) {
      final day = int.parse(matchBr.group(1)!);
      final month = int.parse(matchBr.group(2)!);
      final year = int.parse(matchBr.group(3)!);
      return DateTime(year, month, day);
    }

    // Tenta formato DD/MM (sem ano)
    final regExpShortBr = RegExp(r'^(\d{1,2})[-/](\d{1,2})$');
    final matchShortBr = regExpShortBr.firstMatch(dateStr.trim());
    if (matchShortBr != null) {
      final day = int.parse(matchShortBr.group(1)!);
      final month = int.parse(matchShortBr.group(2)!);
      final year = DateTime.now().year;
      return DateTime(year, month, day);
    }

    // Tenta formato escrito em português: "19 de junho" ou "19 de junho de 2026"
    final months = {
      'janeiro': 1, 'fev': 2, 'fevereiro': 2, 'março': 3, 'marco': 3,
      'abril': 4, 'maio': 5, 'junho': 6, 'julho': 7, 'agosto': 8,
      'setembro': 9, 'outubro': 10, 'novembro': 11, 'dezembro': 12
    };
    final regExpPt = RegExp(r'^(\d{1,2})\s+de\s+([a-zç]+)(?:\s+de\s+(\d{4}))?');
    final matchPt = regExpPt.firstMatch(normalized);
    if (matchPt != null) {
      final day = int.parse(matchPt.group(1)!);
      final monthStr = matchPt.group(2)!;
      final yearStr = matchPt.group(3);
      final month = months[monthStr];
      if (month != null) {
        final year = yearStr != null ? int.parse(yearStr) : DateTime.now().year;
        return DateTime(year, month, day);
      }
    }

    // Tenta formato YYYY-MM-DD
    final regExpIso = RegExp(r'^(\d{4})[-/](\d{1,2})[-/](\d{1,2})');
    final matchIso = regExpIso.firstMatch(dateStr);
    if (matchIso != null) {
      final year = int.parse(matchIso.group(1)!);
      final month = int.parse(matchIso.group(2)!);
      final day = int.parse(matchIso.group(3)!);
      return DateTime(year, month, day);
    }

    return null;
  }
}
