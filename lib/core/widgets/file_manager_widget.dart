import 'dart:io';
import 'package:flutter/material.dart';
import '../models/file_upload_dto.dart';
import '../services/file_upload_service.dart';

/// Widget for managing uploaded files (view, download, delete)
class FileManagerWidget extends StatefulWidget {
  final List<FileUploadDto> files;
  final FileUploadService fileUploadService;
  final Function(FileUploadDto)? onFileDeleted;
  final Function(String)? onError;

  const FileManagerWidget({
    Key? key,
    required this.files,
    required this.fileUploadService,
    this.onFileDeleted,
    this.onError,
  }) : super(key: key);

  @override
  State<FileManagerWidget> createState() => _FileManagerWidgetState();
}

class _FileManagerWidgetState extends State<FileManagerWidget> {
  final Map<int, bool> _downloadingFiles = {};
  final Map<int, double> _downloadProgress = {};

  @override
  Widget build(BuildContext context) {
    if (widget.files.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No files uploaded'),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.files.length,
      itemBuilder: (context, index) {
        final file = widget.files[index];
        return _buildFileCard(file);
      },
    );
  }

  Widget _buildFileCard(FileUploadDto file) {
    final isDownloading = _downloadingFiles[file.id] ?? false;
    final progress = _downloadProgress[file.id] ?? 0.0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: _buildFileIcon(file.type),
        title: Text(
          file.filename,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_formatFileSize(file.size)),
            Text(
              'Uploaded: ${_formatDate(file.uploadedAt)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (isDownloading)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: LinearProgressIndicator(value: progress),
              ),
          ],
        ),
        trailing: isDownloading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : PopupMenuButton<String>(
                onSelected: (value) => _handleMenuAction(value, file),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'download',
                    child: Row(
                      children: [
                        Icon(Icons.download),
                        SizedBox(width: 8),
                        Text('Download'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildFileIcon(String type) {
    IconData icon;
    Color color;

    switch (type) {
      case 'receipt':
        icon = Icons.receipt;
        color = Colors.blue;
        break;
      case 'invoice':
        icon = Icons.description;
        color = Colors.green;
        break;
      case 'document':
        icon = Icons.insert_drive_file;
        color = Colors.orange;
        break;
      default:
        icon = Icons.attach_file;
        color = Colors.grey;
    }

    return CircleAvatar(
      backgroundColor: color.withOpacity(0.1),
      child: Icon(icon, color: color),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _handleMenuAction(String action, FileUploadDto file) async {
    switch (action) {
      case 'download':
        await _downloadFile(file);
        break;
      case 'delete':
        await _confirmAndDeleteFile(file);
        break;
    }
  }

  Future<void> _downloadFile(FileUploadDto file) async {
    setState(() {
      _downloadingFiles[file.id] = true;
      _downloadProgress[file.id] = 0.0;
    });

    try {
      final downloadedFile = await widget.fileUploadService.downloadFile(
        file.path,
        onProgress: (progress) {
          setState(() {
            _downloadProgress[file.id] = progress;
          });
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File downloaded to: ${downloadedFile.path}'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Open',
              onPressed: () {
                // In a real app, you'd open the file with a file viewer
                // For now, just show the path
              },
            ),
          ),
        );
      }
    } catch (e) {
      _handleError('Failed to download file: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _downloadingFiles[file.id] = false;
          _downloadProgress[file.id] = 0.0;
        });
      }
    }
  }

  Future<void> _confirmAndDeleteFile(FileUploadDto file) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete File'),
        content: Text('Are you sure you want to delete "${file.filename}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteFile(file);
    }
  }

  Future<void> _deleteFile(FileUploadDto file) async {
    try {
      await widget.fileUploadService.deleteFile(file.path);

      if (widget.onFileDeleted != null) {
        widget.onFileDeleted!(file);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _handleError('Failed to delete file: ${e.toString()}');
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
}
