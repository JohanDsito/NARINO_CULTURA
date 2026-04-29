import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/ai_service.dart';

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

  final _messages = <_ChatMessage>[];
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
          _messages[idx] = _messages[idx].copyWith(status: _BotStatus.typing);
        }
      } else {
        _messages.add(_ChatMessage.user(text: text));
        _messages.add(_ChatMessage.botTyping(requestText: text));
        _ctrl.clear();
      }
    });

    _scrollToBottom();

    final botIndex = retryForMessageId != null
        ? _messages.indexWhere((m) => m.id == retryForMessageId)
        : _messages.length - 1;

    try {
      final reply = await _ai.chat(mensaje: text);
      if (!mounted) return;
      setState(() {
        if (botIndex >= 0 && botIndex < _messages.length) {
          _messages[botIndex] = _messages[botIndex].copyWith(
            text: reply,
            status: _BotStatus.done,
          );
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        if (botIndex >= 0 && botIndex < _messages.length) {
          _messages[botIndex] = _messages[botIndex].copyWith(
            text: 'No se pudo conectar. Toca para reintentar.',
            status: _BotStatus.error,
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
    return Scaffold(
      backgroundColor: AppColors.bgLight,
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
                ? _EmptyChat(onExampleTap: (t) => _send(forcedText: t))
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    itemCount: _messages.length,
                    itemBuilder: (_, i) => _ChatBubble(
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
            decoration: const BoxDecoration(
              color: AppColors.bgCardLight,
              border: Border(
                top: BorderSide(color: AppColors.borderLight),
              ),
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
                      style: AppTypography.bodyMedium(
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _sending ? null : _send,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.tierraProfunda,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      child: _sending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.send, color: Colors.white),
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

class _EmptyChat extends StatelessWidget {
  const _EmptyChat({required this.onExampleTap});

  final void Function(String text) onExampleTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.chat_bubble_outline,
              color: AppColors.textMutedLight,
              size: 72,
            ),
            const SizedBox(height: 16),
            Text(
              'Pregúntame sobre arte y cultura de Nariño',
              style: AppTypography.displaySemiBold(
                color: AppColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Ejemplos: “¿Qué obras hay en Barniz de Pasto?” o “¿Qué eventos hay esta semana?”',
              style: AppTypography.bodySmall(color: AppColors.textMutedLight),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                _ExampleChip(
                  label: 'Carnaval',
                  onTap: () => onExampleTap(
                    'Cuéntame sobre el Carnaval de Negros y Blancos.',
                  ),
                ),
                _ExampleChip(
                  label: 'Artistas',
                  onTap: () => onExampleTap(
                    '¿Qué artistas destacados hay en la plataforma?',
                  ),
                ),
                _ExampleChip(
                  label: 'Eventos',
                  onTap: () => onExampleTap(
                    'Recomiéndame eventos culturales en Nariño.',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ExampleChip extends StatelessWidget {
  const _ExampleChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.bgCardLight,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Text(
          label,
          style:
              AppTypography.labelSemiBold(color: AppColors.textSecondaryLight),
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message, required this.onRetry});

  final _ChatMessage message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final bubbleColor =
        isUser ? AppColors.tierraProfunda : AppColors.bgCardLight;
    final textColor = isUser ? Colors.white : AppColors.textPrimaryLight;
    final alignment = isUser ? Alignment.centerRight : Alignment.centerLeft;

    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: InkWell(
          onTap: onRetry,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 320),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.circular(14),
              border: isUser ? null : Border.all(color: AppColors.borderLight),
            ),
            child: message.isTyping
                ? const _TypingDots()
                : Text(
                    message.text,
                    style: AppTypography.bodyMedium(color: textColor),
                  ),
          ),
        ),
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _a;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
    _a = CurvedAnimation(parent: _c, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _a,
      builder: (_, __) {
        double o(int i) {
          final t = (_a.value + i * 0.18) % 1.0;
          final v = (t < 0.5) ? (t * 2) : ((1 - t) * 2);
          return 0.25 + v * 0.75;
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Dot(opacity: o(0)),
            const SizedBox(width: 5),
            _Dot(opacity: o(1)),
            const SizedBox(width: 5),
            _Dot(opacity: o(2)),
          ],
        );
      },
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.opacity});

  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: AppColors.textMutedLight,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

enum _BotStatus { typing, done, error }

class _ChatMessage {
  _ChatMessage._({
    required this.id,
    required this.role,
    required this.text,
    required this.status,
    required this.requestText,
  });

  final int id;
  final _Role role;
  final String text;
  final _BotStatus? status;
  final String? requestText;

  bool get isUser => role == _Role.user;
  bool get isTyping => role == _Role.bot && status == _BotStatus.typing;
  bool get isBotError => role == _Role.bot && status == _BotStatus.error;

  static int _idSeed = 0;

  factory _ChatMessage.user({required String text}) => _ChatMessage._(
        id: ++_idSeed,
        role: _Role.user,
        text: text,
        status: null,
        requestText: null,
      );

  factory _ChatMessage.botTyping({required String requestText}) =>
      _ChatMessage._(
        id: ++_idSeed,
        role: _Role.bot,
        text: '',
        status: _BotStatus.typing,
        requestText: requestText,
      );

  _ChatMessage copyWith({String? text, _BotStatus? status}) => _ChatMessage._(
        id: id,
        role: role,
        text: text ?? this.text,
        status: status ?? this.status,
        requestText: requestText,
      );
}

enum _Role { user, bot }
