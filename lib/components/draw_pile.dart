import 'dart:ui';

import 'package:flame/components.dart';
import 'package:blackjack/models/pile.dart';

import '../blackjack_game.dart';
import '../models/player.dart';
import 'card.dart';

class DrawPile extends PositionComponent
    with HasGameReference<BlackJackGame>
    implements Pile {
  @override
  bool get debugMode => true;

  DrawPile({super.position})
      : super(size: BlackJackGame.cardSize);

  Player? player;

  /// Which cards are currently placed onto this pile. The first card in the
  /// list is at the bottom, the last card is on top.
  final List<Card> _cards = [];

  get cards => _cards;

  //#region Pile API

  @override
  bool canMoveCard(Card card, MoveMethod method) => false;
  // Can be moved by onTapUp callback (see below).

  @override
  bool canAcceptCard(Card card) => false;

  @override
  void removeCard(Card card, MoveMethod method) =>
      throw StateError('cannot remove cards');

  @override
  // Card cannot be removed but could have been dragged out of place.
  void returnCard(Card card) =>
      card.priority = _cards.indexOf(card);

  @override
  void acquireCard(Card card) {
    assert(card.isFaceDown);
    card.pile = this;
    card.position = position;
    card.priority = _cards.length;
    _cards.add(card);
  }

  //#endregion

  void handleTapUp(Card card) {
    hitCard();
  }

  void hitCard() {
    final tablePile = player!.tablePile;
    final discardPile = player!.discardPile;
    // if empty, put all cards from discard in random order
    if (_cards.isEmpty) {
      print("is empty");
      discardPile.removeAllCards().forEach((card) {
        card.flip();
        acquireCard(card);
      });
    } else {
      // else put a card from draw to table
      if (_cards.isNotEmpty) {
        final card = _cards.removeLast();
        card.doMoveAndFlip(
          Vector2(
              tablePile.position.x,
              tablePile.position.y +
                  (tablePile.cardsList.length *
                      BlackJackGame.cardWidth *
                      0.2)),
          whenDone: () {
            tablePile.acquireCard(card);
          },
        );
      }
    }
  }

  //#region Rendering

  final _borderPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 10
    ..color = const Color(0xFF3F5B5D);
  final _circlePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 100
    ..color = const Color(0x883F5B5D);

  @override
  void render(Canvas canvas) {
    canvas.drawRRect(BlackJackGame.cardRRect, _borderPaint);
    canvas.drawCircle(
      Offset(width / 2, height / 2),
      BlackJackGame.cardWidth * 0.3,
      _circlePaint,
    );
  }

  //#endregion
}
