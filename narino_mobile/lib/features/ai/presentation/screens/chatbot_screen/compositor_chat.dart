import 'package:flutter/material.dart';
import '../../../../../core/theme/nc_theme.dart';
import '../../../../../shared/widgets/design/design.dart';

/// Límite del backend para cada mensaje (`ChatAPIView`).
const _kMaxChars = 500;

class CompositorChat extends StatefulWidget {
  const CompositorChat({
    super.key,
    required this.ctrl,
    required this.enviando,
    required this.onEnviar,
  });

  final TextEditingController ctrl;
  final bool enviando;
  final VoidCallback onEnviar;

  @override
  State<CompositorChat> createState() => _CompositorState();
}

class _CompositorState extends State<CompositorChat> {
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
                counterText:
                    largo > _kMaxChars - 80 ? '$largo/$_kMaxChars' : '',
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(26)),
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
              onTap: puede ? widget.onEnviar : null,
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
