import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/ai_service.dart';
import 'chatbot_screen/bot_status.dart';
import 'chatbot_screen/chat_bubble.dart';
import 'chatbot_screen/chat_message.dart';
import 'chatbot_screen/empty_chat.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen>
    with SingleTickerProviderStateMixin {
  final _ai = AiService();
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  final _messages = <ChatMessage>[];
  final _history = <Map<String, String>>[];
  bool _sending = false;

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send({String? forcedText, int? retryForMessageId}) async {
    final text = (forcedText ?? _ctrl.text).trim();
    if (text.isEmpty) return;
    if (_sending) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _sending = true;
      if (retryForMessageId != null) {
        final idx = _messages.indexWhere((m) => m.id == retryForMessageId);
        if (idx >= 0) {
          _messages[idx] = _messages[idx].copyWith(status: BotStatus.typing);
        }
      } else {
        _messages.add(ChatMessage.user(text: text));
        _messages.add(ChatMessage.botTyping(requestText: text));
        _ctrl.clear();
      }
    });

    _scrollToBottom();

    final botIndex = retryForMessageId != null
        ? _messages.indexWhere((m) => m.id == retryForMessageId)
        : _messages.length - 1;

    final historySnapshot = List<Map<String, String>>.from(_history);

    try {
      final reply = await _ai.chat(mensaje: text, history: historySnapshot);
      if (!mounted) return;
      setState(() {
        if (botIndex >= 0 && botIndex < _messages.length) {
          _messages[botIndex] = _messages[botIndex].copyWith(
            text: reply,
            status: BotStatus.done,
          );
        }
      });
      _history
        ..add({'role': 'user', 'text': text})
        ..add({'role': 'assistant', 'text': reply});
    } catch (_) {
      if (!mounted) return;
      setState(() {
        if (botIndex >= 0 && botIndex < _messages.length) {
          _messages[botIndex] = _messages[botIndex].copyWith(
            text: 'No se pudo conectar. Toca para reintentar.',
            status: BotStatus.error,
          );
        }
      });
    } finally {
      if (mounted) setState(() => _sending = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent + 200,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final bgCard = theme.cardTheme.color ?? cs.surface;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.obsidiana,
        foregroundColor: AppColors.oroClaro,
        title: Text(
          'Asistente Cultural Nariño',
          style: AppTypography.displaySemiBold(color: AppColors.oroClaro),
        ),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? EmptyChat(onExampleTap: (t) => _send(forcedText: t))
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    itemCount: _messages.length,
                    itemBuilder: (_, i) => ChatBubble(
                      message: _messages[i],
                      onRetry: _messages[i].isBotError
                          ? () => _send(
                                forcedText: _messages[i].requestText ?? '',
                                retryForMessageId: _messages[i].id,
                              )
                          : null,
                    ),
                  ),
          ),
          Container(
            decoration: BoxDecoration(
              color: bgCard,
              border: Border(top: BorderSide(color: border)),
            ),
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      enabled: !_sending,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: 'Escribe tu pregunta...',
                        prefixIcon: Icon(Icons.chat_bubble_outline),
                      ),
                      style: AppTypography.bodyMedium(color: textPrimary),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _sending ? null : _send,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cs.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      child: _sending
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: cs.onPrimary,
                                strokeWidth: 2,
                              ),
                            )
                          : Icon(Icons.send, color: cs.onPrimary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
