import 'package:flutter/material.dart';
import '../../../models/event.dart';
import '../../../theme/theme_provider.dart';

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
    // Check if this is an AI-suggested event by looking at the ID prefix
    final isAISuggested = event.id.startsWith('suggested_');

    if (!isAISuggested) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      margin: const EdgeInsets.only(left: 8),
      decoration: BoxDecoration(
        color: ThemeProvider.notionBlue.withOpacity(isDarkMode ? 0.3 : 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: ThemeProvider.notionBlue.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.auto_awesome,
            size: 12,
            color: ThemeProvider.notionBlue,
          ),
          const SizedBox(width: 4),
          Text(
            'AI',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: ThemeProvider.notionBlue,
            ),
          ),
        ],
      ),
    );
  }
}
