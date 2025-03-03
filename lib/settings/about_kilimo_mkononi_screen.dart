import 'package:flutter/material.dart';

class AboutKilimoMkononiScreen extends StatelessWidget {
  const AboutKilimoMkononiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About Kilimo Mkononi'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'About Kilimo Mkononi',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              const Text(
                'Kilimo Mkononi is an app designed to empower farmers with tools '
                'and information to improve agricultural productivity. Our mission '
                'is to connect farmers to markets, provide weather updates, and '
                'offer expert advice—all in the palm of your hand.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}