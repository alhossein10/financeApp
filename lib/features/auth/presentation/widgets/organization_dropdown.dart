import 'package:flutter/material.dart';
import '../../domain/entities/organization.dart';

/// A dropdown widget for selecting an organization
/// 
/// This widget displays a list of organizations in a dropdown format
/// with loading state support and validation.
class OrganizationDropdown extends StatelessWidget {
  final List<Organization> organizations;
  final int? selectedOrganizationId;
  final ValueChanged<int?> onChanged;
  final bool isLoading;
  final String? errorText;

  const OrganizationDropdown({
    super.key,
    required this.organizations,
    this.selectedOrganizationId,
    required this.onChanged,
    this.isLoading = false,
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

    return DropdownButtonFormField<int>(
      value: selectedOrganizationId,
      decoration: InputDecoration(
        labelText: 'المنظمة',
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
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      items: organizations.map((organization) {
        return DropdownMenuItem<int>(
          value: organization.id,
          child: Text(organization.name),
        );
      }).toList(),
      onChanged: onChanged,
      validator: (value) {
        if (value == null) {
          return 'الرجاء اختيار المنظمة';
        }
        return null;
      },
      isExpanded: true,
      hint: const Text('اختر المنظمة'),
    );
  }
}
