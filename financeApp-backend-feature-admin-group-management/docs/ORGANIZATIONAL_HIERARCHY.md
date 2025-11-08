# Organizational Hierarchy System Documentation

## Overview

The organizational hierarchy system enables multi-organization support with department-level granularity. This allows administrators to manage organization-wide data while regular users access only their department-specific data.

## Database Schema

### Organizations Table
- `id`: Primary key
- `name`: Organization name (Arabic)
- `created_at`, `updated_at`: Timestamps

### Departments Table
- `id`: Primary key
- `organization_id`: Foreign key to organizations
- `name`: Department name (Arabic)
- `created_at`, `updated_at`: Timestamps

### Users Table (Updated)
- `organization_id`: Required foreign key to organizations
- `department_id`: Nullable foreign key to departments (required for regular users, null for admins)

### Financial Tables (Updated)
All financial tables (expenses, transfers, incoming, fund_boxes) now include:
- `organization_id`: Required foreign key to organizations
- `department_id`: Nullable foreign key to departments

## API Endpoints

### Public Endpoints (No Authentication Required)

#### Get All Organizations
```
GET /api/v1/organizations
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "هيئة الاتصالات"
    }
  ]
}
```

#### Get Departments for an Organization
```
GET /api/v1/organizations/{id}/departments
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "organization_id": 1,
      "name": "إدارة الإشارة"
    },
    {
      "id": 2,
      "organization_id": 1,
      "name": "إدارة المعلوماتية"
    }
  ]
}
```

## User Registration

### Regular User Registration
```json
POST /api/v1/auth/register
{
  "name": "أحمد محمد",
  "email": "ahmad@example.com",
  "password": "password123",
  "password_confirmation": "password123",
  "organization_id": 1,
  "department_id": 3,
  "role": "user"
}
```

### Admin User Registration
```json
POST /api/v1/auth/register
{
  "name": "مدير النظام",
  "email": "admin@example.com",
  "password": "password123",
  "password_confirmation": "password123",
  "organization_id": 1,
  "role": "admin"
}
```

**Note:** Admin users don't require a `department_id`.

## Data Access Control

### Admin Users
- Can view all data from all departments within their organization
- Data is filtered by `organization_id` automatically
- Cannot see data from other organizations

### Regular Users
- Can only view data they created
- Data is filtered by `user_id` automatically
- Cannot see data from other users, even within the same department

## Data Creation

When users create financial records (expenses, transfers, incoming):
- `organization_id` is automatically set from the user's organization
- `department_id` is automatically set from the user's department
- Users cannot manually specify different organizational contexts

## Validation Rules

### Registration Validation
- `organization_id`: Required, must exist in organizations table
- `department_id`: 
  - Required for regular users (`role: user`)
  - Optional for admin users (`role: admin`)
  - Must belong to the specified organization

### Error Messages (Arabic)
- Invalid organization: "المنظمة المحددة غير موجودة"
- Invalid department: "القسم المحدد غير موجود"
- Department doesn't belong to organization: "القسم لا ينتمي للمنظمة المحددة"
- Department required for regular users: "القسم مطلوب للمستخدمين العاديين"

## Initial Data

### Default Organization
- Name: "هيئة الاتصالات"

### Default Departments
1. إدارة الإشارة
2. إدارة المعلوماتية
3. إدارة الشبكات
4. إدارة الحرب الالكترونية

## Migration Strategy

The system includes migrations to:
1. Create organizations and departments tables
2. Add organizational columns to users and financial tables
3. Migrate existing data to default organization and department
4. Add foreign key constraints

All existing users and data are automatically assigned to the default organization and department during migration.

## Adding New Organizations/Departments

### Via Seeder
```php
// Create organization
$org = Organization::create(['name' => 'New Organization']);

// Create department
Department::create([
    'organization_id' => $org->id,
    'name' => 'New Department'
]);
```

### Via Database
```sql
INSERT INTO organizations (name, created_at, updated_at) 
VALUES ('New Organization', NOW(), NOW());

INSERT INTO departments (organization_id, name, created_at, updated_at) 
VALUES (1, 'New Department', NOW(), NOW());
```

## Model Relationships

### User Model
```php
$user->organization; // BelongsTo Organization
$user->department;   // BelongsTo Department
```

### Organization Model
```php
$organization->departments; // HasMany Department
$organization->users;       // HasMany User
$organization->expenses;    // HasMany Expense
```

### Department Model
```php
$department->organization; // BelongsTo Organization
$department->users;        // HasMany User
$department->expenses;     // HasMany Expense
```

## Security Considerations

1. **Data Isolation**: Organizations are completely isolated from each other
2. **Automatic Filtering**: All queries automatically apply organizational filters
3. **Immutable Context**: Users cannot change their organizational context after creation
4. **Admin Scope**: Admin users can only access their own organization's data

## Performance

- Indexes are created on all organizational columns for optimal query performance
- The system is designed to handle up to 100 organizations and 1000 departments efficiently

## Testing

To test the organizational hierarchy:

1. Create organizations and departments using the seeder
2. Register users with different organizational contexts
3. Create financial records as different users
4. Verify that admins see organization-wide data
5. Verify that regular users see only their own data
