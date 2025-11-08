# File Upload Service - Usage Guide

## Overview
The File Upload Service provides a complete solution for uploading, downloading, and managing files in the finance app. It supports receipts, invoices, and documents with automatic image compression and progress tracking.

## Quick Start

### 1. Upload a File

```dart
import 'package:finance_app/core/services/file_upload_service.dart';
import 'package:finance_app/core/models/file_upload_dto.dart';

// Get the service (usually via dependency injection)
final fileUploadService = getIt<FileUploadService>();

// Upload a receipt
final file = File('/path/to/receipt.jpg');
final result = await fileUploadService.uploadFile(
  file: file,
  type: FileType.receipt,
  onProgress: (progress) {
    print('Upload: ${(progress * 100).toInt()}%');
  },
);

print('Uploaded: ${result.filename}');
print('File ID: ${result.id}');
print('Encrypted Path: ${result.path}');
```

### 2. Download a File

```dart
// Download using the encrypted path from upload response
final downloadedFile = await fileUploadService.downloadFile(
  result.path,
  onProgress: (progress) {
    print('Download: ${(progress * 100).toInt()}%');
  },
);

print('Downloaded to: ${downloadedFile.path}');
```

### 3. Delete a File

```dart
// Delete using the path from upload response
await fileUploadService.deleteFile(result.path);
print('File deleted successfully');
```

## File Types

The service supports three file types:

```dart
enum FileType {
  receipt,   // For expense receipts
  invoice,   // For invoices
  document,  // For general documents
}
```

## Using the Upload Widget

### Basic Usage

```dart
import 'package:finance_app/core/widgets/file_upload_widget.dart';

FileUploadWidget(
  fileType: FileType.receipt,
  label: 'Upload Receipt',
  onFileUploaded: (FileUploadDto file) {
    // Handle successful upload
    print('Uploaded: ${file.filename}');
  },
  onError: (String error) {
    // Handle error
    print('Error: $error');
  },
)
```

### Customized Upload Options

```dart
FileUploadWidget(
  fileType: FileType.document,
  label: 'Upload Document',
  allowCamera: true,      // Enable camera capture
  allowGallery: true,     // Enable gallery selection
  allowDocuments: true,   // Enable document picker
  onFileUploaded: (file) {
    // Save file reference
    setState(() {
      _uploadedFile = file;
    });
  },
)
```

## Using the File Manager Widget

```dart
import 'package:finance_app/core/widgets/file_manager_widget.dart';

FileManagerWidget(
  files: uploadedFiles,  // List<FileUploadDto>
  fileUploadService: fileUploadService,
  onFileDeleted: (FileUploadDto file) {
    // Handle file deletion
    setState(() {
      uploadedFiles.remove(file);
    });
  },
  onError: (String error) {
    // Handle error
    print('Error: $error');
  },
)
```

## Complete Example: Expense with Receipt

```dart
class ExpenseFormPage extends StatefulWidget {
  @override
  _ExpenseFormPageState createState() => _ExpenseFormPageState();
}

class _ExpenseFormPageState extends State<ExpenseFormPage> {
  FileUploadDto? _receipt;
  final _fileUploadService = getIt<FileUploadService>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('New Expense')),
      body: Column(
        children: [
          // Expense form fields...
          
          // Receipt upload section
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Receipt', style: Theme.of(context).textTheme.titleMedium),
                  SizedBox(height: 8),
                  
                  if (_receipt == null)
                    FileUploadWidget(
                      fileType: FileType.receipt,
                      onFileUploaded: (file) {
                        setState(() {
                          _receipt = file;
                        });
                      },
                    )
                  else
                    _buildReceiptCard(),
                ],
              ),
            ),
          ),
          
          // Save button...
        ],
      ),
    );
  }

  Widget _buildReceiptCard() {
    return Card(
      child: ListTile(
        leading: Icon(Icons.receipt),
        title: Text(_receipt!.filename),
        subtitle: Text(_formatFileSize(_receipt!.size)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.download),
              onPressed: _downloadReceipt,
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: _deleteReceipt,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadReceipt() async {
    try {
      final file = await _fileUploadService.downloadFile(_receipt!.path);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Downloaded to: ${file.path}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Download failed: $e')),
      );
    }
  }

  Future<void> _deleteReceipt() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Receipt'),
        content: Text('Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _fileUploadService.deleteFile(_receipt!.path);
        setState(() {
          _receipt = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Receipt deleted')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: $e')),
        );
      }
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
```

## Image Compression

