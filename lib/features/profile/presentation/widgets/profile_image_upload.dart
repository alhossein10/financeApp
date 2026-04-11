import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/services/profile_image_upload_service.dart';

/// Widget for uploading and displaying profile images
/// Displays current profile image as circular avatar with upload button
class ProfileImageUpload extends StatefulWidget {
  final String? currentImageUrl;
  final Function(String imageUrl) onImageUploaded;
  final ProfileImageUploadService uploadService;
  final double size;

  const ProfileImageUpload({
    super.key,
    this.currentImageUrl,
    required this.onImageUploaded,
    required this.uploadService,
    this.size = 120,
  });

  @override
  State<ProfileImageUpload> createState() => _ProfileImageUploadState();
}

class _ProfileImageUploadState extends State<ProfileImageUpload> {
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _errorMessage;
  File? _selectedImage;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Profile Image Display
        Stack(
          children: [
            // Circular Avatar
            Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).primaryColor,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: _buildImageWidget(),
              ),
            ),

            // Upload Progress Indicator
            if (_isUploading)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withOpacity(0.5),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          value: _uploadProgress,
                          backgroundColor: Colors.white.withOpacity(0.3),
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${(_uploadProgress * 100).toInt()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Upload Button
            if (!_isUploading)
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _showImageSourceOptions,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
          ],
        ),

        // Error Message
        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.red.withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => setState(() => _errorMessage = null),
                  child: const Icon(
                    Icons.close,
                    color: Colors.red,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildImageWidget() {
    // Show selected image (before upload)
    if (_selectedImage != null) {
      return Image.file(
        _selectedImage!,
        fit: BoxFit.cover,
      );
    }

    // Show current profile image from URL
    if (widget.currentImageUrl != null && widget.currentImageUrl!.isNotEmpty) {
      return Image.network(
        widget.currentImageUrl!,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholder();
        },
      );
    }

    // Show placeholder
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[300],
      child: Icon(
        Icons.person,
        size: widget.size * 0.6,
        color: Colors.grey[600],
      ),
    );
  }

  void _showImageSourceOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Choose Profile Picture',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              const SizedBox(height: 20),

              // Camera Option
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.camera_alt,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                title: const Text('Take Photo'),
                subtitle: const Text('Use camera to take a new photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),

              // Gallery Option
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.photo_library,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                title: const Text('Choose from Gallery'),
                subtitle: const Text('Select an existing photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),

              // Cancel Option
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      setState(() {
        _errorMessage = null;
      });

      // Pick image based on source
      final File? imageFile;
      if (source == ImageSource.camera) {
        imageFile = await widget.uploadService.pickImageFromCamera();
      } else {
        imageFile = await widget.uploadService.pickImageFromGallery();
      }

      if (imageFile == null) {
        // User cancelled
        return;
      }

      // Validate image file
      if (!widget.uploadService.isValidImageFile(imageFile)) {
        setState(() {
          _errorMessage = 'Invalid image format. Please select a valid image file.';
        });
        return;
      }

      // Show selected image
      setState(() {
        _selectedImage = imageFile;
      });

      // Upload image
      await _uploadImage(imageFile);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to pick image: ${e.toString()}';
        _selectedImage = null;
      });
    }
  }

  Future<void> _uploadImage(File imageFile) async {
    try {
      setState(() {
        _isUploading = true;
        _uploadProgress = 0.0;
        _errorMessage = null;
      });

      // Upload image with progress tracking
      final imageUrl = await widget.uploadService.uploadProfileImage(
        imageFile,
        onProgress: (progress) {
          setState(() {
            _uploadProgress = progress;
          });
        },
      );

      // Notify parent widget
      widget.onImageUploaded(imageUrl);

      setState(() {
        _isUploading = false;
        _selectedImage = null;
      });
    } catch (e) {
      setState(() {
        _isUploading = false;
        _errorMessage = 'Upload failed: ${e.toString()}';
        _selectedImage = null;
      });
    }
  }
}
