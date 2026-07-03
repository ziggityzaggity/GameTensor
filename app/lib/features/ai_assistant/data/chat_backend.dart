import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../bootstrap.dart';

/// One assistant response: the prose reply, the game ids to render as cards, and
/// the session id to thread back on the next turn.
class ChatResponse {
  const ChatResponse({
    required this.reply,
    required this.gameIds,
    required this.sessionId,
  });

  final String reply;
  final List<String> gameIds;
  final String sessionId;
}

/// The RAG assistant's transport seam (docs/ml-workflows.md §1.6). The controller
/// depends on this abstraction, not on `supabase.functions` directly, so a future
/// on-device implementation can slot in without touching the UI or controller.
///
/// Only [EdgeFunctionChatBackend] ships today. A future `WebLlmChatBackend` would
/// embed the query in-browser (transformers.js gte-small), call the `match_games`
/// RPC directly (it is under RLS, safe from the client), assemble the same
/// grounded prompt (porting the server prompt-builder to Dart), and run a local
/// WebGPU model — no server round trip. The WebGPU integration is out of demo
/// scope; the server pieces it needs (the RPC, RLS) already ship in M5.
abstract interface class ChatBackend {
  Future<ChatResponse> send({required String message, String? sessionId});
}

/// Invokes the `rag-chat` Edge Function. Keeps the `functions.invoke` call out of
/// widgets and the controller — they only ever see [ChatResponse].
class EdgeFunctionChatBackend implements ChatBackend {
  EdgeFunctionChatBackend(this._client);

  final SupabaseClient _client;

  @override
  Future<ChatResponse> send({required String message, String? sessionId}) async {
    final res = await _client.functions.invoke(
      'rag-chat',
      body: {
        'message': message,
        if (sessionId != null) 'sessionId': sessionId,
      },
    );

    final data = res.data as Map<String, dynamic>?;
    if (data == null || data['reply'] is! String || data['sessionId'] is! String) {
      throw Exception('Assistant returned an unexpected response.');
    }

    return ChatResponse(
      reply: data['reply'] as String,
      gameIds: (data['game_ids'] as List?)?.cast<String>() ?? const [],
      sessionId: data['sessionId'] as String,
    );
  }
}

final chatBackendProvider = Provider<ChatBackend>((ref) {
  return EdgeFunctionChatBackend(supabase);
});
