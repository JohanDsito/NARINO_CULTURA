import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/nc_theme.dart';
import '../../../../shared/widgets/design/design.dart';
import '../../data/ai_service.dart';
import 'chatbot_screen/avatar_asistente.dart';
import 'chatbot_screen/bienvenida_chat.dart';
import 'chatbot_screen/burbuja_chat.dart';
import 'chatbot_screen/compositor_chat.dart';
import 'chatbot_screen/mensaje_chat.dart';

/// Asistente cultural con IA (Gemini). Azul: es la acción de ayuda; la
/// serpentina identifica al asistente.
class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key, this.service});

  /// Para pruebas; por defecto [AiService].
  final AiService? service;

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  late final AiService _ai = widget.service ?? AiService();
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final _mensajes = <MensajeChat>[];
  final _historial = <Map<String, String>>[];
  bool _enviando = false;

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _enviar([String? forzado]) async {
    final texto = (forzado ?? _ctrl.text).trim();
    if (texto.isEmpty || _enviando) return;
    final bot = MensajeChat.bot(texto);
    setState(() {
      _mensajes
        ..add(MensajeChat.usuario(texto))
        ..add(bot);
      _ctrl.clear();
    });
    await _responder(bot);
  }

  Future<void> _responder(MensajeChat bot) async {
    setState(() {
      _enviando = true;
      bot.estado = EstadoMensaje.escribiendo;
    });
    _bajar();
    final pregunta = bot.pregunta!;
    try {
      final r = await _ai.chat(mensaje: pregunta, history: List.of(_historial));
      if (!mounted) return;
      setState(() {
        bot
          ..texto = r
          ..estado = EstadoMensaje.listo;
      });
      _historial
        ..add({'role': 'user', 'text': pregunta})
        ..add({'role': 'model', 'text': r});
    } catch (e) {
      if (!mounted) return;
      final msg = e is FormatException ? e.message : e.toString();
      setState(() {
        bot
          ..texto = msg
          ..estado = EstadoMensaje.error;
      });
    } finally {
      if (mounted) setState(() => _enviando = false);
      _bajar();
    }
  }

  void _nueva() {
    HapticFeedback.selectionClick();
    setState(() {
      _mensajes.clear();
      _historial.clear();
    });
  }

  void _bajar() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: kNcEase,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            const AvatarAsistente(size: 36),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Asistente cultural',
                      style: AppTypography.labelSemiBold(color: nc.textPrimary)
                          .copyWith(fontSize: 16)),
                  Text(
                      _enviando
                          ? 'Escribiendo…'
                          : 'Arte, música y eventos de Nariño',
                      style: AppTypography.bodySmall(
                          color: _enviando ? nc.azul : nc.textSecondary)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (_mensajes.isNotEmpty)
            IconButton(
              tooltip: 'Nueva conversación',
              icon: const Icon(Icons.add_comment_outlined),
              onPressed: _enviando ? null : _nueva,
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _mensajes.isEmpty
                ? BienvenidaChat(onSugerencia: _enviar)
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    itemCount: _mensajes.length,
                    itemBuilder: (_, i) {
                      final m = _mensajes[i];
                      final sigueBot = i + 1 < _mensajes.length &&
                          _mensajes[i + 1].deBot == m.deBot;
                      return BurbujaChat(
                        m: m,
                        conAvatar: m.deBot && !sigueBot,
                        onReintentar:
                            m.estado == EstadoMensaje.error && !_enviando
                                ? () => _responder(m)
                                : null,
                      );
                    },
                  ),
          ),
          CompositorChat(
            ctrl: _ctrl,
            enviando: _enviando,
            onEnviar: () => _enviar(),
          ),
        ],
      ),
    );
  }
}
