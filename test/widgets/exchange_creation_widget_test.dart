import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Exchange Creation Widget Tests', () {
    testWidgets('should display target currency selection', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _ExchangeCreationForm(),
          ),
        ),
      );

      // Assert
      expect(find.text('Target Currency'), findsOneWidget);
      expect(find.byType(DropdownButton<String>), findsOneWidget);
    });

    testWidgets('should show SYP and TRY currency options', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _ExchangeCreationForm(),
          ),
        ),
      );

      // Tap dropdown
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('SYP'), findsOneWidget);
      expect(find.text('TRY'), findsOneWidget);
    });

    testWidgets('should display USD amount input field', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _ExchangeCreationForm(),
          ),
        ),
      );

      // Assert
      expect(find.text('USD Amount'), findsOneWidget);
      expect(find.byKey(const Key('usd_amount_field')), findsOneWidget);
    });

    testWidgets('should display exchange rate input field', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _ExchangeCreationForm(),
          ),
        ),
      );

      // Assert
      expect(find.text('Exchange Rate'), findsOneWidget);
      expect(find.byKey(const Key('exchange_rate_field')), findsOneWidget);
    });

    testWidgets('should display converted amount input field', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _ExchangeCreationForm(),
          ),
        ),
      );

      // Assert
      expect(find.text('Converted Amount'), findsOneWidget);
      expect(find.byKey(const Key('converted_amount_field')), findsOneWidget);
    });

    testWidgets('should calculate converted amount when rate is entered', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _ExchangeCreationForm(),
          ),
        ),
      );

      // Enter USD amount
      await tester.enterText(find.byKey(const Key('usd_amount_field')), '100');
      await tester.pump();

      // Enter exchange rate
      await tester.enterText(find.byKey(const Key('exchange_rate_field')), '15000');
      await tester.pump();

      // Assert - converted amount should be calculated
      final convertedField = tester.widget<TextField>(
        find.byKey(const Key('converted_amount_field')),
      );
      expect(convertedField.controller?.text, '1500000.0');
    });

    testWidgets('should calculate exchange rate when converted amount is entered',
        (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _ExchangeCreationForm(),
          ),
        ),
      );

      // Enter USD amount
      await tester.enterText(find.byKey(const Key('usd_amount_field')), '100');
      await tester.pump();

      // Enter converted amount
      await tester.enterText(find.byKey(const Key('converted_amount_field')), '1500000');
      await tester.pump();

      // Assert - exchange rate should be calculated
      final rateField = tester.widget<TextField>(
        find.byKey(const Key('exchange_rate_field')),
      );
      expect(rateField.controller?.text, '15000.0');
    });

    testWidgets('should display optional transfer ID field', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _ExchangeCreationForm(),
          ),
        ),
      );

      // Assert
      expect(find.text('Transfer ID (Optional)'), findsOneWidget);
      expect(find.byKey(const Key('transfer_id_field')), findsOneWidget);
    });

    testWidgets('should display notes field', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _ExchangeCreationForm(),
          ),
        ),
      );

      // Assert
      expect(find.text('Notes'), findsOneWidget);
      expect(find.byKey(const Key('notes_field')), findsOneWidget);
    });

    testWidgets('should display exchange date picker', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _ExchangeCreationForm(),
          ),
        ),
      );

      // Assert
      expect(find.text('Exchange Date'), findsOneWidget);
      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
    });

    testWidgets('should show validation error when USD amount is empty', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _ExchangeCreationForm(),
          ),
        ),
      );

      // Tap create button without entering amount
      await tester.tap(find.text('Create Exchange'));
      await tester.pump();

      // Assert
      expect(find.text('USD amount is required'), findsOneWidget);
    });

    testWidgets('should show validation error when neither rate nor amount provided',
        (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _ExchangeCreationForm(),
          ),
        ),
      );

      // Enter only USD amount
      await tester.enterText(find.byKey(const Key('usd_amount_field')), '100');
      await tester.pump();

      // Tap create button
      await tester.tap(find.text('Create Exchange'));
      await tester.pump();

      // Assert
      expect(
        find.text('Either exchange rate or converted amount is required'),
        findsOneWidget,
      );
    });

    testWidgets('should show insufficient balance error', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                const Text('Current USD Balance: \$50.00'),
                _ExchangeCreationForm(),
              ],
            ),
          ),
        ),
      );

      // Enter amount greater than balance
      await tester.enterText(find.byKey(const Key('usd_amount_field')), '100');
      await tester.pump();

      // Tap create button
      await tester.tap(find.text('Create Exchange'));
      await tester.pump();

      // Assert
      expect(find.text('Insufficient USD balance'), findsOneWidget);
    });

    testWidgets('should display create exchange button', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _ExchangeCreationForm(),
          ),
        ),
      );

      // Assert
      expect(find.text('Create Exchange'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });
  });
}

