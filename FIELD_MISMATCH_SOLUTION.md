# Field Mismatch - App vs Backend

## Problem Identified ✅

The app and backend are using **different field names**!

### App Sends (Flutter):
```json
{
  "user_id": 11,
  "description": "Grocery shopping",
  "price_usd": 14500.00,
  "price_syp": null,
  "price_try": null,
  "expense_date": "2024-10-23T00:00:00.000000Z",
  "has_invoice": false,
  "invoice_path": null
}
```

### Backend Expects (from Postman collection):
```json
{
  "amount": 150.5,
  "category": "Food",
  "description": "Grocery shopping",
  "date": "2024-10-23",
  "payment_method": "cash"
}
```

**These don't match!** That's why you get 401 (probably a validation error).

## Solution Options

### Option 1: Update Laravel Backend (RECOMMENDED)

Change your Laravel backend to accept the app's field names.

#### Laravel Migration

```php
// database/migrations/xxxx_create_expenses_table.php
Schema::create('expenses', function (Blueprint $table) {
    $table->id();
    $table->foreignId('user_id')->constrained()->onDelete('cascade');
    $table->string('description');
    $table->decimal('price_usd', 10, 2)->nullable();
    $table->decimal('price_syp', 10, 2)->nullable();
    $table->decimal('price_try', 10, 2)->nullable();
    $table->boolean('has_invoice')->default(false);
    $table->string('invoice_path')->nullable();
    $table->date('expense_date');
    $table->string('sync_status')->default('synced');
    $table->timestamp('synced_at')->nullable();
    $table->integer('sync_retry_count')->default(0);
    $table->text('sync_error_message')->nullable();
    $table->timestamps();
});
```

#### Laravel Controller

```php
// app/Http/Controllers/ExpenseController.php
public function store(Request $request)
{
    $validated = $request->validate([
        'description' => 'required|string|max:255',
        'price_usd' => 'nullable|numeric|min:0',
        'price_syp' => 'nullable|numeric|min:0',
        'price_try' => 'nullable|numeric|min:0',
        'expense_date' => 'required|date',
        'has_invoice' => 'boolean',
        'invoice_path' => 'nullable|string',
    ]);

    // At least one price must be provided
    if (!isset($validated['price_usd']) && 
        !isset($validated['price_syp']) && 
        !isset($validated['price_try'])) {
        return response()->json([
            'success' => false,
            'message' => 'At least one price (USD, SYP, or TRY) must be provided'
        ], 422);
    }

    $expense = $request->user()->expenses()->create([
        'description' => $validated['description'],
        'price_usd' => $validated['price_usd'] ?? null,
        'price_syp' => $validated['price_syp'] ?? null,
        'price_try' => $validated['price_try'] ?? null,
        'expense_date' => $validated['expense_date'],
        'has_invoice' => $validated['has_invoice'] ?? false,
        'invoice_path' => $validated['invoice_path'] ?? null,
        'sync_status' => 'synced',
        'synced_at' => now(),
        'sync_retry_count' => 0,
    ]);

    return response()->json([
        'success' => true,
        'message' => 'Expense created successfully',
        'data' => $expense
    ], 201);
}

public function index(Request $request)
{
    $expenses = $request->user()
        ->expenses()
        ->orderBy('expense_date', 'desc')
        ->paginate(15);

    return response()->json($expenses);
}
```

#### Laravel Model

```php
// app/Models/Expense.php
class Expense extends Model
{
    protected $fillable = [
        'user_id',
        'description',
        'price_usd',
        'price_syp',
        'price_try',
        'expense_date',
        'has_invoice',
        'invoice_path',
        'sync_status',
        'synced_at',
        'sync_retry_count',
        'sync_error_message',
    ];

    protected $casts = [
        'expense_date' => 'date',
        'has_invoice' => 'boolean',
        'synced_at' => 'datetime',
        'price_usd' => 'decimal:2',
        'price_syp' => 'decimal:2',
        'price_try' => 'decimal:2',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
```

### Option 2: Update Flutter App (NOT RECOMMENDED)

This would require changing the entire app structure to match your current backend. Not recommended because:
1. The app supports multiple currencies (USD, SYP, TRY)
2. Your backend only has single `amount` field
3. Would break existing app functionality

## Why This Happened

You have **two different backend implementations**:

1. **Postman Collection Backend** - Uses `amount`, `category`, `date`, `payment_method`
2. **App's Expected Backend** - Uses `price_usd`, `price_syp`, `price_try`, `expense_date`

The app was built for a specific Laravel backend structure, but your current backend has different fields.

## Recommended Action

**Update your Laravel backend** to match what the app expects (Option 1 above).

### Steps:

1. **Create new migration**:
```bash
php artisan make:migration update_expenses_table_for_app
```

2. **Update migration** with the schema above

3. **Run migration**:
```bash
php artisan migrate
```

4. **Update ExpenseController** with the code above

5. **Update Expense model** with the fillable fields above

6. **Test in Postman**:
```json
POST http://localhost:8000/api/v1/expenses
Headers:
  Authorization: Bearer YOUR_TOKEN
  Content-Type: application/json

Body:
{
  "description": "Test expense",
  "price_usd": 100.50,
  "expense_date": "2024-10-23",
  "has_invoice": false
}
```

7. **Test in app** - Should work now!

## Quick Test

After updating backend, test with curl:

```bash
curl -X POST http://192.168.137.1:8000/api/v1/expenses \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "description": "Test from curl",
    "price_usd": 50.00,
    "expense_date": "2024-10-23",
    "has_invoice": false
  }'
```

Should return:
```json
{
  "success": true,
  "message": "Expense created successfully",
  "data": {
    "id": 2,
    "user_id": 11,
    "description": "Test from curl",
    "price_usd": "50.00",
    ...
  }
}
```

## Summary

**Root Cause**: Field name mismatch between app and backend
**Solution**: Update Laravel backend to accept app's field names
**Why 401**: Backend validation failing, misreported as 401

After updating the backend, both create and fetch will work!
