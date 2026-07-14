import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/habit.dart';
import '../../providers/app_providers.dart';

class ChatScreen extends HookConsumerWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useTextEditingController();
    final messages = useState<List<ChatMessage>>([]);
    final isLoading = useState(false);
    final scrollController = useScrollController();

    final profile = ref.watch(userProfileProvider).valueOrNull;
    final roadmap = ref.watch(roadmapProvider).valueOrNull;
    final ai = ref.watch(aiServiceProvider);

    Future<void> sendMessage() async {
      final text = controller.text.trim();
      if (text.isEmpty || isLoading.value) return;

      final userMsg = ChatMessage(
        id: const Uuid().v4(),
        content: text,
        isUser: true,
        timestamp: DateTime.now(),
      );
      messages.value = [...messages.value, userMsg];
      controller.clear();
      isLoading.value = true;

      try {
        final response = await ai.chat(
          profile: profile!,
          roadmap: roadmap,
          userMessage: text,
          history: messages.value,
        );
        messages.value = [
          ...messages.value,
          ChatMessage(
            id: const Uuid().v4(),
            content: response,
            isUser: false,
            timestamp: DateTime.now(),
          ),
        ];
      } finally {
        isLoading.value = false;
        await Future<void>.delayed(const Duration(milliseconds: 100));
        if (scrollController.hasClients) {
          scrollController.animateTo(
            scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      }
    }

    final suggestions = [
      'I\'m feeling lazy',
      'What should I study today?',
      'Quiz me',
      'Help me prepare',
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Coach Chat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.mic_outlined),
            tooltip: 'Voice (coming soon)',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Voice AI coming soon!')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (messages.value.isEmpty)
            Padding(
              padding: AppSpacing.pagePadding,
              child: Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: suggestions.map((s) {
                  return ActionChip(
                    label: Text(s),
                    onPressed: () {
                      controller.text = s;
                      sendMessage();
                    },
                  );
                }).toList(),
              ),
            ),
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              padding: AppSpacing.pagePadding,
              itemCount: messages.value.length + (isLoading.value ? 1 : 0),
              itemBuilder: (context, index) {
                if (isLoading.value && index == messages.value.length) {
                  return const _TypingIndicator();
                }
                final msg = messages.value[index];
                return _ChatBubble(message: msg);
              },
            ),
          ),
          Container(
            padding: AppSpacing.pagePadding,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).dividerColor,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      hintText: 'Ask your coach anything...',
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => sendMessage(),
                    textInputAction: TextInputAction.send,
                  ),
                ),
                IconButton(
                  onPressed: isLoading.value ? null : sendMessage,
                  icon: Icon(
                    Icons.send_rounded,
                    color: isLoading.value
                        ? Colors.grey
                        : AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? AppColors.primary
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
        ),
        child: Text(
          message.content,
          style: TextStyle(
            color: isUser ? Colors.white : null,
          ),
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const SizedBox(
          width: 40,
          height: 16,
          child: Center(
            child: Text('...', style: TextStyle(fontSize: 20)),
          ),
        ),
      ),
    );
  }
}
