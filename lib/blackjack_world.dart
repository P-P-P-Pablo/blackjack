import 'dart:math';

import 'package:blackjack/models/player.dart';
import 'package:flame/components.dart';
import 'package:flame/flame.dart';

import 'components/card.dart';
import 'components/discard_pile.dart';
import 'components/draw_pile.dart';
import 'components/old_components/flat_button.dart';

import 'blackjack_game.dart';
import 'components/table_pile.dart';

class BlackJackWorld extends World
    with HasGameReference<BlackJackGame> {
  final cardGap = BlackJackGame.cardGap;
  final borderGap = BlackJackGame.borderGap;
  final cardSpaceWidth = BlackJackGame.cardSpaceWidth;
  final cardSpaceHeight = BlackJackGame.cardSpaceHeight;

  final cardWidth = BlackJackGame.cardWidth;
  final cardHeight = BlackJackGame.cardHeight;

  Player player = Player();
  Player opponent = Player();

  final draw = DrawPile(position: Vector2(0.0, 0.0));
  final table = TablePile(position: Vector2(0.0, 0.0));
  final discard = DiscardPile(position: Vector2(0.0, 0.0));
  final opponentDraw =
      DrawPile(position: Vector2(0.0, 0.0));
  final opponentTable =
      TablePile(position: Vector2(0.0, 0.0));
  final opponentDiscard =
      DiscardPile(position: Vector2(0.0, 0.0));
  final List<Card> cards = [];
  final List<Card> opponentCards = [];
  final Vector2 playAreaSize = Vector2(7200, 12800);

  @override
  Future<void> onLoad() async {
    await Flame.images.load('klondike-sprites.png');

    //#region Position

    draw.position = Vector2(
        borderGap, playAreaSize.y - cardHeight - borderGap);

    opponentDraw.position =
        Vector2(borderGap, borderGap + 300);

    table.position = Vector2(
        (playAreaSize.x / 2 - borderGap - cardWidth),
        (2 * playAreaSize.y / 3 - borderGap));
    opponentTable.position = Vector2(
        (playAreaSize.x / 2 + borderGap + cardWidth),
        (playAreaSize.y / 3 + borderGap));

    discard.position = Vector2(
        (playAreaSize.x - borderGap - cardWidth),
        (playAreaSize.y - borderGap - cardHeight));
    opponentDiscard.position = Vector2(
        (playAreaSize.x - borderGap - cardWidth),
        borderGap + 300);

    // Add a Base Card to the Stock Pile, above the pile and below other cards.
    final baseCard = Card(1, 0, isBaseCard: true);
    baseCard.position = draw.position;
    baseCard.priority = -1;
    baseCard.pile = draw;
    draw.priority = -2;

    final opponentBaseCard = Card(1, 0, isBaseCard: true);
    opponentBaseCard.position = draw.position;
    opponentBaseCard.priority = -1;
    opponentBaseCard.pile = draw;
    opponentDraw.priority = -2;

    addButton(
        'Hit',
        Vector2(playAreaSize.x / 2 + 800,
            playAreaSize.y - 4 * borderGap),
        Action.hit);
    addButton(
        'Stand',
        Vector2(playAreaSize.x / 2 - 800,
            playAreaSize.y - 4 * borderGap),
        Action.stand);

    //#endregion

    addCardsToPile(cards, draw);
    addCardsToPile(opponentCards, opponentDraw);

    add(draw);
    add(table);
    add(discard);
    player.pileAttribution(draw, discard, table);
    addAll(cards);
    add(baseCard);
    player.deckAttribution(cards);

    add(opponentDraw);
    add(opponentTable);
    add(opponentDiscard);
    opponent.pileAttribution(
        opponentDraw, opponentDiscard, opponentTable);
    addAll(opponentCards);
    add(opponentBaseCard);
    opponent.deckAttribution(opponentCards);

    final gameMidX = playAreaSize.x / 2;

    final camera = game.camera;
    camera.viewfinder.visibleGameSize = playAreaSize;
    camera.viewfinder.position = Vector2(gameMidX, 0);
    camera.viewfinder.anchor = Anchor.topCenter;
    deal(cards, draw);
    deal(opponentCards, opponentDraw);
  }

  void addButton(
      String label, Vector2 position, Action action) {
    final button = FlatButton(
      label,
      size: Vector2(BlackJackGame.cardWidth, borderGap),
      position: position,
      onReleased: () {
        if (action == Action.hit) {
          draw.hitCard();
          opponentDraw.hitCard();
          print(
              "something happened ${draw.cards} ${table.cards}");
        } else if (action == Action.stand) {}
      },
    );
    add(button);
  }

  void deal(List<Card> cards, DrawPile draw) {
    assert(cards.length == 32,
        'There are ${cards.length} cards: should be 32');

    if (game.action != Action.sameDeal) {
      // New deal: change the Random Number Generator's seed.
      game.seed = Random().nextInt(BlackJackGame.maxInt);
    }
    // For the "Same deal" option, re-use the previous seed, else use a new one.
    cards.shuffle(Random(game.seed));

    // Each card dealt must be seen to come from the top of the deck!
    var dealPriority = 1;
    for (final card in cards) {
      card.priority = dealPriority++;
    }

    for (var n = 0; n <= cards.length - 1; n++) {
      draw.acquireCard(cards[n]);
    }

    // Change priority as cards take off: so later cards fly above earlier ones.
    /* var cardToDeal = cards.length - 1;
    var nMovingCards = 0;
    for (var i = 0; i < 7; i++) {
      for (var j = i; j < 7; j++) {
        final card = cards[cardToDeal--];
        card.doMove(
          tableauPiles[j].position,
          speed: 15.0,
          start: nMovingCards * 0.15,
          startPriority: 100 + nMovingCards,
          onComplete: () {
            tableauPiles[j].acquireCard(card);
            nMovingCards--;
            if (nMovingCards == 0) {
              var delayFactor = 0;
              for (final tableauPile in tableauPiles) {
                delayFactor++;
                tableauPile.flipTopCard(
                    start: delayFactor * 0.15);
              }
            }
          },
        );
        nMovingCards++;
      }
    }
    for (var n = 0; n <= cardToDeal; n++) {
      draw.acquireCard(cards[n]);
    } */
  }

  /* void checkWin() {
    // Callback from a Foundation Pile when it is full (Ace to King).
    var nComplete = 0;
    for (final f in foundations) {
      if (f.isFull) {
        nComplete++;
      }
    }
    if (nComplete == foundations.length) {
      letsCelebrate();
    }
  } */

  void letsCelebrate({int phase = 1}) {
    // Deal won: bring all cards to the middle of the screen (phase 1)
    // then scatter them to points just outside the screen (phase 2).
    //
    // First get the device's screen-size in game co-ordinates, then get the
    // top-left of the off-screen area that will accept the scattered cards.
    // Note: The play area is anchored at TopCenter, so topLeft.y is fixed.

    final cameraZoom = game.camera.viewfinder.zoom;
    final zoomedScreen = game.size / cameraZoom;
    final screenCenter =
        (playAreaSize - BlackJackGame.cardSize) / 2;
    final topLeft = Vector2(
      (playAreaSize.x - zoomedScreen.x) / 2 -
          BlackJackGame.cardWidth,
      -BlackJackGame.cardHeight,
    );
    final nCards = cards.length;
    final offscreenHeight =
        zoomedScreen.y + BlackJackGame.cardSize.y;
    final offscreenWidth =
        zoomedScreen.x + BlackJackGame.cardSize.x;
    final spacing =
        2.0 * (offscreenHeight + offscreenWidth) / nCards;

    // Starting points, directions and lengths of offscreen rect's sides.
    final corner = [
      Vector2(0.0, 0.0),
      Vector2(0.0, offscreenHeight),
      Vector2(offscreenWidth, offscreenHeight),
      Vector2(offscreenWidth, 0.0),
    ];
    final direction = [
      Vector2(0.0, 1.0),
      Vector2(1.0, 0.0),
      Vector2(0.0, -1.0),
      Vector2(-1.0, 0.0),
    ];
    final length = [
      offscreenHeight,
      offscreenWidth,
      offscreenHeight,
      offscreenWidth,
    ];

    var side = 0;
    var cardsToMove = nCards;
    var offScreenPosition = corner[side] + topLeft;
    var space = length[side];
    var cardNum = 0;

    while (cardNum < nCards) {
      final cardIndex =
          phase == 1 ? cardNum : nCards - cardNum - 1;
      final card = cards[cardIndex];
      card.priority = cardIndex + 1;
      if (card.isFaceDown) {
        card.flip();
      }
      // Start cards a short time apart to give a riffle effect.
      final delay = phase == 1
          ? cardNum * 0.02
          : 0.5 + cardNum * 0.04;
      final destination =
          (phase == 1) ? screenCenter : offScreenPosition;
      card.doMove(
        destination,
        speed: (phase == 1) ? 15.0 : 5.0,
        start: delay,
        onComplete: () {
          cardsToMove--;
          if (cardsToMove == 0) {
            if (phase == 1) {
              letsCelebrate(phase: 2);
            } else {
              // Restart with a new deal after winning or pressing "Have fun".
              game.action = Action.newDeal;
              game.world = BlackJackWorld();
            }
          }
        },
      );
      cardNum++;
      if (phase == 1) {
        continue;
      }

      // Phase 2: next card goes to same side with full spacing, if possible.
      offScreenPosition =
          offScreenPosition + direction[side] * spacing;
      space = space - spacing;
      if ((space < 0.0) && (side < 3)) {
        // Out of space: change to the next side and use excess spacing there.
        side++;
        offScreenPosition = corner[side] +
            topLeft -
            direction[side] * space;
        space = length[side] + space;
      }
    }
  }

  void addCardsToPile(List<Card> cards, DrawPile pile) {
    // adding Numbers and Faces
    for (var rank = 7; rank <= 13; rank++) {
      for (var suit = 0; suit < 4; suit++) {
        final card = Card(rank, suit);
        card.position = pile.position;
        cards.add(card);
      }
    }
    // adding Aces
    for (var suit = 0; suit < 4; suit++) {
      final card = Card(1, suit);
      card.position = pile.position;
      cards.add(card);
    }
  }
}