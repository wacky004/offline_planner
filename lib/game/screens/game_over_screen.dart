import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../game/providers/game_provider.dart';

class GameOverScreen extends StatelessWidget {
  final int score;
  final int coinsEarned;

  const GameOverScreen({super.key, required this.score, this.coinsEarned = 0});

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
            if (coinsEarned > 0) ...[
              const SizedBox(height: 24),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '+',
                    style: TextStyle(fontSize: 24, color: Colors.white70, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.monetization_on_rounded, size: 36, color: Colors.yellow.shade700),
                  const SizedBox(width: 8),
                  Text(
                    '$coinsEarned',
                    style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
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
