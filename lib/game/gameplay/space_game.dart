import 'dart:math';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'components/player.dart';
import 'components/enemy.dart';

class SpaceGame extends FlameGame with HasCollisionDetection, TapDetector {
  late Player player;
  int score = 0;
  bool isGameOver = false;
  double _enemySpawnTimer = 0.0;
  final Random _random = Random();
  final VoidCallback onGameOverCallback;
  final void Function(int) onScoreChanged;

  SpaceGame({required this.onGameOverCallback, required this.onScoreChanged});

  @override
  Future<void> onLoad() async {
    player = Player();
    add(player);
  }

  @override
  void update(double dt) {
    if (isGameOver) return;
    super.update(dt);

    _enemySpawnTimer += dt;
    if (_enemySpawnTimer > 1.5) {
      _spawnEnemy();
      _enemySpawnTimer = 0.0;
    }
  }

  void _spawnEnemy() {
    final enemy = Enemy();
    enemy.position = Vector2(
      _random.nextDouble() * (size.x - Enemy.enemySize) + Enemy.enemySize / 2,
      -Enemy.enemySize,
    );
    add(enemy);
  }

  void increaseScore() {
    if (isGameOver) return;
    score += 10;
    onScoreChanged(score);
  }

  void gameOver() {
    if (isGameOver) return;
    isGameOver = true;
    onGameOverCallback();
  }

  @override
  void onTapDown(TapDownInfo info) {
    if (isGameOver) return;
    // Tapping on left side moves left, right side moves right.
    // Tapping near center shoots.
    final touchX = info.eventPosition.widget.x;
    if (touchX < size.x * 0.3) {
      player.moveLeft();
    } else if (touchX > size.x * 0.7) {
      player.moveRight();
    } else {
      player.shoot();
    }
  }
}
