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
     - Para "update": o "id" é obrigatório e inclua apenas os campos que mudaram.
     - Para "complete": o "id" é obrigatório e "isCompleted" (booleano) é obrigatório.
     - Para "delete": apenas o "id" é obrigatório.
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
        final Map<String, dynamic> parsedResponse = jsonDecode(textResponse);

        final String action = parsedResponse['action'] ?? 'none';
        final String feedback = parsedResponse['feedback'] ?? 'Comando processado.';
        final Map<String, dynamic>? taskData = parsedResponse['task'];

        // Executa a ação do CRUD
        if (action == 'create' && taskData != null) {
          final String title = taskData['title'] ?? 'Nova tarefa sem título';
          final String description = taskData['description'] ?? '';
          DateTime? dueDate;
          if (taskData['dueDate'] != null) {
            dueDate = DateTime.tryParse(taskData['dueDate']);
          }
          final String category = taskData['category'] ?? 'Outros';

          await itemProvider.addItem(title, description, dueDate: dueDate, category: category);
        } else if (action == 'update' && taskData != null && taskData['id'] != null) {
          final String id = taskData['id'].toString();
          // Localiza tarefa existente para mesclar valores não alterados
          final existingTask = itemProvider.items.firstWhere((item) => item.id == id);

          final String title = taskData['title'] ?? existingTask.title;
          final String description = taskData['description'] ?? existingTask.description;
          DateTime? dueDate = existingTask.dueDate;
          if (taskData['dueDate'] != null) {
            dueDate = DateTime.tryParse(taskData['dueDate']);
          }
          final String category = taskData['category'] ?? existingTask.category ?? 'Outros';

          await itemProvider.updateItem(id, title, description, newDueDate: dueDate, newCategory: category);
        } else if (action == 'complete' && taskData != null && taskData['id'] != null) {
          final String id = taskData['id'].toString();
          final bool isCompleted = taskData['isCompleted'] ?? true;
          final existingTask = itemProvider.items.firstWhere((item) => item.id == id);

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
}
