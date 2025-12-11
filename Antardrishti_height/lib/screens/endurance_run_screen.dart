// Endurance Run Test Screen (800m for U-12, 1.6km for 12+)
// TODO: Implement this test
import 'package:flutter/material.dart';

class EnduranceRunScreen extends StatelessWidget {
  const EnduranceRunScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Endurance Run')),
      body: const Center(child: Text('Coming Soon\n800m for U-12 | 1.6km for 12+')),
    );
  }
}
