import 'package:flutter/material.dart';

/// Named route helper kept as a single entry point for pushes.
///
/// A plain slide transition (Cupertino style) on every platform.
Route<T> fadeSlideRoute<T>(Widget page) {
  return MaterialPageRoute<T>(
    builder: (context) => page,
    fullscreenDialog: false,
  );
}
