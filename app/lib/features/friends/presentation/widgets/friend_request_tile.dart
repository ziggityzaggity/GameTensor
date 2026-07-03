import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../data/models/friendship.dart';

/// A single friend-request row, reused for both the incoming and outgoing
/// lists. The two lists differ only in their trailing action(s), which the
/// caller supplies via [trailing]. Tapping the row opens the other user's
/// profile.
class FriendRequestTile extends StatelessWidget {
  const FriendRequestTile({
    super.key,
    required this.request,
    required this.trailing,
  });

  final FriendRequest request;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage:
            request.avatarUrl != null ? NetworkImage(request.avatarUrl!) : null,
        child: request.avatarUrl == null ? const Icon(Icons.person) : null,
      ),
      title: Text(request.label),
      subtitle: request.username != null ? Text('@${request.username}') : null,
      trailing: trailing,
      onTap: request.username != null
          ? () => context.push(RoutePaths.profilePath(request.username!))
          : null,
    );
  }
}
