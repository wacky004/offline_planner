import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:provider/provider.dart';
import '../../game/providers/game_provider.dart';
import '../gameplay/space_game.dart';
import 'game_over_screen.dart';

class GameplayScreen extends StatefulWidget {
  final GameDifficulty difficulty;

  const GameplayScreen({super.key, required this.difficulty});

  @override
  State<GameplayScreen> createState() => _GameplayScreenState();
}

class _GameplayScreenState extends State<GameplayScreen> {
  late SpaceGame _game;
  int _currentScore = 0;
  int _currentWave = 1;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _game = SpaceGame(
      difficulty: widget.difficulty,
      onScoreChanged: (score) {
        setState(() {
          _currentScore = score;
        });
      },
      onWaveChanged: (wave) {
        setState(() {
          _currentWave = wave;
        });
      },
      onGameOverCallback: () async {
        final provider = context.read<GameProvider>();
        await provider.updateHighScore(_currentScore);
        
        final coinsEarned = _currentScore ~/ 10;
        if (coinsEarned > 0) {
          await provider.addCoins(coinsEarned);
        }

        // Slight delay to let the user see the collision
        await Future.delayed(const Duration(milliseconds: 500));
        
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => GameOverScreen(
              score: _currentScore,
              coinsEarned: coinsEarned,
            ),
          ),
        );
      },
    );
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
      if (_isPaused) {
        _game.pauseEngine();
      } else {
        _game.resumeEngine();
      }
    });
  }

  void _restartGame() {
    setState(() {
      _isPaused = false;
      _currentScore = 0;
      _currentWave = 1;
      _game.reset();
      _game.resumeEngine();
    });
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Score: $_currentScore',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Wave: $_currentWave',
                    style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause, color: Colors.white),
                    onPressed: _togglePause,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
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
            if (_isPaused)
              Container(
                color: Colors.black.withValues(alpha: 0.7),
                child: Center(
                  child: Card(
                    color: Colors.grey.shade900,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 48.0, vertical: 32.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'PAUSED',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 32),
                          FilledButton.icon(
                            onPressed: _togglePause,
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Resume'),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(200, 50),
                            ),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: _restartGame,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Restart'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              minimumSize: const Size(200, 50),
                              side: const BorderSide(color: Colors.white38),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            icon: const Icon(Icons.exit_to_app, color: Colors.redAccent),
                            label: const Text('Exit Game', style: TextStyle(color: Colors.redAccent)),
                            style: TextButton.styleFrom(
                              minimumSize: const Size(200, 50),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
