import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../bootstrap.dart';
import '../../core/errors/failure.dart';

/// Owns Supabase Storage calls for the `avatars` bucket. Kept separate from
/// ProfilesRepository because Storage and the `profiles` table are distinct
/// backends; the caller wires them together (upload here → write avatar_url via
/// ProfilesRepository).
class AvatarsRepository {
  AvatarsRepository(this._client);

  final SupabaseClient _client;

  static const bucket = 'avatars';
  static const maxBytes = 2 * 1024 * 1024; // 2 MB — mirrors the bucket's file_size_limit.

  // Allowed content types (mirrors the bucket's allowed_mime_types) mapped to
  // the file extension used in the object path.
  static const _extForContentType = {
    'image/png': 'png',
    'image/jpeg': 'jpg',
    'image/webp': 'webp',
  };

  /// Validates then uploads [bytes] to `avatars/{userId}/avatar.{ext}` and
  /// returns the public URL. The RLS policy (migration 0011) requires the first
  /// path segment to equal the caller's uid, so [userId] must be the signed-in
  /// user. Uses a fixed object name so re-uploads overwrite the previous avatar.
  ///
  /// The bucket also enforces size and content-type server-side; validating here
  /// gives an immediate error and avoids a wasted round-trip.
  Future<String> uploadAvatar({
    required String userId,
    required Uint8List bytes,
    required String contentType,
  }) async {
    final ext = _extForContentType[contentType];
    if (ext == null) {
      throw const ValidationFailure('Avatar must be a PNG, JPEG, or WebP image');
    }
    if (bytes.length > maxBytes) {
      throw const ValidationFailure('Avatar must be 2 MB or smaller');
    }

    final path = '$userId/avatar.$ext';
    try {
      await _client.storage.from(bucket).uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: contentType, upsert: true),
          );
    } on StorageException catch (e) {
      throw ValidationFailure(e.message);
    }

    // Cache-bust so the CDN/browser fetches the new image after an overwrite.
    final publicUrl = _client.storage.from(bucket).getPublicUrl(path);
    return '$publicUrl?v=${DateTime.now().millisecondsSinceEpoch}';
  }
}

final avatarsRepositoryProvider = Provider<AvatarsRepository>((ref) {
  return AvatarsRepository(supabase);
});
