import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/user_game_log.dart';
import '../../../../data/repositories/lookups_repository.dart';
import '../../application/game_detail_controller.dart';

class LogStatusSheet extends ConsumerStatefulWidget {
  const LogStatusSheet({super.key, required this.gameId, this.existingLog});

  final String gameId;
  final UserGameLog? existingLog;

  @override
  ConsumerState<LogStatusSheet> createState() => _LogStatusSheetState();
}

class _LogStatusSheetState extends ConsumerState<LogStatusSheet> {
  late int? _selectedStatusId = widget.existingLog?.completionStatusId;
  late bool? _liked = widget.existingLog?.liked;

  @override
  Widget build(BuildContext context) {
    final statuses = ref.watch(completionStatusesProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Completion status', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          statuses.when(
            data: (items) => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: items
                  .map((s) => ChoiceChip(
                        label: Text(s.label),
                        selected: _selectedStatusId == s.id,
                        onSelected: (_) => setState(() => _selectedStatusId = s.id),
                      ))
                  .toList(),
            ),
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('Failed to load statuses: $e'),
          ),
          const SizedBox(height: 16),
          Text('Like / dislike', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.thumb_up, color: _liked == true ? Colors.green : null),
                onPressed: () => setState(() => _liked = _liked == true ? null : true),
              ),
              IconButton(
                icon: Icon(Icons.thumb_down, color: _liked == false ? Colors.red : null),
                onPressed: () => setState(() => _liked = _liked == false ? null : false),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _selectedStatusId == null
                ? null
                : () async {
                    await ref.read(gameDetailActionsProvider).setCompletionStatus(
                          widget.gameId,
                          _selectedStatusId!,
                          liked: _liked,
                        );
                    if (context.mounted) Navigator.of(context).pop();
                  },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
