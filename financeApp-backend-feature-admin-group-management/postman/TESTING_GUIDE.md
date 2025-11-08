# Complete Postman Testing Guide

## Quick Start

### 1. Import Collection & Environment

**Import the Collection:**
1. Open Postman
2. Click "Import" button
3. Select `Finance-API.postman_collection.json`
4. Click "Import"

**Import Environment:**
1. Click "Import" again
2. Select `Finance-API-Local.postman_environment.json`
3. Click "Import"
4. Select "Finance API - Local" from environment dropdown (top right)

### 2. Start Your Server
```bash
php artisan serve
```
Server should be running at: http://localhost:8000

---

## Testing Workflow

### Step 1: Authentication Flow

#### A. Register New User
**Endpoint:** `POST /register`

**Request Body:**
```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "password": "password123",
  "password_confirmation": "password123"
}
```

**Expected Response (201):**
```json
{
  "success": true,
  "message": "User registered successfully",
  "data": {
    "user": {
      "id": 1,
      "name": "John Doe",
      "email": "john@example.com",
      "role": "user"
    },
    "token": "1|abc123..."
  }
}
```

✅ **Auto-saves token** to collection variables

---

#### B. Login
**Endpoint:** `POST /login`

**Request Body:**
```json
{
  "email": "john@example.com",
  "password": "password123"
}
```

**Expected Response (200):**
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "user": {...},
    "token": "2|xyz789..."
  }
}
```

✅ **Auto-saves token** to collection variables

---

#### C. Get Current User
**Endpoint:** `GET /user`

**Headers:** 
- Authorization: Bearer {{auth_token}} (auto-added)

**Expected Response (200):**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "name": "John Doe",
    "email": "john@example.com",
    "role": "user"
  }
}
```

---

### Step 2: Expense Management

#### A. Create Expense
**Endpoint:** `POST /expenses`

**Request Body:**
```json
{
  "amount": 150.50,
  "category": "Food",
  "description": "Grocery shopping",
  "date": "2024-10-23",
  "payment_method": "cash"
}
```

**Expected Response (201):**
```json
{
  "success": true,
  "message": "Expense created successfully",
  "data": {
    "id": 1,
    "amount": 150.50,
    "category": "Food",
    "description": "Grocery shopping",
    "date": "2024-10-23",
    "payment_method": "cash",
    "user_id": 1
  }
}
```

✅ **Auto-saves expense_id** to collection variables

---

#### B. List All Expenses
**Endpoint:** `GET /expenses`

**Query Parameters (optional):**
- `category`: Filter by category
- `date_from`: Start date (YYYY-MM-DD)
- `date_to`: End date (YYYY-MM-DD)
- `payment_method`: Filter by payment method
- `per_page`: Items per page (default: 15)

**Example:** `GET /expenses?category=Food&per_page=20`

**Expected Response (200):**
```json
{
  "success": true,
  "data": {
    "data": [
      {
        "id": 1,
        "amount": 150.50,
        "category": "Food",
        "description": "Grocery shopping",
        "date": "2024-10-23"
      }
    ],
    "current_page": 1,
    "total": 1,
    "per_page": 15
  }
}
```

---

#### C. Get Single Expense
**Endpoint:** `GET /expenses/{{expense_id}}`

