import 'bot_status.dart';
import 'role.dart';

class ChatMessage {
  ChatMessage._({
    required this.id,
    required this.role,
    required this.text,
    required this.status,
    required this.requestText,
  });

  final int id;
  final Role role;
  final String text;
  final BotStatus? status;
  final String? requestText;

  bool get isUser => role == Role.user;
  bool get isTyping => role == Role.bot && status == BotStatus.typing;
  bool get isBotError => role == Role.bot && status == BotStatus.error;

  static int _idSeed = 0;

  factory ChatMessage.user({required String text}) => ChatMessage._(
        id: ++_idSeed,
        role: Role.user,
        text: text,
        status: null,
        requestText: null,
      );

  factory ChatMessage.botTyping({required String requestText}) =>
      ChatMessage._(
        id: ++_idSeed,
        role: Role.bot,
        text: '',
        status: BotStatus.typing,
        requestText: requestText,
      );

  ChatMessage copyWith({String? text, BotStatus? status}) => ChatMessage._(
        id: id,
        role: role,
        text: text ?? this.text,
        status: status ?? this.status,
        requestText: requestText,
      );
}
