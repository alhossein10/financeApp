# Design Document - Organizational Hierarchy Frontend Implementation

## Overview

This document outlines the technical design for implementing organizational hierarchy support in the Flutter frontend application. The implementation will add organization and department selection to the registration flow, update the user model to include organizational context, and ensure proper data filtering based on user roles.

## Architecture

### Layer Structure

The implementation follows Clean Architecture principles with clear separation of concerns:

```
presentation/
├── pages/
│   └── register_page.dart (updated)
├── widgets/
│   ├── organization_dropdown.dart (new)
│   └── department_dropdown.dart (new)
└── bloc/
    └── auth_bloc.dart (updated)

domain/
├── entities/
│   ├── organization.dart (new)
│   ├── department.dart (new)
│   └── user.dart (updated)
└── usecases/
    ├── get_organizations_usecase.dart (new)
    ├── get_departments_usecase.dart (new)
    └── register_usecase.dart (updated)

data/
├── models/
│   ├── organization_model.dart (new)
│   ├── department_model.dart (new)
│   └── user_model.dart (updated)
├── datasources/
│   └── auth_api_datasource.dart (updated)
└── repositories/
    └── auth_repository_impl.dart (updated)
```

## Components and Interfaces

### 1. Domain Layer

#### Organization Entity
```dart
class Organization {
  final int id;
  final String name;

  Organization({
    required this.id,
    required this.name,
  });
}
```

#### Department Entity
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
}
```

#### Updated User Entity
```dart
class User {
  final int id;
  final String name;
  final String email;
  final String role;
  final int organizationId;        // New field
  final int? departmentId;         // New field (nullable for admins)
  final Organization? organization; // New field (optional)
  final Department? department;     // New field (optional)
  
  // ... existing fields
}
```

#### Use Cases

**GetOrganizationsUseCase**
```dart
class GetOrganizationsUseCase {
  final AuthRepository repository;

  Future<Either<Failure, List<Organization>>> call() async {
    return await repository.getOrganizations();
  }
}
```

**GetDepartmentsUseCase**
```dart
class GetDepartmentsUseCase {
  final AuthRepository repository;

  Future<Either<Failure, List<Department>>> call(int organizationId) async {
    return await repository.getDepartments(organizationId);
  }
}
```

### 2. Data Layer

#### API Datasource Updates

**AuthApiDataSource** - New Methods
```dart
abstract class AuthApiDataSource {
  // Existing methods...
  
  Future<List<OrganizationModel>> getOrganizations();
  Future<List<DepartmentModel>> getDepartments(int organizationId);
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    required int organizationId,
    int? departmentId,
    required String role,
  });
}
```

**Implementation**
```dart
class AuthApiDataSourceImpl implements AuthApiDataSource {
  final ApiClient apiClient;

  @override
  Future<List<OrganizationModel>> getOrganizations() async {
    final response = await apiClient.get('/organizations');
    final List<dynamic> data = response.data['data'];
    return data.map((json) => OrganizationModel.fromJson(json)).toList();
  }

  @override
  Future<List<DepartmentModel>> getDepartments(int organizationId) async {
    final response = await apiClient.get('/organizations/$organizationId/departments');
    final List<dynamic> data = response.data['data'];
    return data.map((json) => DepartmentModel.fromJson(json)).toList();
  }

  @override
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    required int organizationId,
    int? departmentId,
    required String role,
  }) async {
    final Map<String, dynamic> body = {
      'name': name,
      'email': email,
      'password': password,
      'password_confirmation': passwordConfirmation,
      'organization_id': organizationId,
      'role': role,
    };
    
    // Only include department_id for regular users
    if (departmentId != null) {
      body['department_id'] = departmentId;
    }

    final response = await apiClient.post('/auth/register', data: body);
    return UserModel.fromJson(response.data['data']['user']);
  }
}
```

#### Data Models

**OrganizationModel**
```dart
class OrganizationModel extends Organization {
  OrganizationModel({
    required int id,
    required String name,
  }) : super(id: id, name: name);

