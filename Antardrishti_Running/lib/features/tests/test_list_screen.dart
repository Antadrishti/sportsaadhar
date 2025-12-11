import 'package:flutter/material.dart';

import 'data/demo_tests.dart';

class TestListScreen extends StatelessWidget {
  const TestListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Test')),
      body: ListView.separated(
        itemCount: demoTests.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final t = demoTests[index];
          return ListTile(
            title: Text(t.name),
            subtitle: Text(t.description),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.pushNamed(
                context,
                '/record-test',
                arguments: t.name,
              );
            },
          );
        },
      ),
    );
  }
}
