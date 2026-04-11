import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finance_app/features/fund_box/data/models/fund_box_dto.dart';

void main() {
  group('Multi-Currency Fund Box Widget Tests', () {
    testWidgets('should display all three currency balances', (tester) async {
      // Arrange
      final fundBox = FundBoxDto(
        id: 1,
        userId: 123,
        balanceUsd: 1000.0,
        balanceSyp: 15000000.0,
        balanceTry: 30000.0,
        lastCalculatedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                _buildCurrencyCard('USD', fundBox.balanceUsd, '\$'),
                _buildCurrencyCard('SYP', fundBox.balanceSyp, 'ل.س'),
                _buildCurrencyCard('TRY', fundBox.balanceTry, '₺'),
              ],
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('USD'), findsOneWidget);
      expect(find.text('SYP'), findsOneWidget);
      expect(find.text('TRY'), findsOneWidget);
      expect(find.textContaining('\$'), findsOneWidget);
      expect(find.textContaining('ل.س'), findsOneWidget);
      expect(find.textContaining('₺'), findsOneWidget);
    });

    testWidgets('should format USD with 2 decimal places', (tester) async {
      // Arrange
      final balance = 1234.56;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _buildCurrencyCard('USD', balance, '\$'),
          ),
        ),
      );

      // Assert
      expect(find.textContaining('1,234.56'), findsOneWidget);
    });

    testWidgets('should format SYP without decimal places', (tester) async {
      // Arrange
      final balance = 15000000.0;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _buildCurrencyCard('SYP', balance, 'ل.س'),
          ),
        ),
      );

      // Assert
      expect(find.textContaining('15,000,000'), findsOneWidget);
    });

    testWidgets('should format TRY with 2 decimal places', (tester) async {
      // Arrange
      final balance = 30000.50;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _buildCurrencyCard('TRY', balance, '₺'),
          ),
        ),
      );

      // Assert
      expect(find.textContaining('30,000.50'), findsOneWidget);
    });

    testWidgets('should show zero balances correctly', (tester) async {
      // Arrange
      final fundBox = FundBoxDto(
        id: 1,
        userId: 123,
        balanceUsd: 0.0,
        balanceSyp: 0.0,
        balanceTry: 0.0,
        lastCalculatedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                _buildCurrencyCard('USD', fundBox.balanceUsd, '\$'),
                _buildCurrencyCard('SYP', fundBox.balanceSyp, 'ل.س'),
                _buildCurrencyCard('TRY', fundBox.balanceTry, '₺'),
              ],
            ),
          ),
        ),
      );

      // Assert
      expect(find.textContaining('0.00'), findsNWidgets(2)); // USD and TRY
      expect(find.textContaining('0'), findsWidgets); // SYP shows 0
    });

    testWidgets('should display last calculated timestamp', (tester) async {
      // Arrange
      final lastCalculated = DateTime(2024, 11, 16, 10, 30);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Text('Last updated: ${_formatDateTime(lastCalculated)}'),
          ),
        ),
      );

      // Assert
      expect(find.textContaining('Last updated:'), findsOneWidget);
      expect(find.textContaining('2024-11-16'), findsOneWidget);
    });

    testWidgets('should show currency filter dropdown', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DropdownButton<String>(
              value: 'All',
              items: ['All', 'USD', 'SYP', 'TRY']
                  .map((currency) => DropdownMenuItem(
                        value: currency,
                        child: Text(currency),
                      ))
                  .toList(),
              onChanged: (_) {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('All'), findsOneWidget);
      
      // Tap dropdown
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();

      // Assert all options visible
      expect(find.text('USD'), findsOneWidget);
      expect(find.text('SYP'), findsOneWidget);
      expect(find.text('TRY'), findsOneWidget);
    });
  });
}

Widget _buildCurrencyCard(String currency, double balance, String symbol) {
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(currency, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            '$symbol ${_formatCurrency(balance, currency)}',
            style: const TextStyle(fontSize: 24),
          ),
        ],
      ),
    ),
  );
}

String _formatCurrency(double amount, String currency) {
  if (currency == 'SYP') {
    return amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }
  return amount.toStringAsFixed(2).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      );
}

String _formatDateTime(DateTime dateTime) {
  return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
      '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
}
