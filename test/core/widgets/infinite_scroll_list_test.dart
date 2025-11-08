import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finance_app/core/widgets/infinite_scroll_list.dart';

void main() {
  group('InfiniteScrollList', () {
    testWidgets('displays items correctly', (tester) async {
      final items = ['Item 1', 'Item 2', 'Item 3'];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InfiniteScrollList<String>(
              items: items,
              isLoading: false,
              hasMore: false,
              onLoadMore: () {},
              itemBuilder: (context, item) => Text(item),
            ),
          ),
        ),
      );

      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);
      expect(find.text('Item 3'), findsOneWidget);
    });

    testWidgets('shows loading widget when loading and empty', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InfiniteScrollList<String>(
              items: const [],
              isLoading: true,
              hasMore: false,
              onLoadMore: () {},
              itemBuilder: (context, item) => Text(item),
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows empty message when no items', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InfiniteScrollList<String>(
              items: const [],
              isLoading: false,
              hasMore: false,
              onLoadMore: () {},
              itemBuilder: (context, item) => Text(item),
              emptyMessage: 'No items found',
            ),
          ),
        ),
      );

      expect(find.text('No items found'), findsOneWidget);
      expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
    });

    testWidgets('shows custom empty widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InfiniteScrollList<String>(
              items: const [],
              isLoading: false,
              hasMore: false,
              onLoadMore: () {},
              itemBuilder: (context, item) => Text(item),
              emptyWidget: const Text('Custom empty'),
            ),
          ),
        ),
      );

      expect(find.text('Custom empty'), findsOneWidget);
    });

    testWidgets('shows load more indicator when hasMore is true', (tester) async {
      final items = ['Item 1', 'Item 2'];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InfiniteScrollList<String>(
              items: items,
              isLoading: false,
              hasMore: true,
              onLoadMore: () {},
              itemBuilder: (context, item) => Text(item),
            ),
          ),
        ),
      );

      // Should show items plus a loading indicator
      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows custom separator', (tester) async {
      final items = ['Item 1', 'Item 2'];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InfiniteScrollList<String>(
              items: items,
              isLoading: false,
              hasMore: false,
              onLoadMore: () {},
              itemBuilder: (context, item) => Text(item),
              separator: const Divider(key: Key('custom-divider')),
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('custom-divider')), findsOneWidget);
    });

    testWidgets('wraps with RefreshIndicator when onRefresh provided', (tester) async {
      final items = ['Item 1'];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InfiniteScrollList<String>(
              items: items,
              isLoading: false,
              hasMore: false,
              onLoadMore: () {},
              onRefresh: () async {},
              itemBuilder: (context, item) => Text(item),
            ),
          ),
        ),
      );

      expect(find.byType(RefreshIndicator), findsOneWidget);
    });
  });

  group('LoadMoreButton', () {
    testWidgets('shows button when hasMore is true and not loading', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoadMoreButton(
              isLoading: false,
              hasMore: true,
              onPressed: () {},
              text: 'Load More',
            ),
          ),
        ),
      );

      expect(find.text('Load More'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('shows loading indicator when loading', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoadMoreButton(
              isLoading: true,
              hasMore: true,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(ElevatedButton), findsNothing);
    });

    testWidgets('shows "No more items" when hasMore is false', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoadMoreButton(
              isLoading: false,
              hasMore: false,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text('No more items'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsNothing);
    });

    testWidgets('calls onPressed when button tapped', (tester) async {
      var pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoadMoreButton(
              isLoading: false,
              hasMore: true,
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      expect(pressed, true);
    });
  });
}
