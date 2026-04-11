import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finance_app/core/utils/responsive_utils.dart';

void main() {
  group('ResponsiveUtils', () {
    testWidgets('getScreenSize returns correct size for small phone', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(320, 568)),
            child: Builder(
              builder: (context) {
                final screenSize = ResponsiveUtils.getScreenSize(context);
                expect(screenSize, ScreenSize.smallPhone);
                return Container();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('getScreenSize returns correct size for standard phone', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(375, 667)),
            child: Builder(
              builder: (context) {
                final screenSize = ResponsiveUtils.getScreenSize(context);
                expect(screenSize, ScreenSize.standardPhone);
                return Container();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('getScreenSize returns correct size for large phone', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(414, 896)),
            child: Builder(
              builder: (context) {
                final screenSize = ResponsiveUtils.getScreenSize(context);
                expect(screenSize, ScreenSize.standardPhone);
                return Container();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('getScreenSize returns correct size for tablet', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(1024, 768)),
            child: Builder(
              builder: (context) {
                final screenSize = ResponsiveUtils.getScreenSize(context);
                expect(screenSize, ScreenSize.tablet);
                return Container();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('isPortrait returns true for portrait orientation', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(375, 667),
            ),
            child: Builder(
              builder: (context) {
                expect(ResponsiveUtils.isPortrait(context), true);
                expect(ResponsiveUtils.isLandscape(context), false);
                return Container();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('isLandscape returns true for landscape orientation', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(667, 375),
            ),
            child: Builder(
              builder: (context) {
                expect(ResponsiveUtils.isLandscape(context), true);
                expect(ResponsiveUtils.isPortrait(context), false);
                return Container();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('getResponsivePadding returns correct padding for small phone', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(320, 568)),
            child: Builder(
              builder: (context) {
                final padding = ResponsiveUtils.getResponsivePadding(context);
                expect(padding, const EdgeInsets.all(8));
                return Container();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('getResponsivePadding returns correct padding for tablet', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(1024, 768)),
            child: Builder(
              builder: (context) {
                final padding = ResponsiveUtils.getResponsivePadding(context);
                expect(padding, const EdgeInsets.all(24));
                return Container();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('getFontSizeMultiplier returns correct multiplier', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(320, 568)),
            child: Builder(
              builder: (context) {
                final multiplier = ResponsiveUtils.getFontSizeMultiplier(context);
                expect(multiplier, 0.9);
                return Container();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('getResponsiveIconSize returns correct size', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(375, 667)),
            child: Builder(
              builder: (context) {
                final iconSize = ResponsiveUtils.getResponsiveIconSize(context);
                expect(iconSize, 24);
                return Container();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('getResponsiveGridCrossAxisCount adjusts for orientation', (tester) async {
      // Portrait
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(375, 667),
            ),
            child: Builder(
              builder: (context) {
                final count = ResponsiveUtils.getResponsiveGridCrossAxisCount(context);
                expect(count, 2);
                return Container();
              },
            ),
          ),
        ),
      );

      // Landscape (667x375 is still standard phone, but landscape, so should be 3)
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(667, 375),
            ),
            child: Builder(
              builder: (context) {
                final count = ResponsiveUtils.getResponsiveGridCrossAxisCount(context);
                // 667 width is still standard phone (< 840), landscape mode
                expect(count, 4); // Standard phone landscape gets 4 columns based on width
                return Container();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('shouldUseSideNavigation returns true for tablet landscape', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(1024, 768),
            ),
            child: Builder(
              builder: (context) {
                final useSideNav = ResponsiveUtils.shouldUseSideNavigation(context);
                expect(useSideNav, true);
                return Container();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('shouldUseSideNavigation returns false for phone', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(375, 667),
            ),
            child: Builder(
              builder: (context) {
                final useSideNav = ResponsiveUtils.shouldUseSideNavigation(context);
                expect(useSideNav, false);
                return Container();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('context extensions work correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(375, 667)),
            child: Builder(
              builder: (context) {
                expect(context.screenSize, ScreenSize.standardPhone);
                expect(context.isPortrait, true);
                expect(context.responsiveSpacing, 12);
                expect(context.fontSizeMultiplier, 1.0);
                return Container();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('getResponsiveFormColumns returns correct count', (tester) async {
      // Small phone portrait - 1 column
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 568),
            ),
            child: Builder(
              builder: (context) {
                final columns = ResponsiveUtils.getResponsiveFormColumns(context);
                expect(columns, 1);
                return Container();
              },
            ),
          ),
        ),
      );

      // Tablet - 2 columns
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(1024, 768),
            ),
            child: Builder(
              builder: (context) {
                final columns = ResponsiveUtils.getResponsiveFormColumns(context);
                expect(columns, 2);
                return Container();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('getResponsiveMaxContentWidth limits width for tablets', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(1024, 768)),
            child: Builder(
              builder: (context) {
                final maxWidth = ResponsiveUtils.getResponsiveMaxContentWidth(context);
                expect(maxWidth, 1200);
                return Container();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('getResponsiveMaxContentWidth returns infinity for phones', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(375, 667)),
            child: Builder(
              builder: (context) {
                final maxWidth = ResponsiveUtils.getResponsiveMaxContentWidth(context);
                expect(maxWidth, double.infinity);
                return Container();
              },
            ),
          ),
        ),
      );
    });
  });
}
