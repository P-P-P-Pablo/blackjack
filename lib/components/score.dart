import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../blackjack_game.dart';

class Scores extends PositionComponent
    with HasGameReference<BlackJackGame> {
  @override
  void onLoad() {
    final scoreRenderer = TextPaint(
      style: TextStyle(
        fontSize: 0.7 * size.y,
        fontWeight: FontWeight.bold,
        color: Colors.amber,
      ),
    );
    add(
      TextComponent(
        text: 'Hello, Flame',
        textRenderer: scoreRenderer,
        anchor: Anchor.topCenter,
        position: Vector2(
            game.size.x / 2,
            game.size.y -
                BlackJackGame.cardHeight -
                BlackJackGame.borderGap -
                size.y),
      ),
    );
    add(
      TextComponent(
        text: 'Hello, Flame',
        textRenderer: scoreRenderer,
        anchor: Anchor.topCenter,
        position: Vector2(
            game.size.x / 2,
            BlackJackGame.cardHeight +
                BlackJackGame.borderGap),
      ),
    );
  }
}
