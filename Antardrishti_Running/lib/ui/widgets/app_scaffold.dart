import 'package:flutter/material.dart';

class AppScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;
  final bool gradient;

  const AppScaffold({super.key, this.appBar, required this.body, this.floatingActionButton, this.gradient = false});

  @override
  Widget build(BuildContext context) {
    final content = Scaffold(
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: body,
        ),
      ),
    );

    if (!gradient) return content;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFe8f9f0), Color(0xFFffffff)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: content,
    );
  }
}
