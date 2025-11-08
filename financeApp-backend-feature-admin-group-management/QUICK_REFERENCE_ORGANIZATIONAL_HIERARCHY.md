# Quick Reference - Organizational Hierarchy System

## API Endpoints

### Get Organizations (Public)
```
GET /api/v1/organizations
```

### Get Departments (Public)
```
GET /api/v1/organizations/{id}/departments
```

## Registration Examples

### Regular User
```json
POST /api/v1/auth/register
{
  "name": "User Name",
  "email": "user@example.com",
  "password": "password123",
  "password_confirmation": "password123",
  "organization_id": 1,
  "department_id": 2,
  "role": "user"
}
```

### Admin User
```json
POST /api/v1/auth/register
{
  "name": "Admin Name",
  "email": "admin@example.com",
  "password": "password123",
  "password_confirmation": "password123",
  "organization_id": 1,
  "role": "admin"
}
```

## Data Access Rules

| User Type | Can See |
|-----------|---------|
| Admin | All data from their organization |
| Regular User | Only their own data |

## Validation Rules

| Field | Regular User | Admin User |
|-------|-------------|------------|
| organization_id | Required | Required |
| department_id | Required | Optional |

## Error Messages

| Error | Message (Arabic) |
|-------|-----------------|
| Invalid organization | المنظمة المحددة غير موجودة |
| Invalid department | القسم المحدد غير موجود |
| Department mismatch | القسم لا ينتمي للمنظمة المحددة |
| Missing department | القسم مطلوب للمستخدمين العاديين |

## Default Data

**Organization:** هيئة الاتصالات (ID: 1)

**Departments:**
1. إدارة الإشارة
2. إدارة المعلوماتية
3. إدارة الشبكات
4. إدارة الحرب الالكترونية

## Adding New Organizations

```php
use App\Models\Organization;
use App\Models\Department;

// Create organization
$org = Organization::create(['name' => 'New Organization']);

// Create departments
Department::create([
    'organization_id' => $org->id,
    'name' => 'Department Name'
]);
```

## Model Usage

```php
// Get user's organization
$user->organization;

// Get user's department
$user->department;

// Get organization's departments
$organization->departments;

// Get department's users
$department->users;
```

## Automatic Behavior

When creating financial records:
- `organization_id` is automatically set from user
- `department_id` is automatically set from user
- Users cannot override these values

When querying data:
- Admins: Filtered by `organization_id`
- Regular users: Filtered by `user_id`
