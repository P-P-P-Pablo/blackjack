import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';

import 'blackjack_game.dart';

void main() {
  final game = BlackJackGame();
  runApp(GameWidget(game: game));
}
