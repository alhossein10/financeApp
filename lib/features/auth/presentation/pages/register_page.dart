import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/config/flavor_config.dart';
import '../../../admin_group/presentation/widgets/group_code_input.dart';
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
  final _groupCodeController = TextEditingController();
  final _superAdminGroupCodeController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
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
    _groupCodeController.dispose();
    _superAdminGroupCodeController.dispose();
    super.dispose();
  }

  void _handleRegister() {
    if (_formKey.currentState?.validate() ?? false) {
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
              // Get registration result from state
              final registrationResult = state.registrationResult;
              final isArabic = Localizations.localeOf(context).languageCode == 'ar';
              
              // For SuperAdmin users, show SuperAdmin group code dialog (auto-generated by backend)
              if (FlavorConfig.instance.isSuperAdmin && registrationResult?.superAdminGroupCode != null) {
                // Show dialog and navigate after dismissal
                SuperAdminRegistrationSuccessDialog.show(
                  context: context,
                  groupCode: registrationResult!.superAdminGroupCode!,
                  adminGroupName: registrationResult.adminGroupName ?? 'SuperAdmin Group',
                ).then((_) {
                  // Check if widget is still mounted before navigating
                  if (context.mounted) {
                    Navigator.of(context).pushReplacementNamed('/home');
                  }
                });
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
            final isLoading = state.status == AuthStatus.loading || state is AuthLoading;

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

                    // Organization Name Field (required)
                    AuthTextField(
                      controller: _organizationNameController,
                      label: isArabic ? 'اسم المنظمة' : 'Organization Name',
                      hint: isArabic ? 'أدخل اسم المنظمة' : 'Enter organization name',
                      enabled: !isLoading,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return isArabic ? 'اسم المنظمة مطلوب' : 'Organization name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Department Name Field (optional)
                    AuthTextField(
                      controller: _departmentNameController,
                      label: isArabic ? 'اسم القسم (اختياري)' : 'Department Name (optional)',
                      hint: isArabic ? 'أدخل اسم القسم' : 'Enter department name',
                      enabled: !isLoading,
                    ),
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
                      onPressed: isLoading ? null : _handleRegister,
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
