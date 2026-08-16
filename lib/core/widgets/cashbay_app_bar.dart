import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CashBayAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? bottom;
  final Widget? leading;
  final bool automaticallyImplyLeading;

  const CashBayAppBar({
    super.key,
    required this.title,
    this.actions,
    this.bottom,
    this.leading,
    this.automaticallyImplyLeading = true,
  });

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + (bottom != null ? kToolbarHeight : 0));

  @override
  Widget build(BuildContext context) {
    final canPop = automaticallyImplyLeading && Navigator.of(context).canPop();

    return AppBar(
      title: Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
      leading: leading ?? (canPop ? const BackButton() : null),
      actions: actions,
      bottom: bottom != null
          ? PreferredSize(preferredSize: const Size.fromHeight(kToolbarHeight), child: bottom!)
          : null,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 0,
    );
  }
}