  factory OrganizationModel.fromJson(Map<String, dynamic> json) {
    return OrganizationModel(
      id: json['id'] as int,
      name: json['name'] as String,
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

**DepartmentModel**
```dart
class DepartmentModel extends Department {
  DepartmentModel({
    required int id,
    required int organizationId,
    required String name,
  }) : super(id: id, organizationId: organizationId, name: name);

  factory DepartmentModel.fromJson(Map<String, dynamic> json) {
    return DepartmentModel(
      id: json['id'] as int,
      organizationId: json['organization_id'] as int,
      name: json['name'] as String,
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

**Updated UserModel**
```dart
class UserModel extends User {
  UserModel({
    required int id,
    required String name,
    required String email,
    required String role,
    required int organizationId,
    int? departmentId,
    Organization? organization,
    Department? department,
    // ... existing fields
  }) : super(
    id: id,
    name: name,
    email: email,
    role: role,
    organizationId: organizationId,
    departmentId: departmentId,
    organization: organization,
    department: department,
    // ... existing fields
  );

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      organizationId: json['organization_id'] as int,
      departmentId: json['department_id'] as int?,
      organization: json['organization'] != null
          ? OrganizationModel.fromJson(json['organization'])
          : null,
      department: json['department'] != null
          ? DepartmentModel.fromJson(json['department'])
          : null,
      // ... existing fields
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'organization_id': organizationId,
      'department_id': departmentId,
      // ... existing fields
    };
  }
}
```

### 3. Presentation Layer

#### Auth BLoC Updates

**New Events**
```dart
class LoadOrganizationsEvent extends AuthEvent {}

class LoadDepartmentsEvent extends AuthEvent {
  final int organizationId;
  LoadDepartmentsEvent(this.organizationId);
}

class OrganizationSelectedEvent extends AuthEvent {
  final int organizationId;
  OrganizationSelectedEvent(this.organizationId);
}

class RegisterSubmittedEvent extends AuthEvent {
  final String name;
  final String email;
  final String password;
  final String passwordConfirmation;
  final int organizationId;
  final int? departmentId;
  final String role;
  
  RegisterSubmittedEvent({
    required this.name,
    required this.email,
    required this.password,
    required this.passwordConfirmation,
    required this.organizationId,
    this.departmentId,
    required this.role,
  });
}
```

**Updated State**
```dart
class AuthState extends Equatable {
  final AuthStatus status;
  final User? user;
  final String? errorMessage;
  final List<Organization> organizations;
  final List<Department> departments;
  final int? selectedOrganizationId;
  final bool isLoadingOrganizations;
  final bool isLoadingDepartments;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
    this.organizations = const [],
    this.departments = const [],
    this.selectedOrganizationId,
    this.isLoadingOrganizations = false,
    this.isLoadingDepartments = false,
  });

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? errorMessage,
    List<Organization>? organizations,
    List<Department>? departments,
    int? selectedOrganizationId,
    bool? isLoadingOrganizations,
    bool? isLoadingDepartments,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
      organizations: organizations ?? this.organizations,
      departments: departments ?? this.departments,
      selectedOrganizationId: selectedOrganizationId ?? this.selectedOrganizationId,
      isLoadingOrganizations: isLoadingOrganizations ?? this.isLoadingOrganizations,
      isLoadingDepartments: isLoadingDepartments ?? this.isLoadingDepartments,
    );
  }

  @override
  List<Object?> get props => [
    status,
    user,
    errorMessage,
    organizations,
    departments,
    selectedOrganizationId,
    isLoadingOrganizations,
    isLoadingDepartments,
  ];
}
```

#### UI Components

**OrganizationDropdown Widget**
```dart
class OrganizationDropdown extends StatelessWidget {
  final List<Organization> organizations;
  final int? selectedOrganizationId;
  final ValueChanged<int?> onChanged;
  final bool isLoading;
  final String? errorText;

  const OrganizationDropdown({
    Key? key,
    required this.organizations,
    this.selectedOrganizationId,
    required this.onChanged,
    this.isLoading = false,
    this.errorText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const CircularProgressIndicator();
    }

    return DropdownButtonFormField<int>(
      value: selectedOrganizationId,
      decoration: InputDecoration(
        labelText: 'المنظمة',
        errorText: errorText,
        border: OutlineInputBorder(),
      ),
      items: organizations.map((org) {
        return DropdownMenuItem<int>(
          value: org.id,
          child: Text(org.name),
        );
      }).toList(),
      onChanged: onChanged,
      validator: (value) {
        if (value == null) {
          return 'الرجاء اختيار المنظمة';
        }
        return null;
      },
    );
  }
}
```

**DepartmentDropdown Widget**
```dart
class DepartmentDropdown extends StatelessWidget {
  final List<Department> departments;
  final int? selectedDepartmentId;
  final ValueChanged<int?> onChanged;
  final bool isLoading;
  final bool isRequired;
  final String? errorText;

