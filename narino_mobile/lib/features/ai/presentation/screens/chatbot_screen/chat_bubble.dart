import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import 'chat_message.dart';
import 'typing_dots.dart';

class ChatBubble extends StatelessWidget {
  const ChatBubble({super.key, required this.message, required this.onRetry});

  final ChatMessage message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final bgCard = theme.cardTheme.color ?? cs.surface;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final isUser = message.isUser;
    final bubbleColor = isUser ? cs.primary : bgCard;
    final textColor = isUser ? cs.onPrimary : textPrimary;
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
              border: isUser ? null : Border.all(color: border),
            ),
            child: message.isTyping
                ? const TypingDots()
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
