import 'package:flutter/material.dart';

/// Keeps every child alive (like [IndexedStack]) and animates between them in
/// the direction of travel: the outgoing page slides out to one side while the
/// incoming page slides in from the other.
///
/// [PageView] already does exactly this, so this is a thin index-driven wrapper
/// over it. Each child is wrapped in a keep-alive so leaving a page does not
/// dispose it — the dashboard reads its children's [GlobalKey] state after
/// switching tabs.
class SlideIndexedStack extends StatefulWidget {
  final int index;
  final List<Widget> children;
  final Duration duration;
  final Curve curve;

  const SlideIndexedStack({
    super.key,
    required this.index,
    required this.children,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeOutCubic,
  });

  @override
  State<SlideIndexedStack> createState() => _SlideIndexedStackState();
}

class _SlideIndexedStackState extends State<SlideIndexedStack> {
  late final PageController _controller =
      PageController(initialPage: widget.index);

  @override
  void didUpdateWidget(covariant SlideIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) {
      _controller.animateToPage(
        widget.index,
        duration: widget.duration,
        curve: widget.curve,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: _controller,
      physics: const NeverScrollableScrollPhysics(),
      // Build the neighbouring pages too, so a page's GlobalKey state exists
      // before the tab is opened (the dashboard calls into HistoryScreen's
      // state right after switching to it).
      allowImplicitScrolling: true,
      children: [
        for (final child in widget.children) _KeepAlive(child: child),
      ],
    );
  }
}

/// Keeps [child]'s state alive while it is off-screen inside a [PageView].
class _KeepAlive extends StatefulWidget {
  final Widget child;
  const _KeepAlive({required this.child});

  @override
  State<_KeepAlive> createState() => _KeepAliveState();
}

class _KeepAliveState extends State<_KeepAlive>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

