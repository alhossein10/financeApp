# Exchange Feature - Flutter Integration Guide

## Overview

The Exchange feature allows users to convert USD amounts from their transfers to Syrian Pounds (SYP). Users provide the exchange rate at the time of exchange, and the system tracks all exchanges with detailed logs visible to both users and admins.

## Key Concepts

### 1. Exchange Flow
- Admin transfers USD to a user
- User can exchange portions of the transfer amount to SYP
- User provides the current exchange rate (e.g., 1 USD = 11,600 SYP)
- System calculates and stores the SYP amount
- Multiple exchanges can be made from the same transfer
- Balance tracking prevents over-exchange

### 2. Permissions
- **Users**: Can exchange from their own transfers and view their exchanges
- **Admins**: Can view all exchanges in their admin group

## API Endpoints

### Base URL
```
https://your-api-domain.com/api/v1
```

All endpoints require authentication via Bearer token.

---

## 1. Create Exchange

**Endpoint:** `POST /exchanges`

**Description:** Create a new exchange from USD to SYP

**Headers:**
```
Authorization: Bearer {token}
Content-Type: application/json
```

**Request Body:**
```json
{
  "transfer_id": 1,
  "amount_usd": 100.00,
  "exchange_rate": 11600.00,
  "exchange_date": "2025-11-02",
  "notes": "Exchange for daily expenses"
}
```

**Field Descriptions:**
- `transfer_id` (required, integer): ID of the transfer to exchange from
- `amount_usd` (required, decimal): Amount in USD to exchange (must not exceed remaining balance)
- `exchange_rate` (required, decimal): Current exchange rate (1 USD = X SYP)
- `exchange_date` (required, date): Date of exchange (format: YYYY-MM-DD)
- `notes` (optional, string): Additional notes about the exchange

**Success Response (201):**
```json
{
  "message": "Exchange created successfully",
  "data": {
    "id": 1,
    "transfer_id": 1,
    "user_id": 5,
    "admin_group_id": 2,
    "amount_usd": "100.00",
    "exchange_rate": "11600.00",
    "amount_syp": "1160000.00",
    "exchange_date": "2025-11-02",
    "notes": "Exchange for daily expenses",
    "created_at": "2025-11-02T10:30:00.000000Z",
    "updated_at": "2025-11-02T10:30:00.000000Z",
    "transfer": {
      "id": 1,
      "recipient_name": "John Doe",
      "amount_usd": "500.00",
      "transfer_date": "2025-11-01"
    },
    "user": {
      "id": 5,
      "name": "John Doe",
      "email": "john@example.com"
    }
  }
}
```

**Error Response (400):**
```json
{
  "message": "Failed to create exchange",
  "error": "Insufficient balance. Available: 50 USD"
}
```

**Validation Errors (422):**
```json
{
  "message": "The given data was invalid.",
  "errors": {
    "transfer_id": ["Transfer not found"],
    "amount_usd": ["Amount must be at least 0.01"],
    "exchange_rate": ["Exchange rate is required"]
  }
}
```

---

## 2. Get All Exchanges

**Endpoint:** `GET /exchanges`

**Description:** Get all exchanges for the authenticated user (or all in admin group for admins)

**Headers:**
```
Authorization: Bearer {token}
```

**Success Response (200):**
```json
{
  "message": "Exchanges retrieved successfully",
  "data": [
    {
      "id": 1,
      "transfer_id": 1,
      "user_id": 5,
      "amount_usd": "100.00",
      "exchange_rate": "11600.00",
      "amount_syp": "1160000.00",
      "exchange_date": "2025-11-02",
      "notes": "First exchange",
      "created_at": "2025-11-02T10:30:00.000000Z",
      "transfer": {
        "id": 1,
        "recipient_name": "John Doe",
        "amount_usd": "500.00"
      },
      "user": {
        "id": 5,
        "name": "John Doe"
      }
    },
    {
      "id": 2,
      "transfer_id": 1,
      "user_id": 5,
      "amount_usd": "50.00",
      "exchange_rate": "11700.00",
      "amount_syp": "585000.00",
      "exchange_date": "2025-11-03",
      "notes": "Second exchange",
      "created_at": "2025-11-03T14:20:00.000000Z",
      "transfer": {
        "id": 1,
        "recipient_name": "John Doe",
        "amount_usd": "500.00"
      },
      "user": {
        "id": 5,
        "name": "John Doe"
      }
    }
  ]
}
```

