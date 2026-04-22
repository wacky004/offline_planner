import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import '../space_game.dart';
import 'enemy.dart';

class Bullet extends PositionComponent with HasGameRef<SpaceGame>, CollisionCallbacks {
  static const double bulletSpeed = 400.0;
  final Paint _paint = Paint()..color = Colors.yellow;

  Bullet() : super(size: Vector2(4, 15), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.y -= bulletSpeed * dt;

    if (position.y < -size.y) {
      removeFromParent();
    }
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is Enemy) {
      removeFromParent();
      other.takeHit();
    }
  }
}
