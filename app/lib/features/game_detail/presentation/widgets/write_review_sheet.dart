import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/game_detail_controller.dart';

class WriteReviewSheet extends ConsumerStatefulWidget {
  const WriteReviewSheet({super.key, required this.gameId});

  final String gameId;

  @override
  ConsumerState<WriteReviewSheet> createState() => _WriteReviewSheetState();
}

class _WriteReviewSheetState extends ConsumerState<WriteReviewSheet> {
  final _bodyController = TextEditingController();
  double _rating = 7;

  @override
  void dispose() {
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          Text('Write a review', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _bodyController,
            maxLines: 5,
            decoration: const InputDecoration(hintText: 'What did you think?'),
          ),
          const SizedBox(height: 8),
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
          FilledButton(
            onPressed: () async {
              await ref
                  .read(gameDetailActionsProvider)
                  .submitReview(widget.gameId, _bodyController.text, rating: _rating);
              if (context.mounted) Navigator.of(context).pop();
            },
            child: const Text('Submit review'),
          ),
        ],
      ),
    );
  }
}
