import 'dart:math';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'components/player.dart';
import 'components/enemy.dart';
import 'components/bullet.dart';
import 'components/boss.dart';
import 'components/boss_bullet.dart';

enum GameDifficulty { easy, normal }

class SpaceGame extends FlameGame with HasCollisionDetection, TapDetector {
  late Player player;
  int score = 0;
  int wave = 1;
  bool isGameOver = false;
  bool isBossActive = false;
  int _lastBossWave = 0;
  double _enemySpawnTimer = 0.0;
  final Random _random = Random();
  
  final GameDifficulty difficulty;
  final VoidCallback onGameOverCallback;
  final void Function(int) onScoreChanged;
  final void Function(int) onWaveChanged;

  SpaceGame({
    required this.difficulty,
    required this.onGameOverCallback,
    required this.onScoreChanged,
    required this.onWaveChanged,
  });

  @override
  Future<void> onLoad() async {
    player = Player();
    add(player);
  }

  @override
  void update(double dt) {
    if (isGameOver) return;
    super.update(dt);

    // Check for Boss Spawn (Every 5 waves)
    if (wave % 5 == 0 && wave != _lastBossWave && !isBossActive) {
      _spawnBoss();
      return; // Stop normal spawning logic this frame
    }

    if (isBossActive) return; // Don't spawn normal enemies during boss fight

    _enemySpawnTimer += dt;
    
    // Calculate spawn rate based on difficulty and wave
    double spawnThreshold = difficulty == GameDifficulty.easy ? 2.0 : 1.5;
    spawnThreshold = max(0.5, spawnThreshold - (wave * 0.1));

    if (_enemySpawnTimer > spawnThreshold) {
      _spawnEnemy();
      _enemySpawnTimer = 0.0;
    }
  }

  void _spawnEnemy() {
    // Calculate speed based on difficulty and wave
    double baseSpeed = difficulty == GameDifficulty.easy ? 80.0 : 120.0;
    double speed = baseSpeed + (wave * 20.0);

    final enemy = Enemy(speed: speed);
    enemy.position = Vector2(
      _random.nextDouble() * (size.x - Enemy.enemySize) + Enemy.enemySize / 2,
      -Enemy.enemySize,
    );
    add(enemy);
  }

  void _spawnBoss() {
    isBossActive = true;
    final int maxHp = difficulty == GameDifficulty.easy ? 10 : 20 + (wave * 2);
    final boss = Boss(maxHp: maxHp);
    add(boss);
  }

  void onBossDefeated() {
    isBossActive = false;
    _lastBossWave = wave;
    score += 500; // Large score reward = 50 coins!
    onScoreChanged(score);

    // Force wave progression since we defeated the boss
    int newWave = (score ~/ 100) + 1;
    if (newWave > wave) {
      wave = newWave;
      onWaveChanged(wave);
    }
  }

  void increaseScore() {
    if (isGameOver) return;
    score += 10;
    onScoreChanged(score);

    // Wave progression: Every 100 points, wave increases
    int newWave = (score ~/ 100) + 1;
    if (newWave > wave) {
      wave = newWave;
      onWaveChanged(wave);
    }
  }

  void gameOver() {
    if (isGameOver) return;
    isGameOver = true;
    onGameOverCallback();
  }

  void reset() {
    isGameOver = false;
    isBossActive = false;
    _lastBossWave = 0;
    score = 0;
    wave = 1;
    _enemySpawnTimer = 0.0;
    onScoreChanged(score);
    onWaveChanged(wave);

    children.whereType<Enemy>().forEach((e) => e.removeFromParent());
    children.whereType<Bullet>().forEach((b) => b.removeFromParent());
    children.whereType<Boss>().forEach((b) => b.removeFromParent());
    children.whereType<BossBullet>().forEach((b) => b.removeFromParent());

    player.position = Vector2(size.x / 2, size.y - 60);
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
