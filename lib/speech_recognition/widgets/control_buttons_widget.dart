import 'package:flutter/material.dart';

class ControlButtonsWidget extends StatelessWidget {
  final bool isRecording;
  final bool hasText;
  final VoidCallback onToggleRecording;
  final VoidCallback onClearText;

  const ControlButtonsWidget({
    super.key,
    required this.isRecording,
    required this.hasText,
    required this.onToggleRecording,
    required this.onClearText,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: FilledButton.icon(
              onPressed: onToggleRecording,
              icon: Icon(isRecording ? Icons.stop : Icons.mic),
              label: Text(isRecording ? 'Stop' : 'Record'),
              style: const ButtonStyle(
                padding: WidgetStatePropertyAll(
                  EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: hasText ? onClearText : null,
              icon: const Icon(Icons.clear),
              label: const Text('Clear'),
              style: const ButtonStyle(
                padding: WidgetStatePropertyAll(
                  EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