The service automatically compresses images larger than 2MB:

```dart
// Compression happens automatically
final result = await fileUploadService.uploadFile(
  file: largeImageFile,  // 5MB image
  type: FileType.receipt,
);
// Image is compressed to < 2MB before upload
```

### Manual Compression

```dart
// Compress with custom quality
final compressedFile = await fileUploadService.compressImage(
  originalFile,
  quality: 70,  // 0-100, default is 85
);
```

## Error Handling

```dart
try {
  final result = await fileUploadService.uploadFile(
    file: file,
    type: FileType.receipt,
  );
  // Success
} on ApiException catch (e) {
  if (e.statusCode == 401) {
    // Unauthorized - redirect to login
  } else if (e.statusCode == 413) {
    // File too large
    print('File is too large');
  } else {
    // Other error
    print('Upload failed: ${e.message}');
  }
} catch (e) {
  // Generic error
  print('Unexpected error: $e');
}
```

## Progress Tracking

### Upload Progress

```dart
double _uploadProgress = 0.0;

await fileUploadService.uploadFile(
  file: file,
  type: FileType.receipt,
  onProgress: (progress) {
    setState(() {
      _uploadProgress = progress;
    });
  },
);

// In your UI:
LinearProgressIndicator(value: _uploadProgress)
```

### Download Progress

```dart
double _downloadProgress = 0.0;

await fileUploadService.downloadFile(
  encryptedPath,
  onProgress: (progress) {
    setState(() {
      _downloadProgress = progress;
    });
  },
);
```

## Best Practices

### 1. Store File References
```dart
// Store the encrypted path and file ID in your expense model
class Expense {
  final int id;
  final String description;
  final double amount;
  final String? receiptPath;  // Store encrypted path
  final int? receiptFileId;   // Store file ID
}
```

### 2. Handle Cleanup
```dart
// Delete file when expense is deleted
Future<void> deleteExpense(Expense expense) async {
  if (expense.receiptPath != null) {
    await fileUploadService.deleteFile(expense.receiptPath!);
  }
  await expenseRepository.delete(expense.id);
}
```

### 3. Validate Before Upload
```dart
Future<bool> validateFile(File file) async {
  // Check file size
  final size = await file.length();
  if (size > 10 * 1024 * 1024) {  // 10MB
    return false;
  }
  
  // Check file extension
  final extension = file.path.split('.').last.toLowerCase();
  if (!['jpg', 'jpeg', 'png', 'pdf'].contains(extension)) {
    return false;
  }
  
  return true;
}
```

### 4. Show User Feedback
```dart
// Show loading indicator during upload
showDialog(
  context: context,
  barrierDismissible: false,
  builder: (context) => AlertDialog(
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 16),
        Text('Uploading...'),
      ],
    ),
  ),
);

try {
  final result = await fileUploadService.uploadFile(
    file: file,
    type: FileType.receipt,
  );
  Navigator.pop(context);  // Close loading dialog
  // Show success message
} catch (e) {
  Navigator.pop(context);  // Close loading dialog
  // Show error message
}
```

## API Response Format

### Upload Response
```json
{
  "success": true,
  "data": {
    "id": 1,
    "filename": "receipt_20241023.jpg",
    "path": "encrypted_path_string",
    "type": "receipt",
    "size": 245678,
    "mime_type": "image/jpeg",
    "uploaded_at": "2024-10-23T10:00:00.000000Z"
  }
}
```

### Delete Response
```json
{
  "success": true,
  "message": "File deleted successfully"
}
```

## Troubleshooting

### Upload Fails with 413 Error
- File is too large (server limit exceeded)
- Solution: Compress image or reduce file size

### Upload Fails with 401 Error
- Authentication token expired
- Solution: Re-authenticate user

### Download Fails with 404 Error
- File not found or already deleted
- Solution: Check if file still exists

### Compression Takes Too Long
- Image is very large
- Solution: Show progress indicator to user

## Migration from Old API

If you're using the deprecated methods:

```dart
// Old way (deprecated)
final path = await fileUploadService.uploadInvoice(file, expenseId: 123);

// New way
final result = await fileUploadService.uploadFile(
  file: file,
  type: FileType.invoice,
);
final path = result.path;
final fileId = result.id;  // Now you have the file ID too!
```

## Related Documentation

- [API Documentation](../../../financeApp-backend-main/API_DOCUMENTATION.md)
- [Error Handling Guide](../api/ERROR_CODES.md)
- [Service Usage Examples](../USAGE_EXAMPLES.md)
