import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';

class FlatButton extends ButtonComponent {
  FlatButton(
    String text, {
    super.size,
    super.onReleased,
    super.position,
  }) : super(
          button: ButtonBackground(Colors.blueGrey,
              Colors.white.withOpacity(0.2)),
          buttonDown: ButtonBackground(
              Colors.amber, Colors.white.withOpacity(0.6)),
          children: [
            TextComponent(
              text: text,
              textRenderer: TextPaint(
                style: TextStyle(
                  fontSize: 0.7 * size!.y,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
              position: size / 2.0,
              anchor: Anchor.center,
            ),
          ],
          anchor: Anchor.center,
        );
}

class ButtonBackground extends PositionComponent
    with HasAncestor<FlatButton> {
  final borderPaint = Paint()..style = PaintingStyle.stroke;
  final bodyPaint = Paint()..style = PaintingStyle.fill;

  late double cornerRadius;

  ButtonBackground(Color borderColor, Color bodyColor) {
    borderPaint.color = borderColor;
    bodyPaint.color = bodyColor;
  }

  @override
  void onMount() {
    super.onMount();
    size = ancestor.size;
    cornerRadius = 0.3 * size.y;
    borderPaint.strokeWidth = 0.05 * size.y;
  }

  late final buttonForm = RRect.fromRectAndRadius(
    size.toRect(),
    Radius.circular(cornerRadius),
  );

  @override
  void render(Canvas canvas) {
    canvas.drawRRect(buttonForm, bodyPaint);
    canvas.drawRRect(buttonForm, borderPaint);
  }
}
