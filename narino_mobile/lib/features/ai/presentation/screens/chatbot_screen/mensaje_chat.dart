enum EstadoMensaje { escribiendo, listo, error }

class MensajeChat {
  MensajeChat.usuario(this.texto)
      : deBot = false,
        estado = EstadoMensaje.listo,
        pregunta = null;
  MensajeChat.bot(this.pregunta)
      : deBot = true,
        texto = '',
        estado = EstadoMensaje.escribiendo;

  final bool deBot;
  String texto;
  EstadoMensaje estado;

  /// Pregunta que originó la respuesta (para reintentar).
  final String? pregunta;
}
