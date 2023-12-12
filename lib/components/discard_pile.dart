import 'package:flame/components.dart';
import 'package:blackjack/models/pile.dart';

import '../blackjack_game.dart';
import 'card.dart';

class DiscardPile extends PositionComponent
    with HasGameReference<BlackJackGame>
    implements Pile {
  @override
  bool get debugMode => true;

  DiscardPile({super.position})
      : super(size: BlackJackGame.cardSize);

  final List<Card> _cards = [];
  final Vector2 _fanOffset =
      Vector2(BlackJackGame.cardWidth * 0.2, 0);

  //#region Pile API

  @override
  bool canMoveCard(Card card, MoveMethod method) =>
      false; // Tap and drag are both OK.

  @override
  bool canAcceptCard(Card card) => false;

  @override
  void removeCard(Card card, MoveMethod method) {
    assert(canMoveCard(card, method));
    _cards.removeLast();
    _fanOutTopCards();
  }

  @override
  void returnCard(Card card) {
    card.priority = _cards.indexOf(card);
    _fanOutTopCards();
  }

  @override
  void acquireCard(Card card) {
    assert(card.isFaceUp);
    card.pile = this;
    card.position = position;
    card.priority = _cards.length;
    _cards.add(card);
    _fanOutTopCards();
  }

  //#endregion

  List<Card> removeAllCards() {
    final cards = _cards.toList();
    _cards.clear();
    cards.shuffle();
    return cards;
  }

  void _fanOutTopCards() {
    if (game.blackjackDraw == 1) {
      // No fan-out in BlackJack Draw 1.
      return;
    }
    final n = _cards.length;
    for (var i = 0; i < n; i++) {
      _cards[i].position = position;
    }
    if (n == 2) {
      _cards[1].position.add(_fanOffset);
    } else if (n >= 3) {
      _cards[n - 2].position.add(_fanOffset);
      _cards[n - 1].position.addScaled(_fanOffset, 2);
    }
  }
}
