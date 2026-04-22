import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:provider/provider.dart';
import '../../game/providers/game_provider.dart';
import '../gameplay/space_game.dart';
import 'game_over_screen.dart';

class GameplayScreen extends StatefulWidget {
  const GameplayScreen({super.key});

  @override
  State<GameplayScreen> createState() => _GameplayScreenState();
}

class _GameplayScreenState extends State<GameplayScreen> {
  late SpaceGame _game;
  int _currentScore = 0;

  @override
  void initState() {
    super.initState();
    _game = SpaceGame(
      onScoreChanged: (score) {
        setState(() {
          _currentScore = score;
        });
      },
      onGameOverCallback: () async {
        final provider = context.read<GameProvider>();
        await provider.updateHighScore(_currentScore);
        
        // Slight delay to let the user see the collision
        await Future.delayed(const Duration(milliseconds: 500));
        
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => GameOverScreen(score: _currentScore),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            GameWidget(game: _game),
            Positioned(
              top: 16,
              left: 16,
              child: Text(
                'Score: $_currentScore',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ),
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  const Text('TAP LEFT = Move Left', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  const Text('TAP CENTER = Shoot', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  const Text('TAP RIGHT = Move Right', style: TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
