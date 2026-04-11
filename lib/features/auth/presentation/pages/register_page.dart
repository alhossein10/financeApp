import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/config/flavor_config.dart';
import '../../../admin_group/presentation/widgets/group_code_input.dart';
import '../../../organizations/data/datasources/organizations_api_datasource.dart';
import '../../../organizations/data/datasources/organizations_cache_datasource.dart';
import '../../../organizations/data/models/organization_dto.dart';
import '../../../organizations/data/models/department_dto.dart';
import '../../../../injection_container.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/app_logo.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/admin_registration_success_dialog.dart';
import '../widgets/superadmin_registration_success_dialog.dart';
import '../../../../core/widgets/watermark_background.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _organizationNameController = TextEditingController();
  final _departmentNameController = TextEditingController();
  final _adminGroupNameController = TextEditingController();
  final _groupCodeController = TextEditingController();
  final _superAdminGroupCodeController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSubmitting = false;

  // Organizations and departments state
  List<OrganizationDto> _organizations = [];
  List<DepartmentDto> _departments = [];
  OrganizationDto? _selectedOrganization;
  DepartmentDto? _selectedDepartment;
  bool _isLoadingOrganizations = false;
  bool _isLoadingDepartments = false;
  String? _organizationsError;
  String? _departmentsError;

  late final OrganizationsApiDatasource _organizationsApi;
  late final OrganizationsCacheDatasource _organizationsCache;

  @override
  void initState() {
    super.initState();
    _organizationsApi = sl<OrganizationsApiDatasource>();
    _organizationsCache = sl<OrganizationsCacheDatasource>();
    _loadOrganizations();
  }

  /// Load organizations from API or cache
  Future<void> _loadOrganizations() async {
    setState(() {
      _isLoadingOrganizations = true;
      _organizationsError = null;
    });

    try {
      // Try to load from cache first
      final cachedOrganizations = await _organizationsCache.getCachedOrganizations();
      if (cachedOrganizations != null && cachedOrganizations.isNotEmpty) {
        setState(() {
          _organizations = cachedOrganizations;
          _isLoadingOrganizations = false;
        });
        print('[RegisterPage] ✅ Loaded ${cachedOrganizations.length} organizations from cache');
        
        // Fetch fresh data in background
        _fetchOrganizationsInBackground();
        return;
      }

      // No cache, fetch from API
      final organizations = await _organizationsApi.getOrganizations();
      
      // Cache the results
      await _organizationsCache.cacheOrganizations(organizations);
      
      setState(() {
        _organizations = organizations;
        _isLoadingOrganizations = false;
      });
      
      print('[RegisterPage] ✅ Loaded ${organizations.length} organizations from API');
    } catch (e) {
      print('[RegisterPage] 🔴 Error loading organizations: $e');
      setState(() {
        _organizationsError = 'Failed to load organizations. Please try again.';
        _isLoadingOrganizations = false;
      });
    }
  }

  /// Fetch organizations in background to update cache
  Future<void> _fetchOrganizationsInBackground() async {
    try {
      final organizations = await _organizationsApi.getOrganizations();
      await _organizationsCache.cacheOrganizations(organizations);
      
      // Update UI if data changed
      if (mounted && organizations.length != _organizations.length) {
        setState(() {
          _organizations = organizations;
        });
      }
    } catch (e) {
      print('[RegisterPage] ⚠️ Background fetch failed: $e');
      // Silently fail - we already have cached data
    }
  }

  /// Load departments for selected organization
  Future<void> _loadDepartments(int organizationId) async {
    setState(() {
      _isLoadingDepartments = true;
      _departmentsError = null;
      _departments = [];
      _selectedDepartment = null;
    });

    try {
      // Try to load from cache first
      final cachedDepartments = await _organizationsCache.getCachedDepartments(organizationId);
      if (cachedDepartments != null) {
        setState(() {
          _departments = cachedDepartments;
          _isLoadingDepartments = false;
        });
        print('[RegisterPage] ✅ Loaded ${cachedDepartments.length} departments from cache');
        return;
      }

      // No cache, fetch from API
      final departments = await _organizationsApi.getDepartments(organizationId);
      
      // Cache the results
      await _organizationsCache.cacheDepartments(organizationId, departments);
      
      setState(() {
        _departments = departments;
        _isLoadingDepartments = false;
      });
      
      print('[RegisterPage] ✅ Loaded ${departments.length} departments from API');
    } catch (e) {
      print('[RegisterPage] 🔴 Error loading departments: $e');
      setState(() {
        _departmentsError = 'Failed to load departments. Please try again.';
        _isLoadingDepartments = false;
      });
    }
  }

  // Get role based on flavor
  String get _role {
    if (FlavorConfig.instance.isSuperAdmin) {
      return 'superAdmin';
    } else if (FlavorConfig.instance.isAdmin) {
      return 'admin';
    } else {
      return 'user';
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _organizationNameController.dispose();
    _departmentNameController.dispose();
    _adminGroupNameController.dispose();
    _groupCodeController.dispose();
    _superAdminGroupCodeController.dispose();
    super.dispose();
  }

  void _handleRegister() {
    // Prevent multiple submissions
    if (_isSubmitting) {
      print('⚠️ [RegisterPage] Registration already in progress, ignoring duplicate request');
      return;
    }
    
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isSubmitting = true;
      });
      
      final isArabic = Localizations.localeOf(context).languageCode == 'ar';
      final role = _role;
      
      // SuperAdmin flavor: no group code needed (backend generates it)
      // Admin flavor: SuperAdmin group code is required
      // User flavor: admin group code is required
      
      String? groupCode;
      String? superAdminGroupCode;
      
      if (FlavorConfig.instance.isAdmin) {
        // Admin flavor: require SuperAdmin group code
        final superAdminCode = _superAdminGroupCodeController.text.trim();
        if (superAdminCode.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isArabic ? 'رمز مجموعة SuperAdmin مطلوب' : 'SuperAdmin group code is required',
              ),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        
        if (superAdminCode.length != 6) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isArabic ? 'رمز مجموعة SuperAdmin يجب أن يكون 6 أحرف' : 'SuperAdmin group code must be 6 characters',
              ),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        superAdminGroupCode = superAdminCode;
      } else if (FlavorConfig.instance.isUser) {
        // User flavor: require admin group code
        final adminCode = _groupCodeController.text.trim();
        if (adminCode.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isArabic ? 'رمز المجموعة مطلوب' : 'Group code is required',
              ),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        
        if (adminCode.length != 6) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isArabic ? 'رمز المجموعة يجب أن يكون 6 أحرف' : 'Group code must be 6 characters',
              ),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        groupCode = adminCode;
      }
      // SuperAdmin flavor: no group code validation needed
      
      // For SuperAdmin, admin_group_name is required
      String? adminGroupName;
      if (FlavorConfig.instance.isSuperAdmin) {
        adminGroupName = _adminGroupNameController.text.trim();
        if (adminGroupName.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isArabic ? 'اسم مجموعة SuperAdmin مطلوب' : 'SuperAdmin group name is required',
              ),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }
      
      // Dispatch RegisterSubmittedEvent with new fields
      context.read<AuthBloc>().add(
            AuthRegisterRequested(
              username: _usernameController.text.trim(),
              email: _emailController.text.trim(),
              password: _passwordController.text,
              confirmPassword: _confirmPasswordController.text,
              organizationName: _organizationNameController.text.trim(),
              departmentName: _departmentNameController.text.trim().isEmpty 
                  ? null 
                  : _departmentNameController.text.trim(),
              adminGroupName: adminGroupName,
              groupCode: groupCode,
              superAdminGroupCode: superAdminGroupCode,
              role: role,
            ),
          );
    }
  }



  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(isArabic ? 'إنشاء حساب جديد' : 'Create Account'),
        centerTitle: true,
      ),
      body: WatermarkBackground(
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
          // Handle registration failure with error message
          if (state.status == AuthStatus.error && state.errorMessage != null) {
            setState(() {
              _isSubmitting = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 4),
              ),
            );
          } 
          // Legacy support for AuthError state
          else if (state is AuthError) {
            setState(() {
              _isSubmitting = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? 'An error occurred'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 4),
              ),
            );
          } 
          // Handle registration success
          else if (state.status == AuthStatus.authenticated || state is AuthAuthenticated) {
            setState(() {
              _isSubmitting = false;
            });
            // Get registration result from state
            final registrationResult = state.registrationResult;
            final isArabic = Localizations.localeOf(context).languageCode == 'ar';
            
            // For SuperAdmin users, show SuperAdmin group code dialog (auto-generated by backend)
            if (FlavorConfig.instance.isSuperAdmin && registrationResult?.superAdminGroupCode != null) {
              SuperAdminRegistrationSuccessDialog.show(
                context: context,
                superAdminGroupCode: registrationResult!.superAdminGroupCode!,
                adminGroupName: registrationResult.adminGroupName,
                onContinue: () {
                  Navigator.of(context).pushReplacementNamed('/home');
                },
              );
            }
            // For admin users, show admin group code dialog
            else if (FlavorConfig.instance.isAdmin && registrationResult?.groupCode != null) {
              AdminRegistrationSuccessDialog.show(
                context: context,
                groupCode: registrationResult!.groupCode!,
                isSuperAdmin: false,
                onContinue: () {
                  Navigator.of(context).pushReplacementNamed('/home');
                },
              );
            } else {
              // For regular users, show success message and navigate
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isArabic
                        ? 'تم إنشاء الحساب بنجاح!'
                        : 'Account created successfully!',
                  ),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.of(context).pushReplacementNamed('/home');
            }
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),

                    // Eagle with text logo
                    Center(
                      child: Image.asset(
                        'assets/images/eagle_with_text.png',
                        width: 200,
                        height: 200,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          // Fallback to AppLogo if image not found
                          return const AppLogo(size: 80, showText: false);
                        },
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Welcome Text
                    Text(
                      isArabic ? 'إنشاء حساب جديد' : 'Create Your Account',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isArabic
                          ? 'املأ البيانات للبدء'
                          : 'Fill in the details to get started',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),

                    // Username Field
                    AuthTextField(
                      controller: _usernameController,
                      label: isArabic ? 'اسم المستخدم' : 'Username',
                      hint: isArabic ? 'أدخل اسم المستخدم' : 'Enter your username',
                      enabled: !isLoading,
                      validator: Validators.validateUsername,
                    ),
                    const SizedBox(height: 16),

                    // Email Field
                    AuthTextField(
                      controller: _emailController,
                      label: isArabic ? 'البريد الإلكتروني' : 'Email',
                      hint: isArabic ? 'أدخل بريدك الإلكتروني' : 'Enter your email',
                      keyboardType: TextInputType.emailAddress,
                      enabled: !isLoading,
                      validator: Validators.validateEmail,
                    ),
                    const SizedBox(height: 16),

                    // Password Field
                    AuthTextField(
                      controller: _passwordController,
                      label: isArabic ? 'كلمة المرور' : 'Password',
                      hint: isArabic ? 'أدخل كلمة المرور' : 'Enter your password',
                      obscureText: _obscurePassword,
                      enabled: !isLoading,
                      validator: Validators.validatePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Password Requirements
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        isArabic
                            ? 'يجب أن تحتوي كلمة المرور على 8 أحرف على الأقل، حرف كبير، حرف صغير، ورقم'
                            : 'Password must be at least 8 characters with uppercase, lowercase, and number',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Confirm Password Field
                    AuthTextField(
                      controller: _confirmPasswordController,
                      label: isArabic ? 'تأكيد كلمة المرور' : 'Confirm Password',
                      hint: isArabic ? 'أعد إدخال كلمة المرور' : 'Re-enter your password',
                      obscureText: _obscureConfirmPassword,
                      enabled: !isLoading,
                      validator: (value) => Validators.validatePasswordConfirmation(
                        _passwordController.text,
                        value,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Organization Dropdown
                    if (_isLoadingOrganizations)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_organizationsError != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline, color: Colors.red.shade700),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _organizationsError!,
                                    style: TextStyle(color: Colors.red.shade700),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: _loadOrganizations,
                            icon: const Icon(Icons.refresh),
                            label: Text(isArabic ? 'إعادة المحاولة' : 'Retry'),
                          ),
                        ],
                      )
                    else if (_organizations.isEmpty)
                      // Fallback to text field if no organizations available
                      AuthTextField(
                        controller: _organizationNameController,
                        label: isArabic ? 'اسم الجهة' : 'Organization Name',
                        hint: isArabic ? 'أدخل اسم الجهة' : 'Enter organization name',
                        enabled: !isLoading,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return isArabic ? 'اسم الجهة مطلوب' : 'Organization name is required';
                          }
                          return null;
                        },
                      )
                    else
                      DropdownButtonFormField<OrganizationDto>(
                        value: _selectedOrganization,
                        decoration: InputDecoration(
                          labelText: isArabic ? 'اسم الجهة' : 'Organization',
                          hintText: isArabic ? 'اختر الجهة' : 'Select organization',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        items: _organizations.map((org) {
                          return DropdownMenuItem<OrganizationDto>(
                            value: org,
                            child: Text(org.name),
                          );
                        }).toList(),
                        onChanged: isLoading ? null : (OrganizationDto? value) {
                          setState(() {
                            _selectedOrganization = value;
                            _organizationNameController.text = value?.name ?? '';
                            
                            // Load departments when organization is selected
                            if (value != null) {
                              _loadDepartments(value.id);
                            } else {
                              _departments = [];
                              _selectedDepartment = null;
                            }
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return isArabic ? 'اسم الجهة مطلوب' : 'Organization is required';
                          }
                          return null;
                        },
                      ),
                    const SizedBox(height: 16),

                    // Department Dropdown (only show if organization is selected)
                    if (_selectedOrganization != null) ...[
                      if (_isLoadingDepartments)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (_departmentsError != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.orange.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.warning_amber, color: Colors.orange.shade700),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _departmentsError!,
                                      style: TextStyle(color: Colors.orange.shade700),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: () => _loadDepartments(_selectedOrganization!.id),
                              icon: const Icon(Icons.refresh),
                              label: Text(isArabic ? 'إعادة المحاولة' : 'Retry'),
                            ),
                          ],
                        )
                      else if (_departments.isEmpty)
                        // Show optional text field if no departments
                        AuthTextField(
                          controller: _departmentNameController,
                          label: isArabic ? 'اسم الفرع (اختياري)' : 'Department Name (optional)',
                          hint: isArabic ? 'أدخل اسم الفرع' : 'Enter department name',
                          enabled: !isLoading,
                        )
                      else
                        DropdownButtonFormField<DepartmentDto>(
                          value: _selectedDepartment,
                          decoration: InputDecoration(
                            labelText: isArabic ? 'اسم الفرع (اختياري)' : 'Department (optional)',
                            hintText: isArabic ? 'اختر الفرع' : 'Select department',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          items: _departments.map((dept) {
                            return DropdownMenuItem<DepartmentDto>(
                              value: dept,
                              child: Text(dept.name),
                            );
                          }).toList(),
                          onChanged: isLoading ? null : (DepartmentDto? value) {
                            setState(() {
                              _selectedDepartment = value;
                              _departmentNameController.text = value?.name ?? '';
                            });
                          },
                        ),
                      const SizedBox(height: 16),
                    ],

                    // Admin Group Name Field (required for SuperAdmin)
                    if (FlavorConfig.instance.isSuperAdmin)
                      AuthTextField(
                        controller: _adminGroupNameController,
                        label: isArabic ? 'اسم مجموعة SuperAdmin' : 'SuperAdmin Group Name',
                        hint: isArabic ? 'أدخل اسم مجموعة SuperAdmin' : 'Enter SuperAdmin group name',
                        enabled: !isLoading,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return isArabic ? 'اسم مجموعة SuperAdmin مطلوب' : 'SuperAdmin group name is required';
                          }
                          return null;
                        },
                      ),
                    if (FlavorConfig.instance.isSuperAdmin)
                      const SizedBox(height: 16),

                    // Group Code Input based on flavor
                    // SuperAdmin flavor: no group code field (backend generates it)
                    // Admin flavor: SuperAdmin group code (required)
                    // User flavor: admin group code (required)
                    if (FlavorConfig.instance.isAdmin)
                      AuthTextField(
                        controller: _superAdminGroupCodeController,
                        label: isArabic ? 'رمز مجموعة SuperAdmin' : 'SuperAdmin Group Code',
                        hint: isArabic ? 'أدخل رمز مجموعة SuperAdmin للانضمام' : 'Enter SuperAdmin group code to join',
                        enabled: !isLoading,
                        validator: (value) {
                          // Required field for admin flavor
                          if (value == null || value.trim().isEmpty) {
                            return isArabic
                                ? 'رمز مجموعة SuperAdmin مطلوب'
                                : 'SuperAdmin group code is required';
                          }
                          if (value.trim().length != 6) {
                            return isArabic
                                ? 'يجب أن يكون رمز المجموعة 6 أحرف'
                                : 'Group code must be 6 characters';
                          }
                          if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(value.trim())) {
                            return isArabic
                                ? 'يجب أن يحتوي رمز المجموعة على أحرف وأرقام فقط'
                                : 'Group code must contain only letters and numbers';
                          }
                          return null;
                        },
                      ),
                    if (FlavorConfig.instance.isAdmin)
                      const SizedBox(height: 16),
                    
                    if (FlavorConfig.instance.isUser)
                      GroupCodeInput(
                        controller: _groupCodeController,
                        enabled: !isLoading,
                      ),
                    if (FlavorConfig.instance.isUser)
                      const SizedBox(height: 16),

                    // Register Button
                    ElevatedButton(
                      onPressed: (isLoading || _isSubmitting) ? null : _handleRegister,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              isArabic ? 'إنشاء حساب' : 'Create Account',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                    const SizedBox(height: 24),

                    // Already have an account
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isArabic ? 'لديك حساب بالفعل؟' : 'Already have an account?',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        TextButton(
                          onPressed: isLoading
                              ? null
                              : () {
                                  Navigator.of(context).pop();
                                },
                          child: Text(
                            isArabic ? 'تسجيل الدخول' : 'Login',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
          },
        ),
      ),
    );
  }
}
