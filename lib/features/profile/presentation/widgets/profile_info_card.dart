import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/services/profile_image_upload_service.dart';
import '../../../auth/domain/entities/user.dart';
import 'profile_image_upload.dart';
import 'profile_photo_widget.dart';

/// Card displaying user profile information
class ProfileInfoCard extends StatelessWidget {
  final User user;
  final VoidCallback onEditPressed;
  final VoidCallback onProfilePicturePressed;
  final ProfileImageUploadService? uploadService;
  final Function(String imageUrl)? onImageUploaded;

  const ProfileInfoCard({
    super.key,
    required this.user,
    required this.onEditPressed,
    required this.onProfilePicturePressed,
    this.uploadService,
    this.onImageUploaded,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Picture - Use new ProfilePhotoWidget
            ProfilePhotoWidget(
              photoUrl: user.profileImageUrl,
              size: 100,
            ),
            const SizedBox(height: 16),
            
            // Username
            Text(
              user.username,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            
            // Email
            Text(
              user.email,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            
            // Account Creation Date
            Text(
              '${l10n?.memberSince ?? 'Member since'} ${_formatDate(user.createdAt)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 16),
            
            // Edit Button
            ElevatedButton.icon(
              onPressed: onEditPressed,
              icon: const Icon(Icons.edit),
              label: Text(l10n?.editProfile ?? 'Edit Profile'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 40),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    
    return '${months[date.month - 1]} ${date.year}';
  }
}