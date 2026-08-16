import 'package:flutter/material.dart';

class AnimatedBalance extends StatefulWidget {
  final double value;
  final TextStyle? style;
  final String Function(double value) formatter;
  final Duration duration;
  final int? maxLines;
  final TextOverflow? overflow;

  const AnimatedBalance({
    super.key,
    required this.value,
    this.style,
    required this.formatter,
    this.duration = const Duration(milliseconds: 500),
    this.maxLines,
    this.overflow,
  });

  @override
  State<AnimatedBalance> createState() => _AnimatedBalanceState();
}

class _AnimatedBalanceState extends State<AnimatedBalance>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _displayValue = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _animation = _controller.drive(Tween<double>(
      begin: 0,
      end: widget.value,
    ));
    _animation.addListener(() {
      setState(() {
        _displayValue = _animation.value;
      });
    });
    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedBalance oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _animation = _controller.drive(Tween<double>(
        begin: _displayValue,
        end: widget.value,
      ));
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      widget.formatter(_displayValue),
      style: widget.style,
      maxLines: widget.maxLines,
      overflow: widget.overflow,
    );
  }
}
