import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/nc_theme.dart';
import '../../../../shared/widgets/design/design.dart';
import '../../data/ai_service.dart';

/// Límite del backend para cada mensaje (`ChatAPIView`).
const _kMaxChars = 500;

enum _Estado { escribiendo, listo, error }

class _Mensaje {
  _Mensaje.usuario(this.texto)
      : deBot = false,
        estado = _Estado.listo,
        pregunta = null;
  _Mensaje.bot(this.pregunta)
      : deBot = true,
        texto = '',
        estado = _Estado.escribiendo;

  final bool deBot;
  String texto;
  _Estado estado;

  /// Pregunta que originó la respuesta (para reintentar).
  final String? pregunta;
}

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
  final _mensajes = <_Mensaje>[];
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
    final bot = _Mensaje.bot(texto);
    setState(() {
      _mensajes
        ..add(_Mensaje.usuario(texto))
        ..add(bot);
      _ctrl.clear();
    });
    await _responder(bot);
  }

  Future<void> _responder(_Mensaje bot) async {
    setState(() {
      _enviando = true;
      bot.estado = _Estado.escribiendo;
    });
    _bajar();
    final pregunta = bot.pregunta!;
    try {
      final r = await _ai.chat(
          mensaje: pregunta, history: List.of(_historial));
      if (!mounted) return;
      setState(() {
        bot
          ..texto = r
          ..estado = _Estado.listo;
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
          ..estado = _Estado.error;
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
            const _AvatarBot(size: 36),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Asistente cultural',
                      style:
                          AppTypography.labelSemiBold(color: nc.textPrimary)
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
                ? _Bienvenida(onSugerencia: _enviar)
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    itemCount: _mensajes.length,
                    itemBuilder: (_, i) {
                      final m = _mensajes[i];
                      final sigueBot = i + 1 < _mensajes.length &&
                          _mensajes[i + 1].deBot == m.deBot;
                      return _Burbuja(
                        m: m,
                        conAvatar: m.deBot && !sigueBot,
                        onReintentar: m.estado == _Estado.error && !_enviando
                            ? () => _responder(m)
                            : null,
                      );
                    },
                  ),
          ),
          _Compositor(
            ctrl: _ctrl,
            enviando: _enviando,
            onEnviar: () => _enviar(),
          ),
        ],
      ),
    );
  }
}

/// Círculo con la serpentina y el ícono del asistente.
class _AvatarBot extends StatelessWidget {
  const _AvatarBot({this.size = 32});

  final double size;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: SweepGradient(colors: [
          ...nc.carnavalGradient.colors,
          nc.carnavalGradient.colors.first,
        ]),
      ),
      padding: EdgeInsets.all(size * 0.08),
      child: Container(
        decoration: BoxDecoration(color: nc.bgCard, shape: BoxShape.circle),
        child: Icon(Icons.auto_awesome_rounded,
            size: size * 0.5, color: nc.azul),
      ),
    );
  }
}

class _Bienvenida extends StatelessWidget {
  const _Bienvenida({required this.onSugerencia});

