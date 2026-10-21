import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double size;

  const AppLogo({super.key, this.size = 88});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.22),
      child: Image.asset(
        'assets/images/logo.png',
        width: size,
        height: size,
        errorBuilder: (context, error, stackTrace) => Icon(
          Icons.school,
          size: size,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}