---

## 3. Get Exchange by ID

**Endpoint:** `GET /exchanges/{id}`

**Description:** Get details of a specific exchange

**Headers:**
```
Authorization: Bearer {token}
```

**Success Response (200):**
```json
{
  "message": "Exchange retrieved successfully",
  "data": {
    "id": 1,
    "transfer_id": 1,
    "user_id": 5,
    "amount_usd": "100.00",
    "exchange_rate": "11600.00",
    "amount_syp": "1160000.00",
    "exchange_date": "2025-11-02",
    "notes": "Exchange for daily expenses",
    "created_at": "2025-11-02T10:30:00.000000Z",
    "transfer": {
      "id": 1,
      "recipient_name": "John Doe",
      "amount_usd": "500.00",
      "transfer_date": "2025-11-01"
    },
    "user": {
      "id": 5,
      "name": "John Doe",
      "email": "john@example.com"
    }
  }
}
```

**Error Response (404):**
```json
{
  "message": "Exchange not found"
}
```

---

## 4. Get Exchanges by Transfer

**Endpoint:** `GET /exchanges/transfer/{transferId}`

**Description:** Get all exchanges for a specific transfer

**Headers:**
```
Authorization: Bearer {token}
```

**Success Response (200):**
```json
{
  "message": "Transfer exchanges retrieved successfully",
  "data": [
    {
      "id": 1,
      "transfer_id": 1,
      "amount_usd": "100.00",
      "exchange_rate": "11600.00",
      "amount_syp": "1160000.00",
      "exchange_date": "2025-11-02"
    },
    {
      "id": 2,
      "transfer_id": 1,
      "amount_usd": "50.00",
      "exchange_rate": "11700.00",
      "amount_syp": "585000.00",
      "exchange_date": "2025-11-03"
    }
  ]
}
```

---

## 5. Get Transfer Balance

**Endpoint:** `GET /exchanges/transfer/{transferId}/balance`

**Description:** Get transfer balance showing original amount, total exchanged, and remaining balance

**Headers:**
```
Authorization: Bearer {token}
```

**Success Response (200):**
```json
{
  "message": "Transfer balance retrieved successfully",
  "data": {
    "transfer_id": 1,
    "original_amount": 500.00,
    "total_exchanged": 150.00,
    "remaining_balance": 350.00,
    "recipient_name": "John Doe",
    "transfer_date": "2025-11-01"
  }
}
```

---

## Flutter Implementation Examples

### 1. Data Models

```dart
class Exchange {
  final int id;
  final int transferId;
  final int userId;
  final int? adminGroupId;
  final double amountUsd;
  final double exchangeRate;
  final double amountSyp;
  final DateTime exchangeDate;
  final String? notes;
  final DateTime createdAt;
  final Transfer? transfer;
  final User? user;

  Exchange({
    required this.id,
    required this.transferId,
    required this.userId,
    this.adminGroupId,
    required this.amountUsd,
    required this.exchangeRate,
    required this.amountSyp,
    required this.exchangeDate,
    this.notes,
    required this.createdAt,
    this.transfer,
    this.user,
  });

  factory Exchange.fromJson(Map<String, dynamic> json) {
    return Exchange(
      id: json['id'],
      transferId: json['transfer_id'],
      userId: json['user_id'],
      adminGroupId: json['admin_group_id'],
      amountUsd: double.parse(json['amount_usd'].toString()),
      exchangeRate: double.parse(json['exchange_rate'].toString()),
      amountSyp: double.parse(json['amount_syp'].toString()),
      exchangeDate: DateTime.parse(json['exchange_date']),
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
      transfer: json['transfer'] != null ? Transfer.fromJson(json['transfer']) : null,
      user: json['user'] != null ? User.fromJson(json['user']) : null,
    );
  }
}

class TransferBalance {
  final int transferId;
  final double originalAmount;
  final double totalExchanged;
  final double remainingBalance;
  final String recipientName;
  final DateTime transferDate;

  TransferBalance({
    required this.transferId,
    required this.originalAmount,
    required this.totalExchanged,
    required this.remainingBalance,
    required this.recipientName,
    required this.transferDate,
  });

  factory TransferBalance.fromJson(Map<String, dynamic> json) {
    return TransferBalance(
      transferId: json['transfer_id'],
      originalAmount: json['original_amount'].toDouble(),
      totalExchanged: json['total_exchanged'].toDouble(),
      remainingBalance: json['remaining_balance'].toDouble(),
      recipientName: json['recipient_name'],
      transferDate: DateTime.parse(json['transfer_date']),
    );
  }
}
```