**Expected Response (200):**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "amount": 150.50,
    "category": "Food",
    "description": "Grocery shopping",
    "date": "2024-10-23",
    "payment_method": "cash",
    "receipt_path": null,
    "user_id": 1,
    "created_at": "2024-10-23T10:00:00.000000Z"
  }
}
```

---

#### D. Update Expense
**Endpoint:** `PUT /expenses/{{expense_id}}`

**Request Body:**
```json
{
  "amount": 175.00,
  "category": "Food",
  "description": "Grocery shopping - Updated",
  "date": "2024-10-23",
  "payment_method": "card"
}
```

**Expected Response (200):**
```json
{
  "success": true,
  "message": "Expense updated successfully",
  "data": {
    "id": 1,
    "amount": 175.00,
    "description": "Grocery shopping - Updated",
    "payment_method": "card"
  }
}
```

---

#### E. Delete Expense
**Endpoint:** `DELETE /expenses/{{expense_id}}`

**Expected Response (200):**
```json
{
  "success": true,
  "message": "Expense deleted successfully"
}
```

---

### Step 3: Income/Incoming Management

#### A. Create Income
**Endpoint:** `POST /incoming`

**Request Body:**
```json
{
  "amount": 5000.00,
  "source": "Salary",
  "description": "Monthly salary",
  "date": "2024-10-23",
  "payment_method": "bank_transfer"
}
```

**Expected Response (201):**
```json
{
  "success": true,
  "message": "Income created successfully",
  "data": {
    "id": 1,
    "amount": 5000.00,
    "source": "Salary",
    "description": "Monthly salary",
    "date": "2024-10-23"
  }
}
```

✅ **Auto-saves incoming_id** to collection variables

---

#### B. List All Income
**Endpoint:** `GET /incoming`

**Query Parameters (optional):**
- `source`: Filter by source
- `date_from`: Start date
- `date_to`: End date
- `per_page`: Items per page

---

#### C. Update Income
**Endpoint:** `PUT /incoming/{{incoming_id}}`

---

#### D. Delete Income
**Endpoint:** `DELETE /incoming/{{incoming_id}}`

---

### Step 4: Transfer Management

#### A. Create Transfer
**Endpoint:** `POST /transfers`

**Request Body:**
```json
{
  "amount": 500.00,
  "from_account": "Savings",
  "to_account": "Checking",
  "description": "Monthly transfer",
  "date": "2024-10-23"
}
```

**Expected Response (201):**
```json
{
  "success": true,
  "message": "Transfer created successfully",
  "data": {
    "id": 1,
    "amount": 500.00,
    "from_account": "Savings",
    "to_account": "Checking",
    "description": "Monthly transfer"
  }
}
```

✅ **Auto-saves transfer_id** to collection variables

---

#### B. List All Transfers
**Endpoint:** `GET /transfers`

---

#### C. Update Transfer
**Endpoint:** `PUT /transfers/{{transfer_id}}`

---

#### D. Delete Transfer
**Endpoint:** `DELETE /transfers/{{transfer_id}}`

---

### Step 5: Fund Box (Balance Tracking)

#### A. Get Fund Box
**Endpoint:** `GET /fund-box`

**Expected Response (200):**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "total_balance": 4324.50,
    "total_income": 5000.00,
    "total_expenses": 175.50,
    "total_transfers": 500.00,
    "last_updated": "2024-10-23T10:00:00.000000Z"
  }
}
```

---

#### B. Recalculate Fund Box
**Endpoint:** `POST /fund-box/recalculate`

**Expected Response (200):**
```json
{
  "success": true,
  "message": "Fund box recalculated successfully",
  "data": {
    "total_balance": 4324.50,
    "total_income": 5000.00,
    "total_expenses": 175.50
  }
}
```

---

### Step 6: File Management

#### A. Upload File
**Endpoint:** `POST /files/upload`

**Request Body (form-data):**
- `file`: [Select file]
- `type`: "receipt" or "document"
- `related_id`: 1 (optional - expense/income ID)
- `related_type`: "expense" (optional)

**Expected Response (201):**
```json
{
  "success": true,
  "message": "File uploaded successfully",
  "data": {
    "id": 1,
    "filename": "receipt_123.jpg",
    "path": "/storage/files/receipt_123.jpg",
    "size": 102400,
    "mime_type": "image/jpeg"
  }
}
```

---

#### B. Download File
**Endpoint:** `GET /files/{{file_id}}/download`

**Response:** File download

---

#### C. Delete File
**Endpoint:** `DELETE /files/{{file_id}}`

---

### Step 7: Export Data

#### A. Export Expenses (PDF)
**Endpoint:** `POST /exports/expenses`

**Request Body:**
```json
{
  "format": "pdf",
  "date_from": "2024-10-01",
  "date_to": "2024-10-31",
  "category": "Food"
}
```

**Expected Response (200):**
```json
{
  "success": true,
  "message": "Export created successfully",
  "data": {
    "id": 1,
    "format": "pdf",
    "status": "completed",
    "download_url": "/api/v1/exports/1/download"
  }
}
```

✅ **Auto-saves export_id** to collection variables

---

#### B. Export Expenses (Excel)
**Endpoint:** `POST /exports/expenses`

**Request Body:**
```json
{
  "format": "excel",
  "date_from": "2024-10-01",
  "date_to": "2024-10-31"
}
```

---

