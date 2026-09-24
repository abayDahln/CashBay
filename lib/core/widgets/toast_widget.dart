import 'package:flutter/material.dart';

class ToastWidget {
  static OverlayEntry? _overlayEntry;

  static void show(BuildContext context, String message, {double topPadding = 24}) {
    _hide();

    final overlay = Overlay.of(context);
    final renderBox = Overlay.of(context).context.findRenderObject()! as RenderBox;

    final size = renderBox.size;
    final text = Text(message,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
        ));

    final textPainter = TextPainter(
      text: TextSpan(text: message, style: const TextStyle(color: Colors.white, fontSize: 16)),
      maxLines: 100,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(minWidth: 0, maxWidth: size.width);
    final textSize = textPainter.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: topPadding,
        left: size.width / 2 - textSize.width / 2,
        right: size.width / 2 - textSize.width / 2,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(20),
            ),
            child: text,
          ),
        ),
      ),
    );

    overlay.insert(_overlayEntry!);

    Future.delayed(const Duration(seconds: 3), () {
      _hide();
    });
  }

  static void _hide() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}