import 'package:flutter/foundation.dart';

@immutable
class Suit {
  factory Suit.fromInt(int index) {
    assert(
      index >= 0 && index <= 3,
      'index is outside of the bounds of what a suit can be',
    );
    return _singletons[index];
  }

  const Suit._(this.value, this.label);

  final int value;
  final String label;

  static final List<Suit> _singletons = [
    const Suit._(0, '♥'),
    const Suit._(1, '♦'),
    const Suit._(2, '♣'),
    const Suit._(3, '♠'),
  ];

  /// Hearts and Diamonds are red, while Clubs and Spades are black.
  bool get isRed => value <= 1;
  bool get isBlack => value >= 2;
}
