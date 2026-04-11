import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SuperAdmin Group Management Widget Tests', () {
    testWidgets('should display group code prominently', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _GroupManagementPage(
              groupCode: '123456',
              memberCount: 5,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Group Code'), findsOneWidget);
      expect(find.text('123456'), findsOneWidget);
    });

    testWidgets('should display member count', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _GroupManagementPage(
              groupCode: '123456',
              memberCount: 5,
            ),
          ),
        ),
      );

      // Assert
      expect(find.textContaining('5 members'), findsOneWidget);
    });

    testWidgets('should display regenerate code button', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _GroupManagementPage(
              groupCode: '123456',
              memberCount: 5,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Regenerate Code'), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('should show confirmation dialog when regenerating code', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _GroupManagementPage(
              groupCode: '123456',
              memberCount: 5,
            ),
          ),
        ),
      );

      // Tap regenerate button
      await tester.tap(find.text('Regenerate Code'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Regenerate Group Code?'), findsOneWidget);
      expect(find.text('This will invalidate the current code'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Regenerate'), findsOneWidget);
    });

    testWidgets('should display member list', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _GroupManagementPage(
              groupCode: '123456',
              memberCount: 2,
              members: [
                _AdminMember(id: 1, name: 'Admin 1', email: 'admin1@test.com'),
                _AdminMember(id: 2, name: 'Admin 2', email: 'admin2@test.com'),
              ],
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Admin 1'), findsOneWidget);
      expect(find.text('admin1@test.com'), findsOneWidget);
      expect(find.text('Admin 2'), findsOneWidget);
      expect(find.text('admin2@test.com'), findsOneWidget);
    });

    testWidgets('should display remove button for each member', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _GroupManagementPage(
              groupCode: '123456',
              memberCount: 2,
              members: [
                _AdminMember(id: 1, name: 'Admin 1', email: 'admin1@test.com'),
                _AdminMember(id: 2, name: 'Admin 2', email: 'admin2@test.com'),
              ],
            ),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.delete), findsNWidgets(2));
    });

    testWidgets('should show confirmation dialog when removing member', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _GroupManagementPage(
              groupCode: '123456',
              memberCount: 1,
              members: [
                _AdminMember(id: 1, name: 'Admin 1', email: 'admin1@test.com'),
              ],
            ),
          ),
        ),
      );

      // Tap remove button
      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Remove Member?'), findsOneWidget);
      expect(find.textContaining('Admin 1'), findsWidgets);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Remove'), findsOneWidget);
    });

    testWidgets('should display pagination controls', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _GroupManagementPage(
              groupCode: '123456',
              memberCount: 20,
              currentPage: 1,
              totalPages: 2,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Page 1 of 2'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
    });

    testWidgets('should disable previous button on first page', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _GroupManagementPage(
              groupCode: '123456',
              memberCount: 20,
              currentPage: 1,
              totalPages: 2,
            ),
          ),
        ),
      );

      // Assert
      final prevButton = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.arrow_back),
      );
      expect(prevButton.onPressed, isNull);
    });

    testWidgets('should disable next button on last page', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _GroupManagementPage(
              groupCode: '123456',
              memberCount: 20,
              currentPage: 2,
              totalPages: 2,
            ),
          ),
        ),
      );

      // Assert
      final nextButton = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.arrow_forward),
      );
      expect(nextButton.onPressed, isNull);
    });

    testWidgets('should show empty state when no members', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _GroupManagementPage(
              groupCode: '123456',
              memberCount: 0,
              members: [],
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('No members yet'), findsOneWidget);
    });

    testWidgets('should display loading indicator while fetching members', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _GroupManagementPage(
              groupCode: '123456',
              memberCount: 5,
              isLoading: true,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should show new code after regeneration', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _GroupManagementPage(
              groupCode: '123456',
              memberCount: 5,
              newCode: '789012',
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('New Group Code'), findsOneWidget);
      expect(find.text('789012'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });
  });
}

class _AdminMember {
  final int id;
  final String name;
  final String email;

  _AdminMember({required this.id, required this.name, required this.email});
}

class _GroupManagementPage extends StatelessWidget {
  final String groupCode;
  final int memberCount;
  final List<_AdminMember> members;
  final int currentPage;
  final int totalPages;
  final bool isLoading;
  final String? newCode;

  const _GroupManagementPage({
    required this.groupCode,
    required this.memberCount,
    this.members = const [],
    this.currentPage = 1,
    this.totalPages = 1,
    this.isLoading = false,
    this.newCode,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (newCode != null) ...[
            Card(
              color: Colors.green[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('New Group Code'),
                        Text(
                          newCode!,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Group Code'),
                  Text(
                    groupCode,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('$memberCount members'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _showRegenerateDialog(context),
            icon: const Icon(Icons.refresh),
            label: const Text('Regenerate Code'),
          ),
          const SizedBox(height: 24),
          const Text(
            'Members',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else if (members.isEmpty)
            const Center(child: Text('No members yet'))
          else
            ...members.map((member) => Card(
                  child: ListTile(
                    title: Text(member.name),
                    subtitle: Text(member.email),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _showRemoveDialog(context, member),
                    ),
                  ),
                )),
          if (totalPages > 1) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: currentPage > 1 ? () {} : null,
                ),
                Text('Page $currentPage of $totalPages'),
                IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: currentPage < totalPages ? () {} : null,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showRegenerateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Regenerate Group Code?'),
        content: const Text('This will invalidate the current code'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Regenerate'),
          ),
        ],
      ),
    );
  }

  void _showRemoveDialog(BuildContext context, _AdminMember member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member?'),
        content: Text('Remove ${member.name} from the group?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}
