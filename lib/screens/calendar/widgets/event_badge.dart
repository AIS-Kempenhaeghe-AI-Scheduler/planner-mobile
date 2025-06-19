import 'package:flutter/material.dart';
import '../../../models/event.dart';

class EventBadge extends StatelessWidget {
  final Event event;
  final bool isDarkMode;

  const EventBadge({
    super.key,
    required this.event,
    required this.isDarkMode,
  });
  @override
  Widget build(BuildContext context) {
    // AI suggestions have been removed, so this badge is no longer needed
    return const SizedBox.shrink();
  }
}
