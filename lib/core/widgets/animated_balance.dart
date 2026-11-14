import 'package:flutter/material.dart';

class AnimatedBalance extends StatelessWidget {
  final double value;
  final TextStyle? style;
  final String Function(double value) formatter;
  final int? maxLines;
  final TextOverflow? overflow;

  const AnimatedBalance({
    super.key,
    required this.value,
    this.style,
    required this.formatter,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      formatter(value),
      style: style,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