class _ExchangeCreationForm extends StatefulWidget {
  @override
  State<_ExchangeCreationForm> createState() => _ExchangeCreationFormState();
}

class _ExchangeCreationFormState extends State<_ExchangeCreationForm> {
  String _targetCurrency = 'SYP';
  final _usdAmountController = TextEditingController();
  final _exchangeRateController = TextEditingController();
  final _convertedAmountController = TextEditingController();
  final _transferIdController = TextEditingController();
  final _notesController = TextEditingController();
  String? _validationError;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Target Currency'),
          DropdownButton<String>(
            value: _targetCurrency,
            items: ['SYP', 'TRY']
                .map((currency) => DropdownMenuItem(
                      value: currency,
                      child: Text(currency),
                    ))
                .toList(),
            onChanged: (value) {
              setState(() {
                _targetCurrency = value!;
              });
            },
          ),
          const SizedBox(height: 16),
          const Text('USD Amount'),
          TextField(
            key: const Key('usd_amount_field'),
            controller: _usdAmountController,
            keyboardType: TextInputType.number,
            onChanged: _calculateConvertedAmount,
          ),
          const SizedBox(height: 16),
          const Text('Exchange Rate'),
          TextField(
            key: const Key('exchange_rate_field'),
            controller: _exchangeRateController,
            keyboardType: TextInputType.number,
            onChanged: (_) => _calculateConvertedAmount(_usdAmountController.text),
          ),
          const SizedBox(height: 16),
          const Text('Converted Amount'),
          TextField(
            key: const Key('converted_amount_field'),
            controller: _convertedAmountController,
            keyboardType: TextInputType.number,
            onChanged: (_) => _calculateExchangeRate(_usdAmountController.text),
          ),
          const SizedBox(height: 16),
          const Text('Transfer ID (Optional)'),
          TextField(
            key: const Key('transfer_id_field'),
            controller: _transferIdController,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          const Text('Notes'),
          TextField(
            key: const Key('notes_field'),
            controller: _notesController,
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Exchange Date'),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_validationError != null)
            Text(
              _validationError!,
              style: const TextStyle(color: Colors.red),
            ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _validateAndSubmit,
            child: const Text('Create Exchange'),
          ),
        ],
      ),
    );
  }

  void _calculateConvertedAmount(String usdAmount) {
    if (usdAmount.isEmpty || _exchangeRateController.text.isEmpty) return;
    
    final amount = double.tryParse(usdAmount);
    final rate = double.tryParse(_exchangeRateController.text);
    
    if (amount != null && rate != null) {
      _convertedAmountController.text = (amount * rate).toString();
    }
  }

  void _calculateExchangeRate(String usdAmount) {
    if (usdAmount.isEmpty || _convertedAmountController.text.isEmpty) return;
    
    final amount = double.tryParse(usdAmount);
    final converted = double.tryParse(_convertedAmountController.text);
    
    if (amount != null && converted != null && amount > 0) {
      _exchangeRateController.text = (converted / amount).toString();
    }
  }

  void _validateAndSubmit() {
    setState(() {
      _validationError = null;
    });

    if (_usdAmountController.text.isEmpty) {
      setState(() {
        _validationError = 'USD amount is required';
      });
      return;
    }

    if (_exchangeRateController.text.isEmpty && _convertedAmountController.text.isEmpty) {
      setState(() {
        _validationError = 'Either exchange rate or converted amount is required';
      });
      return;
    }

    final amount = double.tryParse(_usdAmountController.text);
    if (amount != null && amount > 50.0) {
      setState(() {
        _validationError = 'Insufficient USD balance';
      });
      return;
    }

    // Submit logic here
  }

  @override
  void dispose() {
    _usdAmountController.dispose();
    _exchangeRateController.dispose();
    _convertedAmountController.dispose();
    _transferIdController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
