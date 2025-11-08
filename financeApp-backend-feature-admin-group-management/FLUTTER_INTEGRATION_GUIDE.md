# Flutter Integration Guide - Organizations API

## Quick Reference

Your backend now has **3 organizations** ready for integration.

---

## Organizations Available

| ID | Arabic Name | English Name |
|----|-------------|--------------|
| 1  | هيئة الاتصالات | Communications Authority |
| 4  | الديوان العام | General Diwan |
| 5  | هيئة الطيران | Aviation Authority |

Each organization has **6 departments**:
- إدارة المعلوماتية (IT)
- إدارة الموارد البشرية (HR)
- إدارة المالية (Finance)
- إدارة الإشارة (Signal)
- إدارة الشبكات (Networks)
- إدارة الحرب الالكترونية (Cyber Warfare)

---

## API Endpoints

### Base URL
```dart
static const String baseUrl = 'http://192.168.137.1:8000/api/v1';
```

### 1. Get Organizations (No Auth Required)
```dart
GET $baseUrl/organizations
```

**Response:**
```json
{
  "success": true,
  "data": [
    {"id": 1, "name": "هيئة الاتصالات"},
    {"id": 4, "name": "الديوان العام"},
    {"id": 5, "name": "هيئة الطيران"}
  ]
}
```

### 2. Get Departments (No Auth Required)
```dart
GET $baseUrl/organizations/{organizationId}/departments
```

**Example Response for Organization 1:**
```json
{
  "success": true,
  "data": [
    {"id": 1, "organization_id": 1, "name": "إدارة المعلوماتية"},
    {"id": 7, "organization_id": 1, "name": "إدارة الموارد البشرية"},
    {"id": 8, "organization_id": 1, "name": "إدارة المالية"},
    {"id": 9, "organization_id": 1, "name": "إدارة الإشارة"},
    {"id": 10, "organization_id": 1, "name": "إدارة الشبكات"},
    {"id": 11, "organization_id": 1, "name": "إدارة الحرب الالكترونية"}
  ]
}
```

---

## Flutter Implementation

### Step 1: Fetch Organizations on Screen Load

```dart
Future<List<Organization>> fetchOrganizations() async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/organizations'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        return (data['data'] as List)
            .map((org) => Organization.fromJson(org))
            .toList();
      }
    }
    throw Exception('Failed to load organizations');
  } catch (e) {
    print('Error fetching organizations: $e');
    rethrow;
  }
}
```

### Step 2: Fetch Departments When Organization Selected

```dart
Future<List<Department>> fetchDepartments(int organizationId) async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/organizations/$organizationId/departments'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        return (data['data'] as List)
            .map((dept) => Department.fromJson(dept))
            .toList();
      }
    }
    throw Exception('Failed to load departments');
  } catch (e) {
    print('Error fetching departments: $e');
    rethrow;
  }
}
```

### Step 3: Register User with Organization and Department

```dart
Future<Map<String, dynamic>> register({
  required String name,
  required String email,
  required String password,
  required int organizationId,
  required int departmentId,
  String role = 'user',
}) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: json.encode({
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': password,
        'organization_id': organizationId,
        'department_id': departmentId,
        'role': role,
      }),
    );

    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Registration failed');
    }
  } catch (e) {
    print('Error during registration: $e');
    rethrow;
  }
}
```

---

## Model Classes

### Organization Model
```dart
class Organization {
  final int id;
  final String name;

  Organization({
    required this.id,
    required this.name,
  });

  factory Organization.fromJson(Map<String, dynamic> json) {
    return Organization(
      id: json['id'],
      name: json['name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}
```

### Department Model
```dart
class Department {
  final int id;
  final int organizationId;
  final String name;

  Department({
    required this.id,
    required this.organizationId,
    required this.name,
  });

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: json['id'],
      organizationId: json['organization_id'],
      name: json['name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'organization_id': organizationId,
      'name': name,
    };
  }
}
```

---

## UI Implementation Example

### Registration Screen with Dropdowns