  final ValueChanged<String> onSugerencia;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final sugerencias = [
      (Icons.celebration_outlined, nc.tomateA, 'El Carnaval',
          'Cuéntame la historia del Carnaval de Negros y Blancos.'),
      (Icons.music_note_rounded, nc.azulA, 'Música',
          'Recomiéndame bandas de música andina de Nariño.'),
      (Icons.content_cut_rounded, nc.naranjaA, 'Artesanía',
          '¿Qué es el barniz de Pasto y quién lo trabaja?'),
      (Icons.event_rounded, nc.catalogo, 'Eventos',
          '¿Qué eventos culturales hay pronto en Nariño?'),
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
      children: [
        const Center(child: _AvatarBot(size: 84)),
        const SizedBox(height: 18),
        Text('¡Hola! Soy tu guía cultural',
            textAlign: TextAlign.center,
            style: AppTypography.displayBold(color: nc.textPrimary)
                .copyWith(fontSize: 24)),
        const SizedBox(height: 8),
        Text(
          'Pregúntame por artistas, obras, música y eventos de Nariño. '
          'Escribe como le hablarías a una amiga.',
          textAlign: TextAlign.center,
          style: AppTypography.bodyMedium(color: nc.textSecondary),
        ),
        const SizedBox(height: 24),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.25,
          children: [
            for (final (icon, accent, titulo, pregunta) in sugerencias)
              Semantics(
                button: true,
                label: 'Preguntar: $pregunta',
                excludeSemantics: true,
                child: NcPressable(
                  onTap: () => onSugerencia(pregunta),
                  pressedScale: 0.96,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Color.alphaBlend(accent.tint, nc.bgCard),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                          color: accent.fill.withValues(alpha: 0.4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        NcAccentIcon(icon: icon, accent: accent, size: 34),
                        const Spacer(),
                        Text(titulo,
                            style: AppTypography.labelSemiBold(
                                color: accent.ink)),
                        const SizedBox(height: 2),
                        Text(pregunta,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodySmall(
                                    color: nc.textSecondary)
                                .copyWith(fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          'Las respuestas las genera una IA y pueden tener errores.',
          textAlign: TextAlign.center,
          style: AppTypography.bodySmall(color: nc.textMuted),
        ),
      ],
    );
  }
}

class _Burbuja extends StatelessWidget {
  const _Burbuja({
    required this.m,
    required this.conAvatar,
    this.onReintentar,
  });

  final _Mensaje m;
  final bool conAvatar;
  final VoidCallback? onReintentar;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final ancho = MediaQuery.sizeOf(context).width * 0.78;

    if (!m.deBot) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8, left: 48),
          constraints: BoxConstraints(maxWidth: ancho),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: nc.azulA.fill,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(6),
            ),
          ),
          child: SelectableText(m.texto,
              style: AppTypography.bodyMedium(color: nc.azulA.onFill)),
        ),
      );
    }

    final error = m.estado == _Estado.error;
    final contenido = switch (m.estado) {
      _Estado.escribiendo => const _Puntos(),
      _Estado.error => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.error_outline_rounded,
                    size: 18, color: nc.tomateA.ink),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(m.texto,
                      style: AppTypography.bodyMedium(color: nc.textPrimary)),
                ),
              ],
            ),
            if (onReintentar != null) ...[
              const SizedBox(height: 6),
              TextButton.icon(
                onPressed: onReintentar,
                style: TextButton.styleFrom(
                  foregroundColor: nc.tomateA.ink,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 36),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Reintentar'),
              ),
            ],
          ],
        ),
      _Estado.listo => _TextoBot(m.texto),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SizedBox(
            width: 30,
            child: conAvatar ? const _AvatarBot(size: 28) : null,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: GestureDetector(
              onLongPress: m.estado == _Estado.listo
                  ? () {
                      Clipboard.setData(ClipboardData(text: m.texto));
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Respuesta copiada')));
                    }
                  : null,
              child: Container(
                constraints: BoxConstraints(maxWidth: ancho),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  color: error
                      ? Color.alphaBlend(nc.tomateA.tint, nc.bgCard)
                      : nc.bgCard,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                    bottomLeft: Radius.circular(6),
                    bottomRight: Radius.circular(20),
                  ),
                  border: Border.all(
                      color: error
                          ? nc.tomateA.fill.withValues(alpha: 0.4)
                          : nc.border),
                ),
                child: contenido,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Texto del bot con el markdown sencillo que usa Gemini: **negrita**,
/// viñetas (`*`, `-`, `•`) y títulos (`#`).
class _TextoBot extends StatelessWidget {
  const _TextoBot(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final base = AppTypography.bodyMedium(color: nc.textPrimary);
    final negrita = base.copyWith(fontWeight: FontWeight.w700);

    List<TextSpan> enLinea(String s, {bool titulo = false}) {
      final spans = <TextSpan>[];
      final partes = s.split('**');
      for (var i = 0; i < partes.length; i++) {
        if (partes[i].isEmpty) continue;
        spans.add(TextSpan(
            text: partes[i], style: (i.isOdd || titulo) ? negrita : base));
      }
      return spans;
    }

    final filas = <Widget>[];
    for (final raw in texto.trim().split('\n')) {
      final l = raw.trimRight();
      if (l.trim().isEmpty) {
        if (filas.isNotEmpty) filas.add(const SizedBox(height: 6));
        continue;
      }
      final vineta = RegExp(r'^\s*([*\-•]|\d+\.)\s+').firstMatch(l);
      final titulo = RegExp(r'^\s*#{1,4}\s+').firstMatch(l);
      if (vineta != null) {
        final marca = vineta.group(1)!;
        filas.add(Padding(
          padding: const EdgeInsets.only(top: 2, bottom: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 18,
                child: Text(RegExp(r'\d').hasMatch(marca) ? marca : '•',
                    style: base.copyWith(color: nc.azul)),
              ),
              Expanded(
                  child: Text.rich(
                      TextSpan(children: enLinea(l.substring(vineta.end))))),
            ],
          ),
        ));
      } else if (titulo != null) {
        filas.add(Text.rich(TextSpan(
            children: enLinea(l.substring(titulo.end), titulo: true))));
      } else {
        filas.add(Text.rich(TextSpan(children: enLinea(l))));
      }
    }
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: filas);
  }
}

