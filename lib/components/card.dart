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
import 'draw_pile.dart';

class Card extends PositionComponent
    with
        DragCallbacks,
        TapCallbacks,
        HasWorldReference<BlackJackWorld> {
  /* @override
  bool get debugMode => true; */

  Card(int intRank, int intSuit, this.backNumber,
      {this.isBaseCard = false})
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
  // A Base Card is rendered in outline only and is NOT playable. It can be
  // added to the base of a Pile (e.g. the Stock Pile) to allow it to handle
  // taps and short drags (on an empty Pile) with the same behavior and
  // tolerances as for regular cards (see BlackJackGame.dragTolerance) and using
  // the same event-handling code, but with different handleTapUp() methods.
  final bool isBaseCard;

  bool _faceUp = false;
  bool _isAnimatedFlip = false;
  bool _isFaceUpView = false;
  bool _isDragging = false;
  Vector2 _whereCardStarted = Vector2(0, 0);

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
    if (isBaseCard) {
      _renderBaseCard(canvas);
      return;
    }
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
    /* cardFrontSprite.render(canvas,
        position: size / 2, anchor: Anchor.center); */
    _drawSprite(canvas, cardFrontSprite, 0.5, 0.5);
  }

  void _renderBaseCard(Canvas canvas) {
    canvas.drawRRect(cardRRect, backBorderPaint1);
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
    /* cardFrontSprite.render(canvas,
        position: size / 2, anchor: Anchor.center); */
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

  //#region Card-Dragging

  @override
  void onTapCancel(TapCancelEvent event) {
    if (pile is DrawPile) {
      _isDragging = false;
      handleTapUp();
    }
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    if (pile is DrawPile) {
      _isDragging = false;
      return;
    }
    // Clone the position, else _whereCardStarted changes as the position does.
    _whereCardStarted = position.clone();
    attachedCards.clear();
    if (pile?.canMoveCard(this, MoveMethod.drag) ?? false) {
      _isDragging = true;
      priority = 100;
      /* if (pile is TableauPile) {
        final extraCards =
            (pile! as TableauPile).cardsOnTop(this);
        for (final card in extraCards) {
          card.priority = attachedCards.length + 101;
          attachedCards.add(card);
        }
      } */
    }
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (!_isDragging) {
      return;
    }
    final delta = event.localDelta;
    position.add(delta);
    for (var card in attachedCards) {
      card.position.add(delta);
    }
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    if (!_isDragging) {
      return;
    }
    _isDragging = false;

    // If short drag, return card to Pile and treat it as having been tapped.
    final shortDrag =
        (position - _whereCardStarted).length <
            BlackJackGame.dragTolerance;
    if (shortDrag && attachedCards.isEmpty) {
      doMove(
        _whereCardStarted,
        onComplete: () {
          pile!.returnCard(this);
          // Card moves to its Foundation Pile next, if valid, or it stays put.
          handleTapUp();
        },
      );
      return;
    }

    // Find out what is under the center-point of this card when it is dropped.
    final dropPiles = parent!
        .componentsAtPoint(position + size / 2)
        .whereType<Pile>()
        .toList();
    if (dropPiles.isNotEmpty) {
      if (dropPiles.first.canAcceptCard(this)) {
        // Found a Pile: move card(s) the rest of the way onto it.
        pile!.removeCard(this, MoveMethod.drag);
        /* if (dropPiles.first is TableauPile) {
          // Get TableauPile to handle positions, priorities and moves of cards.
          (dropPiles.first as TableauPile)
              .dropCards(this, attachedCards);
          attachedCards.clear();
        } else {
          // Drop a single card onto a FoundationPile.
          final dropPosition =
              (dropPiles.first as FoundationPile).position;
          doMove(
            dropPosition,
            onComplete: () {
              dropPiles.first.acquireCard(this);
            },
          );
        } */
        return;
      }
    }

    // Invalid drop (middle of nowhere, invalid pile or invalid card for pile).
    doMove(
      _whereCardStarted,
      onComplete: () {
        pile!.returnCard(this);
      },
    );
    if (attachedCards.isNotEmpty) {
      for (var card in attachedCards) {
        final offset = card.position - position;
        card.doMove(
          _whereCardStarted + offset,
          onComplete: () {
            pile!.returnCard(card);
          },
        );
      }
      attachedCards.clear();
    }
  }

  //#endregion

  //#region Card-Tapping

  // Tap a face-up card to make it auto-move and go out (if acceptable), but
  // if it is face-down and on the Stock Pile, pass the event to that pile.

  @override
  void onTapUp(TapUpEvent event) {
    handleTapUp();
  }

  void handleTapUp() {
    // Can be called by onTapUp or after a very short (failed) drag-and-drop.
    // We need to be more user-friendly towards taps that include a short drag.
    /* if (pile?.canMoveCard(this, MoveMethod.tap) ?? false) {
      final suitIndex = suit.value;
      if (world.foundations[suitIndex]
          .canAcceptCard(this)) {
        pile!.removeCard(this, MoveMethod.tap);
        doMove(
          world.foundations[suitIndex].position,
          onComplete: () {
            world.foundations[suitIndex].acquireCard(this);
          },
        );
      }
    } else if (pile is DrawPile) {
      world.stock.handleTapUp(this);
    } */
  }

  //#endRegion

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
