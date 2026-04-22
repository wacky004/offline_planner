import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'bullet.dart';
import '../space_game.dart';

class Player extends PositionComponent with HasGameRef<SpaceGame> {
  static const double playerSize = 40.0;
  final Paint _paint = Paint()..color = Colors.blueAccent;

  Player() : super(size: Vector2.all(playerSize), anchor: Anchor.center);

  @override
  void onLoad() {
    position = Vector2(gameRef.size.x / 2, gameRef.size.y - 60);
  }

  @override
  void render(Canvas canvas) {
    // Draw a simple triangle for the spaceship
    final path = Path()
      ..moveTo(size.x / 2, 0)
      ..lineTo(size.x, size.y)
      ..lineTo(0, size.y)
      ..close();
    canvas.drawPath(path, _paint);
  }

  void moveLeft() {
    position.x -= 20;
    if (position.x < size.x / 2) position.x = size.x / 2;
  }

  void moveRight() {
    position.x += 20;
    if (position.x > gameRef.size.x - size.x / 2) {
      position.x = gameRef.size.x - size.x / 2;
    }
  }

  void shoot() {
    final bullet = Bullet()
      ..position = position.clone() - Vector2(0, size.y / 2);
    gameRef.add(bullet);
  }
}