### 2. API Service

```dart
class ExchangeService {
  final String baseUrl;
  final String token;

  ExchangeService({required this.baseUrl, required this.token});

  Future<Exchange> createExchange({
    required int transferId,
    required double amountUsd,
    required double exchangeRate,
    required DateTime exchangeDate,
    String? notes,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/exchanges'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'transfer_id': transferId,
        'amount_usd': amountUsd,
        'exchange_rate': exchangeRate,
        'exchange_date': exchangeDate.toIso8601String().split('T')[0],
        'notes': notes,
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return Exchange.fromJson(data['data']);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to create exchange');
    }
  }

  Future<List<Exchange>> getAllExchanges() async {
    final response = await http.get(
      Uri.parse('$baseUrl/exchanges'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['data'] as List)
          .map((json) => Exchange.fromJson(json))
          .toList();
    } else {
      throw Exception('Failed to load exchanges');
    }
  }

  Future<Exchange> getExchangeById(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/exchanges/$id'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Exchange.fromJson(data['data']);
    } else {
      throw Exception('Exchange not found');
    }
  }

  Future<List<Exchange>> getExchangesByTransfer(int transferId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/exchanges/transfer/$transferId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['data'] as List)
          .map((json) => Exchange.fromJson(json))
          .toList();
    } else {
      throw Exception('Failed to load transfer exchanges');
    }
  }

  Future<TransferBalance> getTransferBalance(int transferId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/exchanges/transfer/$transferId/balance'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return TransferBalance.fromJson(data['data']);
    } else {
      throw Exception('Failed to load transfer balance');
    }
  }
}
```

### 3. UI Example - Create Exchange Screen

```dart
class CreateExchangeScreen extends StatefulWidget {
  final Transfer transfer;

  const CreateExchangeScreen({Key? key, required this.transfer}) : super(key: key);

  @override
  _CreateExchangeScreenState createState() => _CreateExchangeScreenState();
}

class _CreateExchangeScreenState extends State<CreateExchangeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _exchangeRateController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TransferBalance? _balance;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  Future<void> _loadBalance() async {
    try {
      final balance = await ExchangeService(
        baseUrl: 'YOUR_API_URL',
        token: 'YOUR_TOKEN',
      ).getTransferBalance(widget.transfer.id);
      
      setState(() {
        _balance = balance;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading balance: $e')),
      );
    }
  }

  Future<void> _createExchange() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final exchange = await ExchangeService(
        baseUrl: 'YOUR_API_URL',
        token: 'YOUR_TOKEN',
      ).createExchange(
        transferId: widget.transfer.id,
        amountUsd: double.parse(_amountController.text),
        exchangeRate: double.parse(_exchangeRateController.text),
        exchangeDate: _selectedDate,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exchange created successfully!')),
      );

      Navigator.pop(context, exchange);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Exchange'),
      ),
      body: _balance == null
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Balance Card
                    Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Transfer Balance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            SizedBox(height: 8),
                            Text('Original Amount: \$${_balance!.originalAmount.toStringAsFixed(2)}'),
                            Text('Total Exchanged: \$${_balance!.totalExchanged.toStringAsFixed(2)}'),
                            Text(
                              'Available: \$${_balance!.remainingBalance.toStringAsFixed(2)}',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 20),

                    // Amount USD
                    TextFormField(
                      controller: _amountController,
                      decoration: InputDecoration(
                        labelText: 'Amount (USD)',
                        border: OutlineInputBorder(),
                        prefixText: '\$ ',
                      ),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter amount';
                        }
                        final amount = double.tryParse(value);
                        if (amount == null || amount <= 0) {
                          return 'Please enter valid amount';
                        }
                        if (amount > _balance!.remainingBalance) {
                          return 'Amount exceeds available balance';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),

                    // Exchange Rate
                    TextFormField(
                      controller: _exchangeRateController,
                      decoration: InputDecoration(
                        labelText: 'Exchange Rate (1 USD = X SYP)',
                        border: OutlineInputBorder(),
                        helperText: 'Enter today\'s exchange rate',
                      ),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter exchange rate';
                        }
                        final rate = double.tryParse(value);
                        if (rate == null || rate <= 0) {
                          return 'Please enter valid rate';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        setState(() {}); // Trigger rebuild to update SYP preview
                      },
                    ),
                    SizedBox(height: 8),

                    // SYP Preview
                    if (_amountController.text.isNotEmpty && _exchangeRateController.text.isNotEmpty)
                      Card(
                        color: Colors.blue.shade50,
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('You will receive:'),
                              Text(
                                '${(double.tryParse(_amountController.text) ?? 0) * (double.tryParse(_exchangeRateController.text) ?? 0)} SYP',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    SizedBox(height: 16),

                    // Exchange Date
                    ListTile(
                      title: Text('Exchange Date'),
                      subtitle: Text('${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}'),
                      trailing: Icon(Icons.calendar_today),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() {
                            _selectedDate = date;
                          });
                        }
                      },
                    ),
                    SizedBox(height: 16),

                    // Notes
                    TextFormField(
                      controller: _notesController,
                      decoration: InputDecoration(
                        labelText: 'Notes (Optional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    SizedBox(height: 24),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _createExchange,
                        child: _isLoading
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text('Create Exchange'),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
```

