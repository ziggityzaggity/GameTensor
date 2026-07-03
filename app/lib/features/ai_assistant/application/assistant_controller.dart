import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/games_repository.dart';
import '../data/chat_backend.dart';

enum ChatRole { user, assistant }

/// One rendered chat bubble. Assistant messages may carry [gameIds] to render as
/// inline game cards; [isError] flags a transport/assistant failure so the UI can
/// style it distinctly without throwing away the conversation.
class ChatMessage {
  const ChatMessage({
    required this.role,
    required this.text,
    this.gameIds = const [],
    this.isError = false,
  });

  final ChatRole role;
  final String text;
  final List<String> gameIds;
  final bool isError;
}

class AssistantState {
  const AssistantState({
    this.messages = const [],
    this.sessionId,
    this.isSending = false,
  });

  final List<ChatMessage> messages;

  /// Threaded back on each turn so the server loads prior history (multi-turn).
  final String? sessionId;
  final bool isSending;

  AssistantState copyWith({
    List<ChatMessage>? messages,
    String? sessionId,
    bool? isSending,
  }) {
    return AssistantState(
      messages: messages ?? this.messages,
      sessionId: sessionId ?? this.sessionId,
      isSending: isSending ?? this.isSending,
    );
  }
}

class AssistantController extends Notifier<AssistantState> {
  @override
  AssistantState build() => const AssistantState();

  Future<void> send(String rawText) async {
    final text = rawText.trim();
    if (text.isEmpty || state.isSending) return;

    // Optimistically show the user's turn, then a loading state.
    state = state.copyWith(
      messages: [...state.messages, ChatMessage(role: ChatRole.user, text: text)],
      isSending: true,
    );

    try {
      final res = await ref.read(chatBackendProvider).send(
            message: text,
            sessionId: state.sessionId,
          );
      state = state.copyWith(
        messages: [
          ...state.messages,
          ChatMessage(
            role: ChatRole.assistant,
            text: res.reply,
            gameIds: res.gameIds,
          ),
        ],
        // Persist the session id from the first turn so later turns are threaded.
        sessionId: res.sessionId,
        isSending: false,
      );
    } catch (_) {
      state = state.copyWith(
        messages: [
          ...state.messages,
          const ChatMessage(
            role: ChatRole.assistant,
            text: "Sorry, I couldn't reach the assistant. Please try again.",
            isError: true,
          ),
        ],
        isSending: false,
      );
    }
  }
}

final assistantControllerProvider =
    NotifierProvider<AssistantController, AssistantState>(AssistantController.new);

/// Fetches the Game rows for a set of retrieved ids so a bubble can render inline
/// cards. Family-keyed on the id list (joined) so identical id sets share a fetch.
final assistantGamesProvider = FutureProvider.family((ref, List<String> ids) {
  return ref.read(gamesRepositoryProvider).getGamesByIds(ids);
});
