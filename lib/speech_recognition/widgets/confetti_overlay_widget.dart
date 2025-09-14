import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';

class ConfettiOverlayWidget extends StatelessWidget {
  final ConfettiController confettiController;

  const ConfettiOverlayWidget({super.key, required this.confettiController});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConfettiWidget(
        confettiController: confettiController,
        blastDirection: 1.5708,
        blastDirectionality: BlastDirectionality.explosive,
        shouldLoop: false,
        colors: const [
          Colors.red,
          Colors.blue,
          Colors.green,
          Colors.yellow,
          Colors.pink,
          Colors.orange,
          Colors.purple,
        ],
      ),
    );
  }
}
