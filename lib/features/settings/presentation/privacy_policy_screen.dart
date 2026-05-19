import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy policy')),
      body: const Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'This is a placeholder privacy policy screen for the MVP. '
          'Replace it with the final published policy before store submission.',
        ),
      ),
    );
  }
}
