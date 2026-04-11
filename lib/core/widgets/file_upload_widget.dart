import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../models/file_upload_dto.dart';
import '../services/file_upload_service.dart';

/// Widget for uploading files (receipts, invoices, documents)
class FileUploadWidget extends StatefulWidget {
  final FileType fileType;
  final Function(FileUploadDto) onFileUploaded;
  final Function(String)? onError;
  final String? label;
  final bool allowCamera;
  final bool allowGallery;
  final bool allowDocuments;

  const FileUploadWidget({
    super.key,
    required this.fileType,
    required this.onFileUploaded,
    this.onError,
    this.label,
    this.allowCamera = true,
    this.allowGallery = true,
    this.allowDocuments = true,
  });

  @override
  State<FileUploadWidget> createState() => _FileUploadWidgetState();
}

class _FileUploadWidgetState extends State<FileUploadWidget> {
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              widget.label!,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        if (_isUploading)
          _buildUploadProgress()
        else
          _buildUploadButtons(),
      ],
    );
  }

  Widget _buildUploadProgress() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('Uploading...'),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: _uploadProgress),
            const SizedBox(height: 8),
            Text('${(_uploadProgress * 100).toStringAsFixed(0)}%'),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadButtons() {
    final buttons = <Widget>[];

    if (widget.allowCamera) {
      buttons.add(
        _buildUploadButton(
          icon: Icons.camera_alt,
          label: 'Camera',
          onTap: () => _pickImage(ImageSource.camera),
        ),
      );
    }

    if (widget.allowGallery) {
      buttons.add(
        _buildUploadButton(
          icon: Icons.photo_library,
          label: 'Gallery',
          onTap: () => _pickImage(ImageSource.gallery),
        ),
      );
    }

    if (widget.allowDocuments) {
      buttons.add(
        _buildUploadButton(
          icon: Icons.insert_drive_file,
          label: 'Document',
          onTap: _pickDocument,
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: buttons,
    );
  }

  Widget _buildUploadButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 32),
              const SizedBox(height: 4),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        await _uploadFile(File(image.path));
      }
    } catch (e) {
      _handleError('Failed to pick image: ${e.toString()}');
    }
  }

  Future<void> _pickDocument() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
      );

      if (result != null && result.files.single.path != null) {
        await _uploadFile(File(result.files.single.path!));
      }
    } catch (e) {
      _handleError('Failed to pick document: ${e.toString()}');
    }
  }

  Future<void> _uploadFile(File file) async {
    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      // Get file upload service from context
      // In a real app, you'd use dependency injection or provider
      final fileUploadService = _getFileUploadService();

      final result = await fileUploadService.uploadFile(
        file: file,
        type: widget.fileType,
        onProgress: (progress) {
          setState(() {
            _uploadProgress = progress;
          });
        },
      );

      widget.onFileUploaded(result);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File uploaded successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _handleError('Failed to upload file: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = 0.0;
        });
      }
    }
  }

  void _handleError(String message) {
    if (widget.onError != null) {
      widget.onError!(message);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  FileUploadService _getFileUploadService() {
    // This is a placeholder - in a real app, you'd use dependency injection
    // or get it from a provider/service locator
    throw UnimplementedError(
      'FileUploadService must be provided via dependency injection',
    );
  }
}
