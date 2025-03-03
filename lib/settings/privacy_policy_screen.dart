import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                'Privacy Policy',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),

              // Last Updated
              const Text(
                'Last updated: February 25, 2025',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 16),

              // Introduction
              const Text(
                'This privacy notice for KILIMO MKONONI describes how and why we might collect, store, use, and/or process your information when you use our services.',
              ),
              const SizedBox(height: 16),

              // Table of Contents
              Text(
                'Table of Contents',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTocItem(context, '1. When We Collect Information'),
                  _buildTocItem(context, '2. Your Privacy Rights and Choices'),
                  _buildTocItem(context, '3. Contact Us'),
                ],
              ),
              const SizedBox(height: 16),

              // Section 1: When We Collect Information
              Text(
                '1. When We Collect Information',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBulletPoint(
                    'Download and use our mobile application (Kilimo Mkononi) or any other application of ours that links to this privacy notice.',
                  ),
                  _buildBulletPoint(
                    'Engage with us in other related ways, including marketing and community initiatives.',
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Section 2: Your Privacy Rights and Choices
              Text(
                '2. Your Privacy Rights and Choices',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  style: Theme.of(context).textTheme.bodyMedium,
                  children: [
                    const TextSpan(
                      text: 'Questions or concerns? Reading this privacy notice will help you understand your ',
                    ),
                    TextSpan(
                      text: 'privacy rights and choices',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const TextSpan(
                      text: '. If you do not agree with our policies and practices, please do not use our Services.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Section 3: Contact Us
              Text(
                '3. Contact Us',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  style: Theme.of(context).textTheme.bodyMedium,
                  children: [
                    const TextSpan(
                      text: 'If you still have questions or concerns, please contact us at ',
                    ),
                    TextSpan(
                      text: 'contact@kilimomkononi.com',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue, // Optional: make it stand out
                      ),
                    ),
                    const TextSpan(text: '.'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method for Table of Contents items
  Widget _buildTocItem(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.blue, // Optional: make clickable-looking
            ),
      ),
    );
  }

  // Helper method for bullet points
  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 16)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}