# Backend SuperAdmin Endpoints - Implementation Required

## Status: ⚠️ ENDPOINTS NOT IMPLEMENTED

The SuperAdmin flavor is currently getting 404 errors because these endpoints are missing from the backend.

## Required Endpoints

### 1. GET /api/v1/superadmin/expenses/summary

**Purpose:** Get aggregated expense summaries for all admin groups under SuperAdmin supervision.

**Authorization:** Requires SuperAdmin role

**Query Parameters:**
- `admin_group_id` (optional): Filter by specific admin group

**Response Example:**
```json
{
  "success": true,
  "data": {
    "summaries": [
      {
        "admin_group_id": 123,
        "admin_group_name": "Sales Department",
        "total_amount": 15000.00,
        "expense_count": 45,
        "pending_count": 5,
        "approved_count": 38,
        "rejected_count": 2,
        "currency": "USD",
        "last_expense_date": "2024-01-15T14:00:00Z"
      }
    ],
    "grand_total": 37000.00,
    "total_expense_count": 112
  }
}
```

**Implementation Logic:**
1. Get authenticated SuperAdmin's `admin_group_id`
2. Find all admin users in that admin_group
3. Aggregate expenses created by those admins
4. Group by admin user (or department)
5. Calculate totals and counts

**SQL Example:**
```sql
SELECT 
    u.id as admin_user_id,
    u.name as admin_name,
    COUNT(e.id) as expense_count,
    SUM(e.amount) as total_amount,
    SUM(CASE WHEN e.status = 'pending' THEN 1 ELSE 0 END) as pending_count,
    SUM(CASE WHEN e.status = 'approved' THEN 1 ELSE 0 END) as approved_count,
    SUM(CASE WHEN e.status = 'rejected' THEN 1 ELSE 0 END) as rejected_count,
    MAX(e.created_at) as last_expense_date
FROM users u
LEFT JOIN expenses e ON e.user_id = u.id
WHERE u.admin_group_id = ? -- SuperAdmin's admin_group_id
  AND u.role = 'admin'
GROUP BY u.id, u.name
ORDER BY u.name;
```

---

### 2. GET /api/v1/superadmin/expenses/by-group/{admin_group_id}

**Purpose:** Get detailed expenses for a specific admin group.

**Authorization:** Requires SuperAdmin role + verify group belongs to SuperAdmin

**Path Parameters:**
- `admin_group_id`: The admin group ID

**Query Parameters:**
- `page` (default: 1): Page number
- `per_page` (default: 50, max: 100): Items per page
- `status` (default: all): Filter by status (all, pending, approved, rejected)
- `date_from` (optional): Filter from date (YYYY-MM-DD)
- `date_to` (optional): Filter to date (YYYY-MM-DD)

**Response Example:**
```json
{
  "success": true,
  "data": {
    "admin_group": {
      "id": 123,
      "name": "Sales Department"
    },
    "expenses": [
      {
        "id": 501,
        "description": "Office supplies",
        "amount": 250.00,
        "currency": "USD",
        "category": "Supplies",
        "status": "approved",
        "created_by": {
          "id": 10,
          "name": "Admin User",
          "email": "admin@example.com"
        },
        "created_at": "2024-01-15T10:00:00Z",
        "approved_at": "2024-01-15T11:00:00Z",
        "photo_url": "https://example.com/photos/expense_501.jpg"
      }
    ],
    "pagination": {
      "current_page": 1,
      "per_page": 50,
      "total": 45,
      "last_page": 1
    }
  }
}
```

**Error Response (403 Forbidden):**
```json
{
  "success": false,
  "message": "You do not have permission to view this admin group's expenses",
  "error_code": "FORBIDDEN"
}
```

**Implementation Logic:**
1. Verify authenticated user is SuperAdmin
2. Verify the admin_group belongs to the SuperAdmin
3. Query expenses for users in that admin_group
4. Apply filters (status, date range)
5. Return paginated results

---

## Authorization Requirements

Both endpoints must:
1. ✅ Verify JWT token is valid
2. ✅ Verify user has `role = 'superAdmin'`
3. ✅ Verify data belongs to the SuperAdmin's admin_group
4. ❌ Return 403 if user tries to access other groups

## Data Scoping

SuperAdmin can only see:
- Expenses from admin users in their own admin_group
- NOT expenses from other SuperAdmin groups
- NOT expenses from regular users

## Testing

### Test User
```
Email: superadmin@gmail.com
Role: superAdmin
Admin Group ID: [check database]
```

### Test Requests

**1. Get Summary:**
```bash
curl -X GET \
  http://192.168.137.1:8000/api/v1/superadmin/expenses/summary \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Accept: application/json"
```

**2. Get Group Expenses:**
```bash
curl -X GET \
  "http://192.168.137.1:8000/api/v1/superadmin/expenses/by-group/123?page=1&per_page=50" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Accept: application/json"
```

## Frontend Changes

The frontend has been updated to:
- ✅ Handle 404 gracefully (return empty data)
- ✅ Show informative message when endpoints are missing
- ✅ Log clear debugging information
- ✅ Provide fallback UI

## Complete API Documentation

See: `.kiro/specs/superadmin-flavor-customization/API_DOCUMENTATION.md`

This file contains the complete API specification including:
- All SuperAdmin endpoints
- Request/response formats
- Error codes
- Authorization requirements
- Rate limiting
- Security considerations

## Priority

🔴 **HIGH PRIORITY** - SuperAdmin flavor is non-functional without these endpoints

## Questions?

Contact the frontend team or refer to:
- `SUPERADMIN_EXPENSE_ENDPOINT_FIX.md` - Detailed fix documentation
- `.kiro/specs/superadmin-flavor-customization/API_DOCUMENTATION.md` - Complete API spec
- `lib/features/expenses/data/datasources/superadmin_expense_api_datasource.dart` - Frontend implementation
