import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/review.dart';
import '../../application/game_detail_controller.dart';

/// Bottom sheet to write or edit a review. Pass [existing] to pre-fill for an
/// edit; omit it to write a new one. Upsert on the backend handles both.
class WriteReviewSheet extends ConsumerStatefulWidget {
  const WriteReviewSheet({super.key, required this.gameId, this.existing});

  final String gameId;
  final Review? existing;

  @override
  ConsumerState<WriteReviewSheet> createState() => _WriteReviewSheetState();
}

class _WriteReviewSheetState extends ConsumerState<WriteReviewSheet> {
  late final TextEditingController _bodyController;
  late double _rating;
  late bool _containsSpoilers;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _bodyController = TextEditingController(text: existing?.body ?? '');
    _rating = existing?.rating ?? 7;
    _containsSpoilers = existing?.containsSpoilers ?? false;
  }

  @override
  void dispose() {
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(isEdit ? 'Edit your review' : 'Write a review',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _bodyController,
            maxLines: 5,
            maxLength: 10000,
            decoration: const InputDecoration(hintText: 'What did you think?'),
          ),
          Row(
            children: [
              const Text('Rating'),
              Expanded(
                child: Slider(
                  value: _rating,
                  min: 0,
                  max: 10,
                  divisions: 20,
                  label: _rating.toStringAsFixed(1),
                  onChanged: (v) => setState(() => _rating = v),
                ),
              ),
            ],
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Contains spoilers'),
            value: _containsSpoilers,
            onChanged: (v) => setState(() => _containsSpoilers = v),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () async {
              await ref.read(gameDetailActionsProvider).submitReview(
                    widget.gameId,
                    _bodyController.text,
                    rating: _rating,
                    containsSpoilers: _containsSpoilers,
                  );
              if (context.mounted) Navigator.of(context).pop();
            },
            child: Text(isEdit ? 'Save changes' : 'Submit review'),
          ),
        ],
      ),
    );
  }
}