#### C. Download Export
**Endpoint:** `GET /exports/{{export_id}}/download`

**Response:** File download (PDF or Excel)

---

### Step 8: User Profile

#### A. Get Profile
**Endpoint:** `GET /profile`

**Expected Response (200):**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "name": "John Doe",
    "email": "john@example.com",
    "role": "user",
    "statistics": {
      "total_expenses": 175.50,
      "total_income": 5000.00,
      "expense_count": 1,
      "income_count": 1
    }
  }
}
```

---

#### B. Update Profile
**Endpoint:** `PUT /profile`

**Request Body:**
```json
{
  "name": "John Smith",
  "email": "john.smith@example.com"
}
```

---

#### C. Change Password
**Endpoint:** `POST /profile/change-password`

**Request Body:**
```json
{
  "current_password": "password123",
  "new_password": "newpassword123",
  "new_password_confirmation": "newpassword123"
}
```

---

### Step 9: Admin Features (Admin users only)

#### A. Admin Dashboard
**Endpoint:** `GET /admin/dashboard`

**Expected Response (200):**
```json
{
  "success": true,
  "data": {
    "total_users": 10,
    "total_expenses": 15000.00,
    "total_income": 50000.00,
    "recent_activities": [...]
  }
}
```

---

#### B. Get All Users (Admin)
**Endpoint:** `GET /admin/users`

---

### Step 10: Audit Logs

#### A. Get Audit Logs
**Endpoint:** `GET /audit-logs`

**Query Parameters:**
- `action`: Filter by action (created, updated, deleted)
- `model`: Filter by model (Expense, Incoming, Transfer)
- `date_from`: Start date
- `date_to`: End date

**Expected Response (200):**
```json
{
  "success": true,
  "data": {
    "data": [
      {
        "id": 1,
        "user_id": 1,
        "action": "created",
        "model": "Expense",
        "model_id": 1,
        "changes": {...},
        "created_at": "2024-10-23T10:00:00.000000Z"
      }
    ]
  }
}
```

---

### Step 11: Data Synchronization

#### A. Sync Data
**Endpoint:** `POST /sync`

**Request Body:**
```json
{
  "last_sync": "2024-10-23T09:00:00.000000Z",
  "data": {
    "expenses": [...],
    "incoming": [...],
    "transfers": [...]
  }
}
```

---

#### B. Get Sync Status
**Endpoint:** `GET /sync/status`

---

## Testing Tips

### 1. Collection Variables
The collection automatically saves important IDs:
- `auth_token` - Authentication token
- `expense_id` - Last created expense ID
- `transfer_id` - Last created transfer ID
- `incoming_id` - Last created income ID
- `export_id` - Last created export ID

### 2. Test Scripts
Each request has test scripts that:
- Validate response status codes
- Save IDs to variables
- Check response structure

### 3. Environment Variables
Switch between environments:
- **Local**: http://localhost:8000/api/v1
- **Production**: Your production URL

### 4. Bulk Testing
Use Postman's Collection Runner:
1. Click "..." on collection
2. Select "Run collection"
3. Choose requests to run
4. Click "Run Finance Backend API"

### 5. Error Testing
Try these scenarios:
- Invalid credentials
- Missing required fields
- Unauthorized access
- Invalid IDs
- Duplicate entries

---

## Common Response Codes

- **200 OK** - Successful GET/PUT/DELETE
- **201 Created** - Successful POST
- **400 Bad Request** - Validation error
- **401 Unauthorized** - Missing/invalid token
- **403 Forbidden** - Insufficient permissions
- **404 Not Found** - Resource not found
- **422 Unprocessable Entity** - Validation failed
- **500 Internal Server Error** - Server error

---

## Validation Error Example

**Response (422):**
```json
{
  "success": false,
  "message": "Validation failed",
  "errors": {
    "amount": ["The amount field is required."],
    "category": ["The category field is required."]
  }
}
```

---

## Authentication Error Example

**Response (401):**
```json
{
  "success": false,
  "message": "Unauthenticated"
}
```

---

## Next Steps

1. ✅ Import collection and environment
2. ✅ Start your server (`php artisan serve`)
3. ✅ Register a new user
4. ✅ Create some expenses
5. ✅ Test all CRUD operations
6. ✅ Try export features
7. ✅ Test file uploads
8. ✅ Check audit logs

Happy Testing! 🚀
