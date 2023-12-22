import 'package:blackjack/components/discard_pile.dart';
import 'package:blackjack/components/draw_pile.dart';
import 'package:blackjack/components/table_pile.dart';
import 'package:flutter/foundation.dart';

import '../components/card.dart';

class Player {
  // Declaring instance variable
  late final List<Card> deck;
  late final DrawPile drawPile;
  late final DiscardPile discardPile;
  late final TablePile tablePile;
  final int maxScore = 21;
  ValueNotifier<int> score = ValueNotifier<int>(0);
  int? limit;

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
    score.value = 0;
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
        if (score.value + 10 < maxScore) {
          value = 10;
        } else {
          value = 1;
        }
      }
      score.value += value;
    }
  }
}
