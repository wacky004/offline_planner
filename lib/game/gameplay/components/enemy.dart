import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import '../space_game.dart';
import 'player.dart';

class Enemy extends PositionComponent with HasGameRef<SpaceGame>, CollisionCallbacks {
  static const double enemySize = 30.0;
  final double speed;
  final Paint _paint = Paint()..color = Colors.redAccent;

  Enemy({required this.speed}) : super(size: Vector2.all(enemySize), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.y += speed * dt;

    if (position.y > gameRef.size.y + size.y) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(size.toRect(), _paint);
  }

  void takeHit() {
    removeFromParent();
    gameRef.increaseScore();
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is Player) {
      gameRef.gameOver();
    }
  }
}
