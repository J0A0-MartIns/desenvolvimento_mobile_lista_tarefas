import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../providers/ai_provider.dart';
import '../providers/item_provider.dart';
import '../enums/app_spacing.dart';

class AiAssistantModal extends StatefulWidget {
  const AiAssistantModal({super.key});

  @override
  State<AiAssistantModal> createState() => _AiAssistantModalState();
}

class _AiAssistantModalState extends State<AiAssistantModal> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late stt.SpeechToText _speech;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _toggleListening() async {
    if (!_isListening) {
      try {
        bool available = await _speech.initialize(
          onStatus: (status) {
            if (status == 'done' || status == 'notListening') {
              setState(() => _isListening = false);
            }
          },
          onError: (errorNotification) {
            setState(() => _isListening = false);
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Reconhecimento de voz: ${errorNotification.errorMsg}'),
                backgroundColor: Colors.red,
              ),
            );
          },
        );

        if (available) {
          setState(() => _isListening = true);
          _speech.listen(
            onResult: (result) {
              setState(() {
                _textController.text = result.recognizedWords;
              });
            },
            localeId: 'pt_BR',
          );
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reconhecimento de voz não disponível neste dispositivo.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao acessar o microfone: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  void _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();
    FocusScope.of(context).unfocus();

    final aiProvider = context.read<AiProvider>();
    final itemProvider = context.read<ItemProvider>();

    _scrollToBottom();
    await aiProvider.sendCommand(text, itemProvider);
    _scrollToBottom();
  }

  void _showApiKeyDialog(BuildContext context) {
    final aiProvider = context.read<AiProvider>();
    final controller = TextEditingController(text: aiProvider.apiKey);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.vpn_key, color: Color(0xFF6200EA)),
            SizedBox(width: 8),
            Text('API Key do Gemini'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Insira sua chave de API do Gemini. Obtenha uma chave gratuita no Google AI Studio.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Chave de API',
                border: OutlineInputBorder(),
                hintText: 'AIzaSy...',
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              aiProvider.saveApiKey(controller.text);
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Configuração da chave salva!')),
              );
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final aiProvider = context.watch<AiProvider>();
    final messages = aiProvider.messages;
    final hasApiKey = aiProvider.apiKey != null && aiProvider.apiKey!.isNotEmpty;

    if (messages.isNotEmpty) {
      _scrollToBottom();
    }

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Cabeçalho do Modal
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.psychology, color: Color(0xFF6200EA)),
                  const SizedBox(width: 8),
                  const Text(
                    'Assistente de IA',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6200EA),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      Icons.settings,
                      color: hasApiKey ? const Color(0xFF6200EA) : Colors.amber,
                    ),
                    onPressed: () => _showApiKeyDialog(context),
                    tooltip: 'Chave API',
                  ),
                  if (messages.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.delete_sweep, color: Colors.grey),
                      onPressed: () => aiProvider.clearChat(),
                      tooltip: 'Limpar Chat',
                    ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Alerta se não houver chave de API
            if (!hasApiKey)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: Colors.amber.shade100,
                width: double.infinity,
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.amber.shade900, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'API Key não configurada. Toque no ícone de engrenagem acima.',
                        style: TextStyle(
                          color: Colors.amber.shade900,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Alerta de erro geral, se houver
            if (aiProvider.error != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                color: Colors.red.shade100,
                width: double.infinity,
                child: Text(
                  aiProvider.error!,
                  style: TextStyle(color: Colors.red.shade900, fontSize: 12),
                ),
              ),

            // Corpo do Chat
            Expanded(
              child: messages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.purple.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.psychology,
                              size: 60,
                              color: Color(0xFF6200EA),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Como posso ajudar você hoje?',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF6200EA),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              'Digite ou fale um comando para gerenciar suas tarefas (Criar, Editar, Excluir ou Concluir).',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.all(AppSpacing.medium.value),
                      itemCount: messages.length,
                      itemBuilder: (ctx, i) {
                        final msg = messages[i];
                        final isUser = msg['role'] == 'user';

                        return Align(
                          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              gradient: isUser
                                  ? const LinearGradient(
                                      colors: [Color(0xFF6200EA), Color(0xFF7C4DFF)],
                                    )
                                  : null,
                              color: isUser ? null : Colors.grey.shade200,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(16),
                                topRight: const Radius.circular(16),
                                bottomLeft: Radius.circular(isUser ? 16 : 0),
                                bottomRight: Radius.circular(isUser ? 0 : 16),
                              ),
                            ),
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.7,
                            ),
                            child: Text(
                              msg['content'] ?? '',
                              style: TextStyle(
                                color: isUser ? Colors.white : Colors.black87,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // Indicador de digitação
            if (aiProvider.isThinking)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6200EA)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'IA está pensando...',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),

            // Campo de Input e botões
            Padding(
              padding: EdgeInsets.all(AppSpacing.medium.value),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _textController,
                              decoration: const InputDecoration(
                                hintText: 'Fale ou escreva algo...',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(vertical: 10),
                              ),
                              onSubmitted: (_) => _sendMessage(),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              _isListening ? Icons.mic : Icons.mic_none,
                              color: _isListening ? Colors.red : Colors.grey.shade700,
                            ),
                            onPressed: _toggleListening,
                          ),
                          const SizedBox(width: 4),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: const Color(0xFF6200EA),
                    radius: 20,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white, size: 16),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
