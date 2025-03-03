import 'package:flutter/material.dart';

class FAQScreen extends StatelessWidget {
  const FAQScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Knowledge Base/FAQ'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Frequently Asked Questions',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              const Text(
                'Q: How do I reset my password?\n'
                'A: Go to the Account section in Settings and select "Change Password".\n\n'
                'Q: Where can I find crop prices?\n'
                'A: Check the main dashboard for real-time market updates.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}