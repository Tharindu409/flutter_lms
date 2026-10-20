import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

enum MessageType { info, success, error }

class MessageBanner extends StatelessWidget {
  final String message;
  final MessageType type;

  const MessageBanner({
    super.key,
    required this.message,
    this.type = MessageType.info,
  });

  @override
  Widget build(BuildContext context) {
    final Color color;
    final IconData icon;
    switch (type) {
      case MessageType.success:
        color = AppTheme.success;
        icon = Icons.check_circle_outline;
      case MessageType.error:
        color = AppTheme.error;
        icon = Icons.error_outline;
      case MessageType.info:
        color = AppTheme.info;
        icon = Icons.info_outline;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppTheme.mediumRadius,
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: color, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
