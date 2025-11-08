# SuperAdmin Expense Endpoint 404 Fix

## Issue

The SuperAdmin flavor is getting a 404 error when trying to fetch expense summaries:

```
[SuperAdminExpenseApiDataSource] ❌ Failed with status 404
[SuperAdminExpenseApiDataSource] ❌ ApiException: Failed to fetch expense summary
```

## Root Cause

The backend has not yet implemented the SuperAdmin expense endpoints:
- `/api/v1/superadmin/expenses/summary` - Returns 404
- `/api/v1/superadmin/expenses/by-group/{id}` - Returns 404

## Backend Requirements

The backend team needs to implement these endpoints as documented in:
`.kiro/specs/superadmin-flavor-customization/API_DOCUMENTATION.md`

### Required Endpoints

#### 1. GET /api/v1/superadmin/expenses/summary

Returns aggregated expense summaries for all admin groups under SuperAdmin supervision.

**Response:**
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

#### 2. GET /api/v1/superadmin/expenses/by-group/{admin_group_id}

Returns detailed expenses for a specific admin group.

**Response:**
```json
{
  "success": true,
  "data": {
    "admin_group": {
      "id": 123,
      "name": "Sales Department"
    },
    "expenses": [...],
    "pagination": {...}
  }
}
```

## Temporary Frontend Fix

Until the backend implements these endpoints, we've updated the frontend to:

1. **Handle 404 gracefully** - Show empty state instead of error
2. **Log clear messages** - Help identify the missing endpoint
3. **Provide fallback UI** - Display helpful message to users

### Changes Made

**File:** `lib/features/expenses/data/datasources/superadmin_expense_api_datasource.dart`

- Added 404 detection and graceful handling
- Return empty data structure when endpoint is not found
- Added clear logging for debugging

**File:** `lib/ui/superadmin_expenses_page.dart`

- Display informative message when no data is available
- Show "Backend endpoint not implemented" message for 404 errors

## Testing

Once the backend implements the endpoints, test with:

1. **SuperAdmin Login**
   ```
   Email: superadmin@gmail.com
   Password: [your password]
   ```

2. **Navigate to Expenses Tab**
   - Should show expense summaries by admin group
   - Should allow drilling down into specific group expenses

3. **Verify Data**
   - Check that summaries aggregate correctly
   - Verify pagination works for detailed expenses
   - Confirm filters work (status, date range)

## Backend Implementation Notes

### Database Queries

The backend should:

1. **Get SuperAdmin's admin_group_id** from authenticated user
2. **Find all admin users** in that admin_group
3. **Aggregate expenses** created by those admin users
4. **Group by admin user** (or by department if available)
5. **Calculate totals** and counts per group

### SQL Example

```sql
-- Get expense summaries for SuperAdmin's group
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

### Authorization

Ensure the endpoint:
- Verifies user has `role = 'superAdmin'`
- Only returns data for the SuperAdmin's own admin_group
- Returns 403 if user tries to access other groups

## Next Steps

1. ✅ Frontend updated to handle 404 gracefully
2. ⏳ Backend team implements the endpoints
3. ⏳ Test with real data
4. ⏳ Remove temporary fallback UI

## Related Files

- `.kiro/specs/superadmin-flavor-customization/API_DOCUMENTATION.md` - Full API spec
- `lib/features/expenses/data/datasources/superadmin_expense_api_datasource.dart` - Frontend datasource
- `lib/ui/superadmin_expenses_page.dart` - SuperAdmin expenses UI
- `lib/features/expenses/data/models/superadmin_expense_view_dto.dart` - Data models

## Contact

If you have questions about the API requirements, refer to the API documentation or contact the frontend team.
