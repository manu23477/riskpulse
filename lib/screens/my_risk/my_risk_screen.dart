import 'package:flutter/material.dart';

class MyRiskScreen extends StatelessWidget {
  const MyRiskScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Risk'),
      ),
      body: const Center(
        child: Text(
          'Personal risk assessment will appear here',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}