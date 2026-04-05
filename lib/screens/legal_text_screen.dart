import 'package:flutter/material.dart';

class LegalTextScreen extends StatelessWidget {
  final String title;
  final String content;

  const LegalTextScreen({
    super.key,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Text(
          content,
          style: const TextStyle(
            fontSize: 15,
            height: 1.6,
          ),
        ),
      ),
    );
  }
}
