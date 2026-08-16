import 'package:flutter/widgets.dart';

extension SpacingX on num {
  Widget get gapX => SizedBox(width: toDouble());
  Widget get gapY => SizedBox(height: toDouble());
}
