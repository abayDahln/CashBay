import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cashbay/core/widgets/slide_indexed_stack.dart';

void main() {
  testWidgets('animates to the target page in the direction of travel', (
    tester,
  ) async {
    await tester.pumpWidget(_host(index: 0));
    await tester.pumpWidget(_host(index: 1));
    await tester.pump(const Duration(milliseconds: 1));

    // Mid-animation the viewport sits between page 0 and 1 (fractional page).
    final pageView = tester.widget<PageView>(find.byType(PageView));
    final offset = pageView.controller!.offset;
    final width = tester.getSize(find.byType(PageView)).width;
    expect(offset, greaterThan(0));
    expect(offset, lessThan(width));
  });

  testWidgets('settles exactly on the target page', (tester) async {
    await tester.pumpWidget(_host(index: 0));
    await tester.pumpWidget(_host(index: 2));
    await tester.pumpAndSettle();

    final pageView = tester.widget<PageView>(find.byType(PageView));
    final width = tester.getSize(find.byType(PageView)).width;
    expect(pageView.controller!.offset, closeTo(2 * width, 0.5));
  });

  testWidgets('shows the active child once settled', (tester) async {
    await tester.pumpWidget(_host(index: 1));
    await tester.pumpAndSettle();
    expect(find.text('one'), findsOneWidget);
  });
}

Widget _host({required int index}) {
  return MaterialApp(
    home: SlideIndexedStack(
      index: index,
      children: const [
        Center(child: Text('zero')),
        Center(child: Text('one')),
        Center(child: Text('two')),
      ],
    ),
  );
}
