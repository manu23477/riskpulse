import 'package:flutter/material.dart';

class CurrentRiskScreen extends StatelessWidget {
  const CurrentRiskScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Current Risk'),
      ),
      body: const Center(
        child: Text(
          'Current Risk analysis will appear here',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}