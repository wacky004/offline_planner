import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../game/providers/game_provider.dart';

class GameOverScreen extends StatelessWidget {
  final int score;

  const GameOverScreen({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();
    final session = provider.currentSession;
    final isNewHighScore = score > 0 && score >= session.highScore;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'GAME OVER',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w900,
                color: Colors.redAccent,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Score: $score',
              style: const TextStyle(
                fontSize: 32,
                color: Colors.white,
              ),
            ),
            if (isNewHighScore) ...[
              const SizedBox(height: 16),
              const Text(
                'NEW HIGH SCORE!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
            ],
            const SizedBox(height: 64),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.home_rounded),
              label: const Text('Back to Base'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                textStyle: const TextStyle(fontSize: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
