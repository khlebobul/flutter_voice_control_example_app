import 'package:flutter/material.dart';

class TextDisplayWidget extends StatelessWidget {
  final String text;

  const TextDisplayWidget({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        reverse: true,
        child: SelectableText(
          text,
          textAlign: TextAlign.left,
          style: const TextStyle(fontSize: 16, height: 1.4),
        ),
      ),
    );
  }
}
