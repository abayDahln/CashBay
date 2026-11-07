import 'package:flutter/material.dart';

class PressCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const PressCard({super.key, required this.child, this.onTap});

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: InkWell(onTap: onTap, child: child),
  );
}
