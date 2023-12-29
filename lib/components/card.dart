import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flutter/animation.dart';

import '../blackjack_game.dart';
import '../blackjack_world.dart';
import '../models/pile.dart';
import '../models/player.dart';
import '../models/rank.dart';
import '../models/suit.dart';

class Card extends PositionComponent
    with
        DragCallbacks,
        TapCallbacks,
        HasWorldReference<BlackJackWorld> {
  /* @override
  bool get debugMode => true; */

  Card(int intRank, int intSuit, this.backNumber)
      : rank = Rank.fromInt(intRank),
        suit = Suit.fromInt(intSuit),
        super(
          size: BlackJackGame.cardSize,
        );

  final Rank rank;
  final Suit suit;
  final int backNumber;
  Pile? pile;
  Player? player;

  bool _faceUp = false;
  bool _isAnimatedFlip = false;
  bool _isFaceUpView = false;

  final List<Card> attachedCards = [];

  bool get isFaceUp => _faceUp;
  bool get isFaceDown => !_faceUp;
  void basicFlip() {
    if (_isAnimatedFlip) {
      // Let the animation determine the FaceUp/FaceDown state.
      _faceUp = _isFaceUpView;
    } else {
      // No animation: flip and render the card immediately.
      _faceUp = !_faceUp;
      _isFaceUpView = _faceUp;
    }
  }

  @override
  String toString() =>
      rank.label + suit.label; // e.g. "Q♠" or "10♦"

  //#region Rendering

  @override
  void render(Canvas canvas) {
    if (_isFaceUpView) {
      _renderFront(canvas);
    } else {
      _renderBack(canvas);
    }
  }

  static final Paint backBorderPaint1 = Paint()
    ..color = const Color(0xffdbaf58)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 10;

  static final RRect cardRRect = RRect.fromRectAndRadius(
    BlackJackGame.cardSize.toRect(),
    const Radius.circular(BlackJackGame.cardRadius),
  );

  double spriteWidth = 102;
  double spriteHeight = 144;

  void _renderBack(Canvas canvas) {
    double spriteX = 0;
    double spriteY = 0;

    switch (backNumber) {
      case 1:
        spriteX = 0;
        spriteY = 0;
        break;
      case 2:
        spriteX = 102;
        spriteY = 0;
        break;
      case 3:
        spriteX = 204;
        spriteY = 0;
        break;
      case 4:
        spriteX = 306;
        spriteY = 0;
        break;
      case 5:
        spriteX = 0;
        spriteY = 144;
        break;
      case 6:
        spriteX = 102;
        spriteY = 144;
        break;
      case 7:
        spriteX = 204;
        spriteY = 144;
        break;
      case 8:
        spriteX = 306;
        spriteY = 144;
        break;
    }

    final Sprite cardFrontSprite = backSprite(
        spriteX, spriteY, spriteWidth, spriteHeight);
    _drawSprite(canvas, cardFrontSprite, 0.5, 0.5);
  }

  static final Paint redBorderPaint = Paint()
    ..color = const Color(0xffece8a3)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 10;
  static final Paint blackBorderPaint = Paint()
    ..color = const Color(0xff7ab2e8)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 10;
  static final blueFilter = Paint()
    ..colorFilter = const ColorFilter.mode(
      Color(0x880d8bff),
      BlendMode.srcATop,
    );

  void _renderFront(Canvas canvas) {
    final double spriteX =
        rank.value * spriteWidth - spriteWidth;
    final double spriteY = suit.value * spriteHeight;

    final Sprite cardFrontSprite = frontSprite(
        spriteX, spriteY, spriteWidth, spriteHeight);
    _drawSprite(canvas, cardFrontSprite, 0.5, 0.5);
  }

  void _drawSprite(
    Canvas canvas,
    Sprite sprite,
    double relativeX,
    double relativeY, {
    double scale = 10,
    bool rotate = false,
  }) {
    if (rotate) {
      canvas.save();
      canvas.translate(size.x / 2, size.y / 2);
      canvas.rotate(pi);
      canvas.translate(-size.x / 2, -size.y / 2);
    }
    sprite.render(
      canvas,
      position:
          Vector2(relativeX * size.x, relativeY * size.y),
      anchor: Anchor.center,
      size: sprite.srcSize.scaled(scale),
    );
    if (rotate) {
      canvas.restore();
    }
  }

  //#endregion

  //#region Effects

  void doMove(
    Vector2 to, {
    double speed = 10.0,
    double start = 0.0,
    int startPriority = 100,
    Curve curve = Curves.easeOutQuad,
    VoidCallback? onComplete,
  }) {
    assert(
        speed > 0.0, 'Speed must be > 0 widths per second');
    final dt = (to - position).length / (speed * size.x);
    assert(dt > 0, 'Distance to move must be > 0');
    add(
      CardMoveEffect(
        to,
        EffectController(
            duration: dt, startDelay: start, curve: curve),
        transitPriority: startPriority,
        onComplete: () {
          onComplete?.call();
        },
      ),
    );
  }

  void doMoveAndFlip(
    Vector2 to, {
    double speed = 10.0,
    double start = 0.0,
    Curve curve = Curves.easeOutQuad,
    VoidCallback? whenDone,
  }) {
    assert(
        speed > 0.0, 'Speed must be > 0 widths per second');
    final dt = (to - position).length / (speed * size.x);
    assert(dt > 0, 'Distance to move must be > 0');
    priority = 100;
    add(
      MoveToEffect(
        to,
        EffectController(
            duration: dt, startDelay: start, curve: curve),
        onComplete: () {
          animatedFlip(
            onComplete: whenDone,
          );
        },
      ),
    );
  }

  void animatedFlip({
    double time = 0.3,
    double start = 0.0,
    VoidCallback? onComplete,
  }) {
    assert(
        time > 0.0, 'Time to turn card over must be > 0');
    assert(start >= 0.0, 'Start tim must be >= 0');
    _isAnimatedFlip = true;
    anchor = Anchor.topCenter;
    position += Vector2(width / 2, 0);
    priority = 100;
    add(
      ScaleEffect.to(
        Vector2(scale.x / 100, scale.y),
        EffectController(
          startDelay: start,
          curve: Curves.easeOutSine,
          duration: time / 2,
          onMax: () {
            _isFaceUpView = !_isFaceUpView;
          },
          reverseDuration: time / 2,
          onMin: () {
            _isAnimatedFlip = false;
            _faceUp = !_faceUp;
            anchor = Anchor.topLeft;
            position -= Vector2(width / 2, 0);
          },
        ),
        onComplete: () {
          onComplete?.call();
        },
      ),
    );
  }

  //#endregion
}

class CardMoveEffect extends MoveToEffect {
  CardMoveEffect(
    super.destination,
    super.controller, {
    super.onComplete,
    this.transitPriority = 100,
  });

  final int transitPriority;

  @override
  void onStart() {
    super
        .onStart(); // Flame connects MoveToEffect to EffectController.
    parent?.priority = transitPriority;
  }
}
