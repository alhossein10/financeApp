# Admin Group Management Flow

## Registration & Login Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    NEW ADMIN REGISTRATION                    │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
                    ┌──────────────────┐
                    │  Register Page   │
                    │  - Email         │
                    │  - Password      │
                    │  - Role: Admin   │
                    │  - Organization  │
                    │  - Department    │
                    └──────────────────┘
                              │
                              ▼
                    ┌──────────────────┐
                    │  Backend API     │
                    │  Creates:        │
                    │  - User account  │
                    │  - Admin group   │
                    │  - Group code    │
                    └──────────────────┘
                              │
                              ▼
                    ┌──────────────────┐
                    │  Success Dialog  │
                    │  Shows:          │
                    │  - Group code    │
                    │  - Instructions  │
                    └──────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                         FIRST LOGIN                          │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
                    ┌──────────────────┐
                    │  Login Process   │
                    │  1. Clear cache  │◄── FIX: Prevents wrong group
                    │  2. Authenticate │
                    │  3. Fetch user   │
                    │  4. Cache user   │
                    └──────────────────┘
                              │
                              ▼
                    ┌──────────────────┐
                    │  Main App        │
                    │  Detects:        │
                    │  - User role     │◄── FIX: Immediate role detection
                    │  - Is admin?     │
                    └──────────────────┘
                              │
                              ▼
                    ┌──────────────────┐
                    │  Home Scaffold   │
                    │  Shows:          │◄── FIX: Correct tabs immediately
                    │  - Dashboard     │
                    │  - Groups        │
                    │  - Cash          │
                    │  - Expenses      │
                    │  - Export        │
                    └──────────────────┘
```

## Group Management Flow

```
┌─────────────────────────────────────────────────────────────┐
│                   GROUP MANAGEMENT PAGE                      │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
                    ┌──────────────────┐
                    │  Page Init       │
                    │  1. Load group   │◄── FIX: Force fresh fetch
                    │  2. Load members │
                    └──────────────────┘
                              │
                              ▼
                    ┌──────────────────┐
                    │  API Call        │
                    │  GET /admin/     │
                    │      group       │
                    └──────────────────┘
                              │
                              ▼
                    ┌──────────────────┐
                    │  Response        │
                    │  {               │
                    │    data: {       │◄── FIX: Parse nested structure
                    │      group: {    │
                    │        id: 4     │
                    │        code: ... │
                    │      }           │
                    │    }             │
                    │  }               │
                    └──────────────────┘
                              │
                              ▼
                    ┌──────────────────┐
                    │  Display         │
                    │  - Group code    │◄── Shows CORRECT code
                    │  - Member count  │
                    │  - Member list   │
                    └──────────────────┘
```

## Regenerate Code Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    REGENERATE GROUP CODE                     │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
                    ┌──────────────────┐
                    │  User Action     │
                    │  1. Click button │
                    │  2. Confirm      │
                    └──────────────────┘
                              │
                              ▼
                    ┌──────────────────┐
                    │  API Call        │
                    │  POST /admin/    │
                    │  group/regenerate│
                    └──────────────────┘
                              │
                              ▼
                    ┌──────────────────┐
                    │  Backend         │
                    │  1. Generate new │
                    │     6-char code  │
                    │  2. Invalidate   │
                    │     old code     │
                    │  3. Update DB    │
                    └──────────────────┘
                              │
                              ▼
                    ┌──────────────────┐
                    │  Response        │
                    │  {               │
                    │    data: {       │◄── FIX: Parse nested structure
                    │      group: {    │
                    │        code:     │
                    │        "608251"  │
                    │      }           │
                    │    }             │
                    │  }               │
                    └──────────────────┘
                              │
                              ▼
                    ┌──────────────────┐
                    │  App Updates     │
                    │  1. Clear cache  │◄── FIX: Invalidate old cache
                    │  2. Update UI    │
                    │  3. Show success │
                    └──────────────────┘
                              │
                              ▼
                    ┌──────────────────┐
                    │  Display         │
                    │  - NEW code      │◄── Shows immediately
                    │  - Success msg   │
                    └──────────────────┘
```

## Cache Management Strategy

```
┌─────────────────────────────────────────────────────────────┐
│                      CACHE LIFECYCLE                         │
└─────────────────────────────────────────────────────────────┘

LOGIN
  │
  ├─► Clear admin group cache    ◄── FIX: Prevent cross-user data
  │
  └─► Authenticate & cache user

FETCH GROUP
  │
  ├─► Check cache (TTL: 5 min)
  │   │
  │   ├─► If valid: Return cached
  │   │
  │   └─► If expired/missing:
  │       │
  │       └─► Fetch from API
  │           │
  │           └─► Cache result

REGENERATE CODE
  │
  ├─► Call API
  │
  ├─► Invalidate cache           ◄── FIX: Force fresh fetch
  │
  └─► Cache new data

LOGOUT
  │
  ├─► Clear auth data
  │
  └─► Clear admin group cache    ◄── FIX: Clean state
```

## Data Scoping

```
┌─────────────────────────────────────────────────────────────┐
│                    ADMIN GROUP ISOLATION                     │
└─────────────────────────────────────────────────────────────┘

Admin 1                          Admin 2
  │                                │
  ├─► Group Code: ABC123          ├─► Group Code: XYZ789
  │                                │
  ├─► Members:                    ├─► Members:
  │   - User A                     │   - User X
  │   - User B                     │   - User Y
  │   - User C                     │   - User Z
  │                                │
  ├─► Expenses:                   ├─► Expenses:
  │   - Only from A, B, C         │   - Only from X, Y, Z
  │                                │
  └─► Transfers:                  └─► Transfers:
      - Only from A, B, C             - Only from X, Y, Z

      ▲                                ▲
      │                                │
      └────────────────────────────────┘
           Backend filters by
           admin_group_id from token
```

## Key Points

1. **Cache Clearing**: Happens on login/logout to prevent data leakage
2. **Role Detection**: Immediate after authentication
3. **API Structure**: Nested `data.group` properly parsed
4. **Data Isolation**: Each admin sees only their group's data
5. **Code Uniqueness**: Each admin group has a unique 6-character code

## Security Notes

- Group codes are unique per admin group
- Old codes are invalidated when regenerated
- Users can only join one group at a time
- Admins cannot join other groups
- Data is automatically scoped by admin_group_id in backend
