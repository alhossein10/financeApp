import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finance_app/core/widgets/responsive_layout.dart';
import 'package:finance_app/core/widgets/responsive_text.dart';
import 'package:finance_app/core/widgets/responsive_scaffold.dart';

void main() {
  group('ResponsiveLayout', () {
    testWidgets('applies max width constraint for tablets', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(1024, 768)),
            child: ResponsiveLayout(
              child: Container(
                color: Colors.blue,
                child: const Text('Content'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Content'), findsOneWidget);
    });

    testWidgets('centers content when centerContent is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(375, 667)),
            child: ResponsiveLayout(
              centerContent: true,
              child: const Text('Centered'),
            ),
          ),
        ),
      );

      expect(find.byType(Center), findsOneWidget);
      expect(find.text('Centered'), findsOneWidget);
    });
  });

  group('ResponsivePadding', () {
    testWidgets('applies horizontal and vertical padding', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(375, 667)),
            child: ResponsivePadding(
              child: const Text('Padded'),
            ),
          ),
        ),
      );

      expect(find.byType(Padding), findsOneWidget);
      expect(find.text('Padded'), findsOneWidget);
    });

    testWidgets('applies only horizontal padding when specified', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(375, 667)),
            child: ResponsivePadding(
              horizontal: true,
              vertical: false,
              child: const Text('Horizontal Padded'),
            ),
          ),
        ),
      );

      expect(find.byType(Padding), findsOneWidget);
      expect(find.text('Horizontal Padded'), findsOneWidget);
    });
  });

  group('ResponsiveText', () {
    testWidgets('renders text with responsive scaling', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(375, 667)),
            child: const ResponsiveText(
              'Hello World',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
      );

      expect(find.text('Hello World'), findsOneWidget);
    });

    testWidgets('supports text scaling up to 200%', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(375, 667),
              textScaleFactor: 2.5, // Should be clamped to 2.0
            ),
            child: const ResponsiveText(
              'Scaled Text',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
      );

      expect(find.text('Scaled Text'), findsOneWidget);
    });

    testWidgets('handles text overflow', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(375, 667)),
            child: const SizedBox(
              width: 100,
              child: ResponsiveText(
                'Very long text that should overflow',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Very long text that should overflow'), findsOneWidget);
    });
  });

  group('ResponsiveHeading', () {
    testWidgets('renders heading with correct style', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(375, 667)),
            child: const ResponsiveHeading(
              'Heading',
              level: HeadingLevel.h1,
            ),
          ),
        ),
      );

      expect(find.text('Heading'), findsOneWidget);
    });

    testWidgets('supports different heading levels', (tester) async {
      for (final level in HeadingLevel.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(size: Size(375, 667)),
              child: ResponsiveHeading(
                'Heading ${level.name}',
                level: level,
              ),
            ),
          ),
        );

        expect(find.text('Heading ${level.name}'), findsOneWidget);
      }
    });
  });

  group('ResponsiveBodyText', () {
    testWidgets('renders body text with correct size', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(375, 667)),
            child: const ResponsiveBodyText(
              'Body text',
              size: BodyTextSize.medium,
            ),
          ),
        ),
      );

      expect(find.text('Body text'), findsOneWidget);
    });

    testWidgets('supports custom color and font weight', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(375, 667)),
            child: const ResponsiveBodyText(
              'Styled text',
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );

      expect(find.text('Styled text'), findsOneWidget);
    });
  });

  group('ResponsiveCard', () {
    testWidgets('renders card with responsive styling', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(375, 667)),
            child: ResponsiveCard(
              child: const Text('Card Content'),
            ),
          ),
        ),
      );

      expect(find.byType(Card), findsOneWidget);
      expect(find.text('Card Content'), findsOneWidget);
    });

    testWidgets('handles tap events', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(375, 667)),
            child: ResponsiveCard(
              onTap: () => tapped = true,
              child: const Text('Tappable Card'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tappable Card'));
      expect(tapped, true);
    });
  });

  group('ResponsiveButton', () {
    testWidgets('renders button with responsive width', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(375, 667)),
            child: ResponsiveButton(
              label: 'Submit',
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text('Submit'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('handles disabled state', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(375, 667)),
            child: const ResponsiveButton(
              label: 'Disabled',
              onPressed: null,
            ),
          ),
        ),
      );

      expect(find.text('Disabled'), findsOneWidget);
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, null);
    });
  });

  group('ResponsiveForm', () {
    testWidgets('renders single column on small screens', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(320, 568)),
            child: ResponsiveForm(
              children: const [
                TextField(decoration: InputDecoration(labelText: 'Field 1')),
                TextField(decoration: InputDecoration(labelText: 'Field 2')),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(TextField), findsNWidgets(2));
      expect(find.byType(Column), findsOneWidget);
    });

    testWidgets('renders two columns on tablets', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(1024, 768)),
            child: ResponsiveForm(
              children: const [
                TextField(decoration: InputDecoration(labelText: 'Field 1')),
                TextField(decoration: InputDecoration(labelText: 'Field 2')),
                TextField(decoration: InputDecoration(labelText: 'Field 3')),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(TextField), findsNWidgets(3));
      expect(find.byType(Row), findsNWidgets(2)); // Two rows for 3 fields
    });
  });

  group('ResponsiveScaffold', () {
    testWidgets('renders with bottom navigation on phones', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(375, 667),
            ),
            child: ResponsiveScaffold(
              title: 'Test Page',
              body: const Text('Content'),
              navigationDestinations: const [
                NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
                NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
              ],
              currentNavigationIndex: 0,
              onNavigationIndexChanged: (index) {},
            ),
          ),
        ),
      );

      expect(find.text('Test Page'), findsOneWidget);
      expect(find.text('Content'), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
    });

    testWidgets('renders with side navigation on tablets in landscape', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(1024, 768),
            ),
            child: ResponsiveScaffold(
              title: 'Test Page',
              body: const Text('Content'),
              navigationDestinations: const [
                NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
                NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
              ],
              currentNavigationIndex: 0,
              onNavigationIndexChanged: (index) {},
            ),
          ),
        ),
      );

      expect(find.text('Test Page'), findsOneWidget);
      expect(find.text('Content'), findsOneWidget);
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    });
  });

  group('ResponsiveDialog', () {
    testWidgets('renders dialog with responsive width', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(375, 667)),
            child: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => const ResponsiveDialog(
                        title: 'Test Dialog',
                        content: Text('Dialog content'),
                      ),
                    );
                  },
                  child: const Text('Show Dialog'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Test Dialog'), findsOneWidget);
      expect(find.text('Dialog content'), findsOneWidget);
    });

    testWidgets('renders dialog with actions', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(375, 667)),
            child: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => ResponsiveDialog(
                        title: 'Confirm',
                        content: const Text('Are you sure?'),
                        actions: [
                          TextButton(
                            onPressed: () {},
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () {},
                            child: const Text('Confirm'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text('Show Dialog'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Confirm'), findsOneWidget);
      expect(find.text('Are you sure?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Confirm'), findsNWidgets(2)); // Button text + dialog title
    });
  });

  group('ResponsiveListTile', () {
    testWidgets('renders list tile with responsive height', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(375, 667)),
            child: ResponsiveListTile(
              leading: const Icon(Icons.person),
              title: const Text('Title'),
              subtitle: const Text('Subtitle'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Title'), findsOneWidget);
      expect(find.text('Subtitle'), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });
  });

  group('ResponsiveImage', () {
    testWidgets('renders image with responsive size', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(375, 667)),
            child: const ResponsiveImage(
              imageUrl: 'https://example.com/image.jpg',
            ),
          ),
        ),
      );

      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('renders avatar with responsive size', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(375, 667)),
            child: const ResponsiveImage(
              imageUrl: 'https://example.com/avatar.jpg',
              isAvatar: true,
            ),
          ),
        ),
      );

      expect(find.byType(CircleAvatar), findsOneWidget);
    });
  });
}
