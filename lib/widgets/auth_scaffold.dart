import 'package:flutter/material.dart';

/// Shared page shell for login, registration and password screens.
class AuthScaffold extends StatelessWidget {
  final String? appBarTitle;
  final List<Widget> children;

  const AuthScaffold({super.key, this.appBarTitle, required this.children});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarTitle == null ? null : AppBar(title: Text(appBarTitle!)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
