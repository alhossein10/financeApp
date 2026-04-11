import 'package:flutter/material.dart';
import '../../domain/entities/department.dart';

/// A dropdown widget for selecting a department
/// 
/// This widget displays a list of departments in a dropdown format
/// with loading state support, conditional validation, and automatic
/// disabling when no departments are available.
class DepartmentDropdown extends StatelessWidget {
  final List<Department> departments;
  final int? selectedDepartmentId;
  final ValueChanged<int?> onChanged;
  final bool isLoading;
  final bool isRequired;
  final String? errorText;

  const DepartmentDropdown({
    super.key,
    required this.departments,
    this.selectedDepartmentId,
    required this.onChanged,
    this.isLoading = false,
    this.isRequired = true,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    // Show loading indicator when data is being fetched
    if (isLoading) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Disable dropdown when departments list is empty
    final bool isEnabled = departments.isNotEmpty;

    return DropdownButtonFormField<int>(
      initialValue: selectedDepartmentId,
      decoration: InputDecoration(
        labelText: 'القسم',
        errorText: errorText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        filled: true,
        fillColor: isEnabled ? Colors.white : Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      items: departments.map((department) {
        return DropdownMenuItem<int>(
          value: department.id,
          child: Text(department.name),
        );
      }).toList(),
      onChanged: isEnabled ? onChanged : null,
      validator: (value) {
        // Only validate if department is required (for regular users)
        if (isRequired && value == null) {
          return 'الرجاء اختيار القسم';
        }
        return null;
      },
      isExpanded: true,
      hint: Text(
        isEnabled ? 'اختر القسم' : 'اختر المنظمة أولاً',
        style: TextStyle(
          color: isEnabled ? null : Colors.grey.shade500,
        ),
      ),
      disabledHint: Text(
        'اختر المنظمة أولاً',
        style: TextStyle(color: Colors.grey.shade500),
      ),
    );
  }
}
