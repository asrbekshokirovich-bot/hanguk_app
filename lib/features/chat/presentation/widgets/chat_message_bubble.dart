import 'package:flutter/material.dart';
import '../../domain/chat_message.dart';
import '../../../../design_system/theme/hanguk_ink.dart';

class ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatMessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final bool isUser = message.role == 'user';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              height: 32,
              width: 32,
              decoration: const BoxDecoration(
                color: HangukInk.ink,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome,
                size: 16,
                color: HangukInk.gold,
              ),
            ),
            const SizedBox(width: 12),
          ],

          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: isUser
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF46B0A0), HangukInk.jadeDeep],
                      )
                    : null,
                color: isUser ? null : HangukInk.paper.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(20).copyWith(
                  bottomRight: isUser
                      ? const Radius.circular(4)
                      : const Radius.circular(20),
                  bottomLeft: isUser
                      ? const Radius.circular(20)
                      : const Radius.circular(4),
                ),
                border: isUser
                    ? null
                    : Border.all(
                        color: HangukInk.ink.withValues(alpha: 0.10),
                        width: 1,
                      ),
              ),
              child: Text(
                message.content,
                style: TextStyle(
                  fontSize: 15,
                  color: isUser ? Colors.white : HangukInk.ink,
                  height: 1.45,
                  fontWeight: isUser ? FontWeight.w500 : FontWeight.w400,
                ),
              ),
            ),
          ),

          if (isUser) ...[
            const SizedBox(width: 12),
            Container(
              height: 32,
              width: 32,
              decoration: BoxDecoration(
                color: HangukInk.ink.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_outline,
                size: 16,
                color: HangukInk.ink2,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
