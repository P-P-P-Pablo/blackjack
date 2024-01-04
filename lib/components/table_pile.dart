import '../components/flat_button.dart';
import 'package:flame/components.dart';
import '../models/pile.dart';

import '../blackjack_game.dart';
import '../models/player.dart';
import 'card.dart';

class TablePile extends PositionComponent
    with HasGameReference<BlackJackGame>
    implements Pile {
  @override
  bool get debugMode => true;

  TablePile({super.position})
      : super(size: BlackJackGame.cardSize);

  Player? player;

  final List<Card> _cards = [];
  final Vector2 _fanOffset =
      Vector2(0, BlackJackGame.cardHeight * 0.25);

  List<Card> get cardsList => _cards;

  get cards => _cards;

  FlatButton? _hitButton;
  set hitButton(FlatButton hitButton) =>
      _hitButton = hitButton;

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
    _fanOutCards();
  }

  @override
  void returnCard(Card card) {
    card.priority = _cards.indexOf(card);
    _fanOutCards();
  }

  @override
  void acquireCard(Card card) {
    assert(card.isFaceUp);
    card.pile = this;
    card.position = position;
    card.priority = _cards.length;
    _cards.add(card);
    _fanOutCards();
    player!.updateScore();
    if (player!.score.value >= player!.maxScore) {
      _hitButton?.isDisabled = true;
    }
  }

  //#endregion

  List<Card> removeAllCards() {
    final cards = _cards.toList();
    _cards.clear();
    return cards;
  }

  void _fanOutCards() {
    if (_cards.isEmpty) {
      return;
    }
    _cards[0].position.setFrom(position);
    _cards[0].priority = 0;
    for (var i = 1; i < _cards.length; i++) {
      _cards[i].priority = i;
      _cards[i].position
        ..setFrom(_cards[i - 1].position)
        ..add(_fanOffset);
    }
  }
}
