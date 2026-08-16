import 'package:flutter/material.dart';

class PressCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleAmount;
  final Duration duration;

  const PressCard({
    super.key,
    required this.child,
    this.onTap,
    this.scaleAmount = 0.97,
    this.duration = const Duration(milliseconds: 120),
  });

  @override
  State<PressCard> createState() => _PressCardState();
}

class _PressCardState extends State<PressCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      lowerBound: widget.scaleAmount,
      upperBound: 1.0,
    )..value = 1.0;
    _scale = _controller.drive(Tween<double>(begin: 1, end: widget.scaleAmount));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) => _controller.reverse();
  void _onTapUp(TapUpDetails details) {
    _controller.forward();
    widget.onTap?.call();
  }
  void _onTapCancel() => _controller.forward();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap != null ? _onTapDown : null,
      onTapUp: widget.onTap != null ? _onTapUp : null,
      onTapCancel: widget.onTap != null ? _onTapCancel : null,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) {
          return Transform.scale(
            scale: _scale.value,
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}
