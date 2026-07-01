import 'package:flutter/material.dart';

import '../../data/models/completion_status.dart';

class CompletionBadge extends StatelessWidget {
  const CompletionBadge({super.key, required this.status});

  final CompletionStatus status;

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text(status.label));
  }
}
