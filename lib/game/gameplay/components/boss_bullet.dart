import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import '../space_game.dart';
import 'player.dart';

class BossBullet extends PositionComponent with HasGameRef<SpaceGame>, CollisionCallbacks {
  static const double bulletSpeed = 300.0;
  final Paint _paint = Paint()..color = Colors.orangeAccent;

  BossBullet() : super(size: Vector2(10, 20), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.y += bulletSpeed * dt;

    if (position.y > gameRef.size.y + size.y) {
      removeFromParent();
    }
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is Player) {
      removeFromParent();
      gameRef.gameOver();
    }
  }

  @override
  void render(Canvas canvas) {
    final path = Path()
      ..moveTo(size.x / 2, 0)
      ..lineTo(size.x, size.y / 2)
      ..lineTo(size.x / 2, size.y)
      ..lineTo(0, size.y / 2)
      ..close();
    canvas.drawPath(path, _paint);
  }
}
