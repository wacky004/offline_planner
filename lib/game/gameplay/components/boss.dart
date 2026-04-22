import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import '../space_game.dart';
import 'player.dart';
import 'boss_bullet.dart';

class Boss extends PositionComponent with HasGameRef<SpaceGame>, CollisionCallbacks {
  static const double bossSize = 80.0;
  int hp;
  final int maxHp;
  double _moveDirection = 1.0;
  final double speed = 100.0;
  double _shootTimer = 0.0;
  final Paint _paint = Paint()..color = Colors.purpleAccent;

  Boss({required this.maxHp}) : hp = maxHp, super(size: Vector2.all(bossSize), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    add(RectangleHitbox());
    position = Vector2(gameRef.size.x / 2, bossSize);
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    position.x += speed * _moveDirection * dt;
    if (position.x > gameRef.size.x - size.x / 2) {
      position.x = gameRef.size.x - size.x / 2;
      _moveDirection = -1.0;
    } else if (position.x < size.x / 2) {
      position.x = size.x / 2;
      _moveDirection = 1.0;
    }

    _shootTimer += dt;
    if (_shootTimer > 0.8) {
      _shoot();
      _shootTimer = 0.0;
    }
  }

  void _shoot() {
    final bullet = BossBullet()
      ..position = position.clone() + Vector2(0, size.y / 2);
    gameRef.add(bullet);
  }

  @override
  void render(Canvas canvas) {
    // Draw boss body
    final path = Path()
      ..moveTo(size.x / 2, size.y)
      ..lineTo(size.x, size.y / 2)
      ..lineTo(size.x, 0)
      ..lineTo(0, 0)
      ..lineTo(0, size.y / 2)
      ..close();
    canvas.drawPath(path, _paint);

    // Draw HP bar
    final double hpRatio = hp / maxHp;
    final Paint hpBgPaint = Paint()..color = Colors.red;
    final Paint hpFillPaint = Paint()..color = Colors.green;
    
    final Rect hpBgRect = Rect.fromLTWH(0, -15, size.x, 8);
    final Rect hpFillRect = Rect.fromLTWH(0, -15, size.x * hpRatio, 8);
    
    canvas.drawRect(hpBgRect, hpBgPaint);
    canvas.drawRect(hpFillRect, hpFillPaint);
  }

  void takeHit() {
    hp--;
    if (hp <= 0) {
      removeFromParent();
      gameRef.onBossDefeated();
    }
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is Player) {
      gameRef.gameOver();
    }
  }
}
