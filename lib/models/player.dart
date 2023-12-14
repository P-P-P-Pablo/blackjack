import 'package:blackjack/components/discard_pile.dart';
import 'package:blackjack/components/draw_pile.dart';
import 'package:blackjack/components/table_pile.dart';

import '../components/card.dart';

class Player {
  // Declaring instance variable
  late List<Card> deck;
  late DrawPile drawPile;
  late DiscardPile discardPile;
  late TablePile tablePile;
  final int maxScore = 21;

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

  int getScore() {
    int score = 0;
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
        if (score + 10 < maxScore) {
          value = 10;
        } else {
          value = 1;
        }
      }
      score += value;
    }
    return score;
  }
}