```dart
class RegistrationScreen extends StatefulWidget {
  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  List<Organization> organizations = [];
  List<Department> departments = [];
  
  Organization? selectedOrganization;
  Department? selectedDepartment;
  
  bool isLoadingOrganizations = true;
  bool isLoadingDepartments = false;

  @override
  void initState() {
    super.initState();
    loadOrganizations();
  }

  Future<void> loadOrganizations() async {
    setState(() => isLoadingOrganizations = true);
    try {
      final orgs = await fetchOrganizations();
      setState(() {
        organizations = orgs;
        isLoadingOrganizations = false;
      });
    } catch (e) {
      setState(() => isLoadingOrganizations = false);
      // Show error message
    }
  }

  Future<void> loadDepartments(int organizationId) async {
    setState(() {
      isLoadingDepartments = true;
      departments = [];
      selectedDepartment = null;
    });
    
    try {
      final depts = await fetchDepartments(organizationId);
      setState(() {
        departments = depts;
        isLoadingDepartments = false;
      });
    } catch (e) {
      setState(() => isLoadingDepartments = false);
      // Show error message
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Form(
        child: Column(
          children: [
            // Organization Dropdown
            DropdownButtonFormField<Organization>(
              value: selectedOrganization,
              decoration: InputDecoration(labelText: 'المنظمة'),
              items: organizations.map((org) {
                return DropdownMenuItem(
                  value: org,
                  child: Text(org.name),
                );
              }).toList(),
              onChanged: (org) {
                setState(() => selectedOrganization = org);
                if (org != null) {
                  loadDepartments(org.id);
                }
              },
            ),
            
            // Department Dropdown
            if (selectedOrganization != null)
              DropdownButtonFormField<Department>(
                value: selectedDepartment,
                decoration: InputDecoration(labelText: 'القسم'),
                items: departments.map((dept) {
                  return DropdownMenuItem(
                    value: dept,
                    child: Text(dept.name),
                  );
                }).toList(),
                onChanged: (dept) {
                  setState(() => selectedDepartment = dept);
                },
              ),
            
            // Other form fields...
            
            // Register Button
            ElevatedButton(
              onPressed: () async {
                if (selectedOrganization != null && 
                    selectedDepartment != null) {
                  await register(
                    name: nameController.text,
                    email: emailController.text,
                    password: passwordController.text,
                    organizationId: selectedOrganization!.id,
                    departmentId: selectedDepartment!.id,
                  );
                }
              },
              child: Text('تسجيل'),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## Error Handling

### Common Errors and Solutions

#### 1. Network Error
```dart
catch (e) {
  if (e is SocketException) {
    // No internet connection
    showError('لا يوجد اتصال بالإنترنت');
  }
}
```

#### 2. Server Error
```dart
if (response.statusCode == 500) {
  showError('خطأ في الخادم');
}
```

#### 3. Validation Error
```dart
if (response.statusCode == 422) {
  final errors = json.decode(response.body)['errors'];
  // Show validation errors
}
```

---

## Testing

### Test in Browser First
1. Open: http://192.168.137.1:8000/api/v1/organizations
2. Should see JSON with 3 organizations
3. Open: http://192.168.137.1:8000/api/v1/organizations/1/departments
4. Should see JSON with 6 departments

### Test in Flutter
1. Run app on device/emulator
2. Navigate to registration screen
3. Organizations dropdown should populate
4. Select organization
5. Departments dropdown should populate
6. Complete registration

---

## Troubleshooting

### Organizations Not Loading
- Check base URL is correct
- Verify server is running: `php artisan serve --host=0.0.0.0 --port=8000`
- Test URL in browser first
- Check device can reach server IP

### Departments Not Loading
- Verify organization ID is valid
- Check API response in logs
- Ensure organization has departments

### Registration Failing
- Check all required fields are provided
- Verify organization_id and department_id are valid
- Check error response for details

---

## Support Files

- [ORGANIZATIONS_COMPLETE_LIST.md](ORGANIZATIONS_COMPLETE_LIST.md) - Complete list of orgs
- [TEST_ORGANIZATIONS_API.md](TEST_ORGANIZATIONS_API.md) - API testing guide
- [ORGANIZATIONS_API_VERIFICATION.md](ORGANIZATIONS_API_VERIFICATION.md) - Verification report

---

**Status**: ✅ Ready for Integration

**Last Updated**: October 29, 2024
