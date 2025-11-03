import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';

Widget autoTextScroller(String text, TextStyle style) {
  return LayoutBuilder(
    builder: (context, constraints) {
      final textPainter = TextPainter(
        text: TextSpan(text: text, style: style),
        maxLines: 1,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: constraints.maxWidth);

      final isOverflowing = textPainter.didExceedMaxLines;

      if (isOverflowing) {
        return Marquee(
          text: text,
          style: style,
          scrollAxis: Axis.horizontal,
          blankSpace: 20.0,
          velocity: 30.0,
        );
      } else {
        return Text(
          text,
          style: style,
        );
      }
    },
  );
}
