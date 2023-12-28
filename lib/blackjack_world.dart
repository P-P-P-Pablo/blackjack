import 'dart:math';

import 'package:blackjack/models/player.dart';
import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flutter/painting.dart';

import 'components/card.dart';
import 'components/discard_pile.dart';
import 'components/draw_pile.dart';
import 'components/flat_button.dart';

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

  final Player player = Player(10);
  final Player opponent = Player(10);

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

  late final TextComponent playerScoreDisplay;
  late final TextComponent opponentScoreDisplay;
  late final TextComponent playerHPDisplay;
  late final TextComponent opponentHPDisplay;
  final scoreRenderer = TextPaint(
      style: const TextStyle(
    fontSize: 400,
    fontWeight: FontWeight.bold,
    color: Color(0xFFDBAF58),
  ));
  final hpRenderer = TextPaint(
      style: const TextStyle(
    fontSize: 200,
    fontWeight: FontWeight.bold,
    color: Color(0xFFDB4638),
  ));

  late final FlatButton hitButton;
  late final FlatButton standButton;

  @override
  Future<void> onLoad() async {
    await Flame.images.load('cards.png');
    await Flame.images.load('backsheet.png');

    opponent.limit = BlackJackGame.opponentLimit;

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

    //#endregion

    //#region Gameplay Components

    addGameplayComponents();

    final gameMidX = playAreaSize.x / 2;

    final camera = game.camera;
    camera.viewfinder.visibleGameSize = playAreaSize;
    camera.viewfinder.position = Vector2(gameMidX, 0);
    camera.viewfinder.anchor = Anchor.topCenter;
    deal(cards, draw);
    deal(opponentCards, opponentDraw);

    //#endregion
  }

  void addGameplayComponents() {
    addCardsToPile(
        cards, draw, BlackJackGame.yourBackNumber);
    addCardsToPile(opponentCards, opponentDraw,
        BlackJackGame.opponentBackNumber);

    add(draw);
    add(table);
    add(discard);
    player.pileAttribution(draw, discard, table);
    addAll(cards);
    player.deckAttribution(cards);

    add(opponentDraw);
    add(opponentTable);
    add(opponentDiscard);
    opponent.pileAttribution(
        opponentDraw, opponentDiscard, opponentTable);
    addAll(opponentCards);
    opponent.deckAttribution(opponentCards);

    addUserInterface();
  }

  void addUserInterface() {
    //#region Buttons
    hitButton = FlatButton(
      "HIT",
      size: Vector2(BlackJackGame.cardWidth, borderGap),
      position: Vector2(playAreaSize.x / 2 - 800,
          playAreaSize.y - 4 * borderGap),
      onPressed: () {
        if (!hitButton.isDisabled) {
          draw.hitCard();
        }

        if (opponent.score.value < opponent.maxScore &&
            opponent.score.value < opponent.limit!) {
          opponentDraw.hitCard();
        }
      },
    );
    table.hitButton = hitButton;
    add(hitButton);

    standButton = FlatButton(
      "STAND",
      size: Vector2(BlackJackGame.cardWidth, borderGap),
      position: Vector2(playAreaSize.x / 2 + 800,
          playAreaSize.y - 4 * borderGap),
      onPressed: () {
        hitButton.isDisabled = true;
        if (opponent.score.value < opponent.maxScore &&
            opponent.score.value < opponent.limit!) {
          opponentDraw.hitCard();
        } else if (opponent.score.value >=
                opponent.limit! &&
            hitButton.isDisabled) {
          endRound();
        }
      },
    );
    add(standButton);
    //#endregion

    //#region HP Display

    // init
    playerHPDisplay = TextComponent(
        text: '${player.hitPoints.value} / ${player.maxHP}',
        textRenderer: hpRenderer,
        anchor: Anchor.topLeft,
        position: Vector2(
            draw.position.x + cardWidth + cardGap,
            draw.position.y));

    // onChange
    player.hitPoints.addListener(() {
      print('player HP : ${player.hitPoints.value}');
      playerHPDisplay.text =
          '${player.hitPoints.value} / ${player.maxHP}';
    });

    opponentHPDisplay = TextComponent(
        text:
            '${opponent.hitPoints.value} / ${opponent.maxHP}',
        textRenderer: hpRenderer,
        anchor: Anchor.topLeft,
        position: Vector2(
            opponentDraw.position.x + cardWidth + cardGap,
            opponentDraw.position.y));

    // onChange
    opponent.hitPoints.addListener(() {
      print('opponent HP : ${opponent.hitPoints.value}');
      opponentHPDisplay.text =
          '${opponent.hitPoints.value} / ${opponent.maxHP}';
    });

    add(opponentHPDisplay);
    add(playerHPDisplay);
    //#endregion

    //#region Score Display

    // init
    playerScoreDisplay = TextComponent(
      text: '${player.score.value} / ${player.maxScore}',
      textRenderer: scoreRenderer,
      anchor: Anchor.topCenter,
      position: Vector2(
          playAreaSize.x / 2,
          playAreaSize.y -
              BlackJackGame.cardHeight -
              BlackJackGame.borderGap * 2),
    );

    // onChange
    player.score.addListener(() {
      print('player Score : ${player.score.value}');
      playerScoreDisplay.text =
          '${player.score.value} / ${player.maxScore}';
    });

    // init
    opponentScoreDisplay = TextComponent(
      text:
          '${opponent.score.value} / ${opponent.maxScore}',
      textRenderer: scoreRenderer,
      anchor: Anchor.topCenter,
      position: Vector2(
          playAreaSize.x / 2,
          BlackJackGame.cardHeight +
              BlackJackGame.borderGap * 2),
    );

    // onChange
    opponent.score.addListener(() {
      print('opponent Score : ${opponent.score.value}');
      opponentScoreDisplay.text =
          '${opponent.score.value} / ${opponent.maxScore}';
    });

    add(playerScoreDisplay);
    add(opponentScoreDisplay);

    //#endregion
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
  }

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
        card.basicFlip();
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

  void addCardsToPile(
      List<Card> cards, DrawPile pile, int backNumber) {
    // adding Numbers and Faces
    for (var rank = 7; rank <= 13; rank++) {
      for (var suit = 0; suit < 4; suit++) {
        final card = Card(rank, suit, backNumber);
        card.position = pile.position;
        cards.add(card);
      }
    }
    // adding Aces
    for (var suit = 0; suit < 4; suit++) {
      final card = Card(1, suit, backNumber);
      card.position = pile.position;
      cards.add(card);
    }
  }

  Future<void> endRound() async {
    String endResult;
    Color color;

    int matchEndTrigger = 1;

    if (player.score.value == opponent.score.value) {
      endResult = "It's a draw !";
      color = const Color(0xFF000000);
    } else if (player.score.value < opponent.score.value &&
        opponent.score.value <= opponent.maxScore) {
      endResult =
          "You lose by ${opponent.score.value - player.score.value} points !";
      color = const Color(0xFFC40A0A);
      matchEndTrigger = await player.loseHP(
          opponent.score.value - player.score.value);
    } else if (player.score.value > player.maxScore) {
      endResult = "You drew too many cards !";
      color = const Color(0xFFC40A0A);
      matchEndTrigger =
          await player.loseHP(opponent.score.value);
    } else if (player.score.value > opponent.score.value &&
        player.score.value <= player.maxScore) {
      endResult =
          "You won by ${player.score.value - opponent.score.value} points !";
      color = const Color(0xFF1A5105);
      matchEndTrigger = await opponent.loseHP(
          player.score.value - opponent.score.value);
    } else if (opponent.score.value > opponent.maxScore) {
      endResult = "Your opponent drew too many cards !";
      color = const Color(0xFF1A5105);
      matchEndTrigger =
          await opponent.loseHP(player.score.value);
    } else {
      endResult = "How did you get that result ?";
      color = const Color(0xFF000000);
    }

    TextComponent endMessage = TextComponent(
      priority: 100,
      //boxConfig: TextBoxConfig(timePerChar: 0.05),
      text: endResult,
      textRenderer: TextPaint(
        style: TextStyle(
          fontSize: 0.05 * playAreaSize.y,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
      position:
          Vector2(playAreaSize.x / 2, playAreaSize.y / 2),
      anchor: Anchor.center,
    );

    add(endMessage);
    await Future.delayed(const Duration(seconds: 3), () {
      remove(endMessage);

      table
          .removeAllCards()
          .asMap()
          .forEach((int i, Card card) async {
        card.doMove(
          discard.position,
          speed: 15.0,
          start: i * 0.3,
          startPriority: 100 + i,
          onComplete: () {
            discard.acquireCard(card);
          },
        );
      });
      opponentTable
          .removeAllCards()
          .asMap()
          .forEach((int i, Card card) async {
        card.doMove(
          opponentDiscard.position,
          speed: 15.0,
          start: i * 0.3,
          startPriority: 100 + i,
          onComplete: () {
            opponentDiscard.acquireCard(card);
          },
        );
      });
      player.updateScore();
      opponent.updateScore();
      if (matchEndTrigger == 0) {
        add(TextComponent(
          priority: 100,
          //boxConfig: TextBoxConfig(timePerChar: 0.05),
          text: "Game Over",
          textRenderer: TextPaint(
            style: TextStyle(
              fontSize: 0.05 * playAreaSize.y,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          position: Vector2(
              playAreaSize.x / 2, playAreaSize.y / 2),
          anchor: Anchor.center,
        ));
      }
    });

    hitButton.isDisabled = false;
  }
}