class _Puntos extends StatefulWidget {
  const _Puntos();

  @override
  State<_Puntos> createState() => _PuntosState();
}

class _PuntosState extends State<_Puntos> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1100))
    ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final colores = [nc.tomateA.fill, nc.oroA.fill, nc.azulA.fill];
    return Semantics(
      label: 'El asistente está escribiendo',
      child: SizedBox(
        height: 20,
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, __) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < 3; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Transform.translate(
                    offset: Offset(
                        0,
                        -4 *
                            (1 -
                                ((_c.value * 3 - i) % 3 - 0.5).abs().clamp(0, 1)
                                    .toDouble())),
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                          color: colores[i], shape: BoxShape.circle),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Compositor extends StatefulWidget {
  const _Compositor({
    required this.ctrl,
    required this.enviando,
    required this.onEnviar,
  });

  final TextEditingController ctrl;
  final bool enviando;
  final VoidCallback onEnviar;

  @override
  State<_Compositor> createState() => _CompositorState();
}

class _CompositorState extends State<_Compositor> {
  @override
  void initState() {
    super.initState();
    widget.ctrl.addListener(_cambio);
  }

  @override
  void dispose() {
    widget.ctrl.removeListener(_cambio);
    super.dispose();
  }

  void _cambio() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    final largo = widget.ctrl.text.characters.length;
    final puede = widget.ctrl.text.trim().isNotEmpty && !widget.enviando;
    return NcGlassBottomBar(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: widget.ctrl,
              minLines: 1,
              maxLines: 5,
              maxLength: _kMaxChars,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => widget.onEnviar(),
              decoration: InputDecoration(
                hintText: 'Pregúntame algo de Nariño…',
                counterText: largo > _kMaxChars - 80
                    ? '$largo/$_kMaxChars'
                    : '',
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(26)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(26),
                  borderSide: BorderSide(color: nc.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(26),
                  borderSide: BorderSide(color: nc.azul, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Semantics(
              button: true,
              enabled: puede,
              label: 'Enviar',
              excludeSemantics: true,
              child: NcPressable(
                onTap: puede ? widget.onEnviar : null,
                pressedScale: 0.9,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: puede ? nc.azulA.fill : nc.itemFill,
                    shape: BoxShape.circle,
                  ),
                  child: widget.enviando
                      ? Padding(
                          padding: const EdgeInsets.all(14),
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: nc.azul),
                        )
                      : Icon(Icons.arrow_upward_rounded,
                          color: puede ? nc.azulA.onFill : nc.textMuted),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
