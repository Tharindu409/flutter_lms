import 'package:flutter/material.dart';

/// Shows a progress value that was calculated by the backend (0 to 100).
class ProgressBar extends StatelessWidget {
  final double? percent;

  const ProgressBar({super.key, required this.percent});

  @override
  Widget build(BuildContext context) {
    final value = percent == null
        ? null
        : (percent! / 100).clamp(0.0, 1.0).toDouble();
    if (percent == null) {
      return Text('--', style: Theme.of(context).textTheme.labelMedium);
    }

    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(value: value, minHeight: 8),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '${percent!.round()}%',
          style: Theme.of(context).textTheme.labelMedium,
        ),
      ],
    );
  }
}