  const DepartmentDropdown({
    Key? key,
    required this.departments,
    this.selectedDepartmentId,
    required this.onChanged,
    this.isLoading = false,
    this.isRequired = true,
    this.errorText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const CircularProgressIndicator();
    }

    return DropdownButtonFormField<int>(
      value: selectedDepartmentId,
      decoration: InputDecoration(
        labelText: 'القسم',
        errorText: errorText,
        border: OutlineInputBorder(),
      ),
      items: departments.map((dept) {
        return DropdownMenuItem<int>(
          value: dept.id,
          child: Text(dept.name),
        );
      }).toList(),
      onChanged: departments.isEmpty ? null : onChanged,
      validator: (value) {
        if (isRequired && value == null) {
          return 'الرجاء اختيار القسم';
        }
        return null;
      },
    );
  }
}
```

**Updated RegisterPage**
```dart
class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  int? _selectedOrganizationId;
  int? _selectedDepartmentId;
  String _selectedRole = 'user'; // 'user' or 'admin'

  @override
  void initState() {
    super.initState();
    // Load organizations when page opens
    context.read<AuthBloc>().add(LoadOrganizationsEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('التسجيل')),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state.status == AuthStatus.success) {
            Navigator.of(context).pushReplacementNamed('/home');
          } else if (state.status == AuthStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage ?? 'حدث خطأ')),
            );
          }
        },
        builder: (context, state) {
          return Form(
            key: _formKey,
            child: ListView(
              padding: EdgeInsets.all(16),
              children: [
                // Name field
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: 'الاسم'),
                  validator: (value) => value?.isEmpty ?? true ? 'الرجاء إدخال الاسم' : null,
                ),
                SizedBox(height: 16),
                
                // Email field
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(labelText: 'البريد الإلكتروني'),
                  validator: (value) => value?.isEmpty ?? true ? 'الرجاء إدخال البريد الإلكتروني' : null,
                ),
                SizedBox(height: 16),
                
                // Password field
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(labelText: 'كلمة المرور'),
                  obscureText: true,
                  validator: (value) => value?.isEmpty ?? true ? 'الرجاء إدخال كلمة المرور' : null,
                ),
                SizedBox(height: 16),
                
                // Confirm password field
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: InputDecoration(labelText: 'تأكيد كلمة المرور'),
                  obscureText: true,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'الرجاء تأكيد كلمة المرور';
                    if (value != _passwordController.text) return 'كلمات المرور غير متطابقة';
                    return null;
                  },
                ),
                SizedBox(height: 16),
                
                // Role selection (for demo - in production this might be determined differently)
                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  decoration: InputDecoration(labelText: 'نوع المستخدم'),
                  items: [
                    DropdownMenuItem(value: 'user', child: Text('مستخدم عادي')),
                    DropdownMenuItem(value: 'admin', child: Text('مدير')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedRole = value!;
                      // Clear department when switching to admin
                      if (_selectedRole == 'admin') {
                        _selectedDepartmentId = null;
                      }
                    });
                  },
                ),
                SizedBox(height: 16),
                
                // Organization dropdown
                OrganizationDropdown(
                  organizations: state.organizations,
                  selectedOrganizationId: _selectedOrganizationId,
                  isLoading: state.isLoadingOrganizations,
                  onChanged: (organizationId) {
                    setState(() {
                      _selectedOrganizationId = organizationId;
                      _selectedDepartmentId = null; // Reset department
                    });
                    if (organizationId != null) {
                      context.read<AuthBloc>().add(LoadDepartmentsEvent(organizationId));
                    }
                  },
                ),
                SizedBox(height: 16),
                
                // Department dropdown (only for regular users)
                if (_selectedRole == 'user')
                  DepartmentDropdown(
                    departments: state.departments,
                    selectedDepartmentId: _selectedDepartmentId,
                    isLoading: state.isLoadingDepartments,
                    isRequired: true,
                    onChanged: (departmentId) {
                      setState(() {
                        _selectedDepartmentId = departmentId;
                      });
                    },
                  ),
                SizedBox(height: 24),
                
                // Submit button
                ElevatedButton(
                  onPressed: state.status == AuthStatus.loading ? null : _handleSubmit,
                  child: state.status == AuthStatus.loading
                      ? CircularProgressIndicator()
                      : Text('تسجيل'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      if (_selectedOrganizationId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('الرجاء اختيار المنظمة')),
        );
        return;
      }
      
      if (_selectedRole == 'user' && _selectedDepartmentId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('الرجاء اختيار القسم')),
        );
        return;
      }

      context.read<AuthBloc>().add(
        RegisterSubmittedEvent(
          name: _nameController.text,
          email: _emailController.text,
          password: _passwordController.text,
          passwordConfirmation: _confirmPasswordController.text,
          organizationId: _selectedOrganizationId!,
          departmentId: _selectedDepartmentId,
          role: _selectedRole,
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
```

## Data Flow

### Registration Flow

1. User opens registration page
2. Page loads organizations from API (`GET /api/v1/organizations`)
3. User selects organization from dropdown
4. Page loads departments for selected organization (`GET /api/v1/organizations/{id}/departments`)
5. User selects department (if regular user) or skips (if admin)
6. User fills in other registration fields
7. User submits form
8. App sends registration request with organizational context (`POST /api/v1/auth/register`)
9. Backend validates and creates user with organizational associations
10. App receives user data with organization and department information
11. App stores user session and navigates to home

### Data Access Flow

1. User logs in
2. Backend returns JWT token with organizational context
3. App stores token and user information
4. When fetching data (expenses, transfers, etc.):
   - Admin users: Backend filters by `organization_id`
   - Regular users: Backend filters by `user_id`
5. App displays filtered data based on user's role

## Error Handling

### Validation Errors

- Organization not selected: "الرجاء اختيار المنظمة"
- Department not selected (for regular users): "الرجاء اختيار القسم"
- Invalid organization ID: "المنظمة المحددة غير موجودة"
- Invalid department ID: "القسم المحدد غير موجود"
- Department doesn't belong to organization: "القسم لا ينتمي للمنظمة المحددة"

### Network Errors

- Failed to load organizations: Show retry button
- Failed to load departments: Show retry button
- Registration failed: Display error message from backend

### State Management

- Loading states for organizations and departments
- Error states with user-friendly messages
- Success states with navigation

## Testing Strategy

### Unit Tests

- OrganizationModel and DepartmentModel serialization
- UserModel updates with organizational fields
- Use case logic for fetching organizations and departments
- BLoC event handling and state transitions

### Widget Tests

- OrganizationDropdown rendering and interaction
- DepartmentDropdown rendering and interaction
- RegisterPage form validation
- Conditional rendering based on user role

### Integration Tests

- Complete registration flow for regular user
- Complete registration flow for admin user
- Organization selection triggering department load
- Error handling for invalid selections

## Localization

### Arabic Strings (ar.arb)

```json
{
  "organization": "المنظمة",
  "department": "القسم",
  "selectOrganization": "اختر المنظمة",
  "selectDepartment": "اختر القسم",
  "organizationRequired": "الرجاء اختيار المنظمة",
  "departmentRequired": "الرجاء اختيار القسم",
  "regularUser": "مستخدم عادي",
  "adminUser": "مدير",
  "userType": "نوع المستخدم"
}
```

### English Strings (en.arb)

```json
{
  "organization": "Organization",
  "department": "Department",
  "selectOrganization": "Select Organization",
  "selectDepartment": "Select Department",
  "organizationRequired": "Please select an organization",
  "departmentRequired": "Please select a department",
  "regularUser": "Regular User",
  "adminUser": "Administrator",
  "userType": "User Type"
}
```

## Security Considerations

1. **No Client-Side Role Assignment**: In production, user roles should be assigned by admins, not during self-registration
2. **Token Validation**: Always validate JWT tokens on every request
3. **Data Filtering**: Never trust client-side filtering - all filtering must happen on backend
4. **Input Validation**: Validate all user inputs before sending to backend

## Performance Optimization

1. **Caching**: Cache organizations list (rarely changes)
2. **Lazy Loading**: Only load departments when organization is selected
3. **Debouncing**: Debounce API calls if user rapidly changes selections
4. **Error Recovery**: Implement retry logic for failed API calls

## Future Enhancements

1. **Multi-Organization Support**: Allow users to switch between organizations
2. **Department Hierarchy**: Support nested department structures
3. **Bulk User Import**: Admin feature to import users with organizational assignments
4. **Organization Settings**: Per-organization configuration and branding
5. **Department Transfer**: Allow admins to move users between departments
