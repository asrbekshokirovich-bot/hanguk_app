import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/chat_repository.dart';
import '../../../../design_system/theme/hanguk_ink.dart';
import '../../../../l10n/app_localizations.dart';
import 'widgets/chat_message_bubble.dart';

class ChatTab extends ConsumerStatefulWidget {
  const ChatTab({super.key});

  @override
  ConsumerState<ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends ConsumerState<ChatTab> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _handleSend() {
    final text = _textController.text;
    if (text.trim().isEmpty) return;

    _textController.clear();
    FocusScope.of(context).unfocus();

    // Pass the active UI locale so the AI answers in the user's language
    // instead of always defaulting to English.
    final locale = Localizations.localeOf(context).languageCode;
    ref.read(chatProvider.notifier).sendMessage(text, locale: locale);
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final l = AppLocalizations.of(context)!;

    ref.listen(chatProvider, (previous, next) {
      if (previous?.messages.length != next.messages.length ||
          (previous?.isLoading == true && next.isLoading == false)) {
        Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
      }
    });

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'Hanguk AI',
          style: HangukInk.display.copyWith(fontSize: 18),
        ),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: HangukInk.ink,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            color: HangukInk.ink2,
            tooltip: l.a11yTooltipClearChat,
            onPressed: () {
              ref.read(chatProvider.notifier).clearChat();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount:
                  chatState.messages.length + (chatState.isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == chatState.messages.length && chatState.isLoading) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(width: 44),
                        SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ],
                    ),
                  );
                }
                return ChatMessageBubble(message: chatState.messages[index]);
              },
            ),
          ),

          if (chatState.error != null)
            Container(
              padding: const EdgeInsets.all(8),
              color: Theme.of(context).colorScheme.errorContainer,
              width: double.infinity,
              child: Text(
                chatState.error!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ),

          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: HangukInk.hanji,
                border: Border(
                  top: BorderSide(color: HangukInk.ink.withValues(alpha: 0.10)),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      style: const TextStyle(color: HangukInk.ink),
                      decoration: InputDecoration(
                        hintText: 'Ask anything about South Korea...',
                        hintStyle: const TextStyle(color: HangukInk.ink3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(28),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(28),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(28),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: HangukInk.paper.withValues(alpha: 0.9),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _handleSend(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  CircleAvatar(
                    backgroundColor: HangukInk.jadeDeep,
                    radius: 24,
                    child: IconButton(
                      icon: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                      ),
                      tooltip: l.a11yTooltipSendMessage,
                      onPressed: chatState.isLoading ? null : _handleSend,
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
