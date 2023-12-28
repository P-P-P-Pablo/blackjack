import 'package:blackjack/components/discard_pile.dart';
import 'package:blackjack/components/draw_pile.dart';
import 'package:blackjack/components/table_pile.dart';
import 'package:flutter/foundation.dart';

import '../components/card.dart';

class Player {
  // Declaring instance variable
  late final ValueNotifier<int> hitPoints;
  final int maxHP;
  late final List<Card> deck;
  late final DrawPile drawPile;
  late final DiscardPile discardPile;
  late final TablePile tablePile;
  final int maxScore = 21;
  ValueNotifier<int> score = ValueNotifier<int>(0);
  int? limit;

  Player(this.maxHP) : hitPoints = ValueNotifier(maxHP);

  Future<int> loseHP(int damage) async {
    if (damage > hitPoints.value) {
      damage = hitPoints.value;
    }

    for (var i = 0; i < damage; i++) {
      await Future.delayed(
          const Duration(milliseconds: 500), () {
        hitPoints.value -= 1;
      });
    }

    return hitPoints.value;
  }

  void deckAttribution(List<Card> deck) {
    for (var card in deck) {
      assert(card.player == null);
      card.player = this;
    }
    deck = deck;
  }

  void pileAttribution(
      DrawPile draw, DiscardPile discard, TablePile table) {
    drawPile = draw;
    draw.player = this;
    discardPile = discard;
    discard.player = this;
    tablePile = table;
    table.player = this;
  }

  void updateScore() {
    int scoreValue = 0;
    // get a copy of all cards values
    List<int> valuesList = [];
    for (Card card in tablePile.cardsList) {
      valuesList.add(card.rank.value);
    }

    //order list highest to lowest
    valuesList.sort((a, b) => b.compareTo(a));
    //count score
    for (int toto in valuesList) {
      int value = toto;
      // Faces value is 10
      if (value > 10) value = 10;
      // Ace value is 10 if score < maxScore
      if (value == 1) {
        if (scoreValue + 10 < maxScore) {
          value = 10;
        } else {
          value = 1;
        }
      }
      scoreValue += value;
    }
    score.value = scoreValue;
  }
}