### 4. UI Example - Exchange History List

```dart
class ExchangeHistoryScreen extends StatefulWidget {
  @override
  _ExchangeHistoryScreenState createState() => _ExchangeHistoryScreenState();
}

class _ExchangeHistoryScreenState extends State<ExchangeHistoryScreen> {
  List<Exchange> _exchanges = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExchanges();
  }

  Future<void> _loadExchanges() async {
    try {
      final exchanges = await ExchangeService(
        baseUrl: 'YOUR_API_URL',
        token: 'YOUR_TOKEN',
      ).getAllExchanges();

      setState(() {
        _exchanges = exchanges;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading exchanges: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Exchange History'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _exchanges.isEmpty
              ? Center(child: Text('No exchanges yet'))
              : ListView.builder(
                  itemCount: _exchanges.length,
                  itemBuilder: (context, index) {
                    final exchange = _exchanges[index];
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Icon(Icons.currency_exchange),
                        ),
                        title: Text('\$${exchange.amountUsd} → ${exchange.amountSyp} SYP'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Rate: 1 USD = ${exchange.exchangeRate} SYP'),
                            Text('Date: ${exchange.exchangeDate.toString().split(' ')[0]}'),
                            if (exchange.notes != null) Text('Notes: ${exchange.notes}'),
                          ],
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
    );
  }
}
```

## Important Notes for Frontend Team

### 1. Balance Validation
- Always check transfer balance before allowing exchange
- Show remaining balance prominently in the UI
- Prevent users from entering amounts exceeding the balance

### 2. Exchange Rate Input
- The exchange rate is user-provided (not fetched from API)
- Consider adding a helper text showing recent rates if available
- Format: 1 USD = X SYP (e.g., 11600)

### 3. SYP Calculation
- Frontend should show a preview: `amount_usd * exchange_rate = amount_syp`
- Backend calculates and stores the final SYP amount
- Display SYP amounts with proper formatting (large numbers)

### 4. Admin View
- Admins see all exchanges in their group
- Show which user made each exchange
- Consider adding filters by date, user, or transfer

### 5. Error Handling
- Handle "Insufficient balance" errors gracefully
- Show validation errors clearly
- Provide retry options for network failures

### 6. Date Handling
- Exchange date should not be in the future
- Use date picker for better UX
- Format: YYYY-MM-DD for API

### 7. Number Formatting
- USD: 2 decimal places (e.g., 100.00)
- SYP: 2 decimal places but large numbers (e.g., 1,160,000.00)
- Exchange rate: 2 decimal places (e.g., 11600.00)

## Testing Checklist

- [ ] Create exchange with valid data
- [ ] Validate insufficient balance error
- [ ] Create multiple exchanges from same transfer
- [ ] View exchange history
- [ ] View exchanges for specific transfer
- [ ] Check transfer balance updates
- [ ] Admin can view all group exchanges
- [ ] User can only view their exchanges
- [ ] Handle network errors
- [ ] Test with large SYP amounts
- [ ] Verify SYP calculation accuracy

## Support

For questions or issues, contact the backend team or refer to the Postman collection for detailed API examples.
