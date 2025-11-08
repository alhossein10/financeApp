# Firebase Free Tier Implementation

## Overview

This implementation uses **Firestore only** (no Firebase Storage) to stay completely within Firebase's free tier. Invoice images are stored as compressed base64 strings directly in Firestore documents.

## Why This Approach?

### Firebase Storage Limitations
- ❌ Requires **Blaze (Pay-as-you-go) plan**
- ❌ No free tier for Storage
- ❌ Costs money even for small usage

### Firestore-Only Benefits
- ✅ **Completely FREE** within generous limits:
  - 1 GB storage
  - 50,000 reads/day
  - 20,000 writes/day
  - 20,000 deletes/day
- ✅ Simpler setup (one service instead of two)
- ✅ Simpler security rules
- ✅ No additional configuration needed
- ✅ Images and metadata in same document (atomic operations)

## How It Works

### Image Storage Process

1. **User captures/selects image**
   ```dart
   File imageFile = await ImagePicker().pickImage(...);
   ```

2. **Image is compressed**
   ```dart
   // Resize to max 1024px width
   // Compress to JPEG 75% quality
   // Result: ~200-500KB for typical invoice
   ```

3. **Convert to base64**
   ```dart
   String base64Image = base64Encode(compressedBytes);
   ```

4. **Store in Firestore document**
   ```dart
   await firestore.collection('expenses').doc(id).set({
     'description': 'Office supplies',
     'amount': 50.00,
     'invoice_image_base64': base64Image, // Stored here
     'user_id': userId,
     // ... other fields
   });
   ```

5. **Admin retrieves and displays**
   ```dart
   String base64 = doc.data()['invoice_image_base64'];
   Uint8List bytes = base64Decode(base64);
   Image.memory(bytes); // Display in UI
   ```

## Size Limitations

### Firestore Document Limits
- Maximum document size: **1 MB**
- Recommended image size: **500 KB** (compressed)
- Original image size: **~750 KB** (before compression)

### Image Compression Strategy

```dart
// Recommended compression settings
- Max width: 1024px (maintains readability)
- JPEG quality: 75% (good balance)
- Format: JPEG (better compression than PNG)
- Expected result: 200-500KB per image
```

### Typical Invoice Image Sizes

| Original Size | After Compression | Base64 Size | Fits in Firestore? |
|--------------|-------------------|-------------|-------------------|
| 2 MB (phone) | 400 KB | 533 KB | ✅ Yes |
| 5 MB (phone) | 450 KB | 600 KB | ✅ Yes |
| 10 MB (high-res) | 500 KB | 667 KB | ✅ Yes |
| 15 MB+ | 600 KB+ | 800 KB+ | ⚠️ May exceed limit |

## Implementation Details

### Compression Function

```dart
Future<Uint8List> compressImage(File imageFile) async {
  // Read image
  final bytes = await imageFile.readAsBytes();
  final image = img.decodeImage(bytes);
  
  if (image == null) throw Exception('Invalid image');
  
  // Resize if too large
  final resized = image.width > 1024
      ? img.copyResize(image, width: 1024)
      : image;
  
  // Compress to JPEG
  return Uint8List.fromList(
    img.encodeJpg(resized, quality: 75)
  );
}
```

### Firestore Document Structure

```json
{
  "expense_id": 123,
  "user_id": 456,
  "username": "john_doe",
  "user_email": "john@example.com",
  "description": "Office supplies",
  "price_usd": 50.00,
  "expense_date": 1704067200000,
  "created_at": 1704067200000,
  "synced_at": 1704067200000,
  "invoice_image_base64": "/9j/4AAQSkZJRgABAQEAYABgAAD...", // Base64 string
  "invoice_status": 1
}
```

## Free Tier Limits

### Firestore Free Tier (Spark Plan)

| Resource | Daily Limit | Monthly Equivalent |
|----------|-------------|-------------------|
| Stored data | 1 GB | 1 GB |
| Document reads | 50,000 | 1.5 million |
| Document writes | 20,000 | 600,000 |
| Document deletes | 20,000 | 600,000 |
| Network egress | 10 GB/month | 10 GB |

### Estimated Capacity

Assuming average image size of 400 KB per expense:

- **Storage**: 1 GB ÷ 400 KB = ~2,500 expenses with images
- **Writes**: 20,000/day = plenty for typical usage
- **Reads**: 50,000/day = plenty for typical usage

### Cost if Exceeding Free Tier

If you exceed limits, Firebase automatically upgrades to Blaze plan:

- Storage: $0.18/GB/month
- Reads: $0.06 per 100,000 documents
- Writes: $0.18 per 100,000 documents
- Network egress: $0.12/GB

**Example**: 5,000 expenses with images
- Storage: 2 GB × $0.18 = $0.36/month
- Very affordable even if exceeding free tier

## When to Upgrade to Firebase Storage

Consider upgrading to Firebase Storage if:

1. **Large images**: Need to store high-resolution images (>1 MB)
2. **Many images**: Storing thousands of images per month
3. **Video/documents**: Need to store non-image files
4. **CDN features**: Need global CDN distribution
5. **Advanced features**: Need image transformations, thumbnails, etc.

### Migration Path

If you need to upgrade later:

1. Enable Firebase Storage in console
2. Deploy storage security rules (already prepared in `firebase/storage.rules`)
3. Update code to use `FirebaseStorage` instead of base64
4. Optionally migrate existing base64 images to Storage
5. No changes needed to Firestore structure (just remove base64 field)

## Best Practices

### Image Optimization

1. **Compress before upload**
   - Always compress images client-side
   - Don't upload original high-res images

2. **Validate size**
   ```dart
   if (base64String.length > 1000000) { // ~750KB original
     throw Exception('Image too large');
   }
   ```

3. **Show compression progress**
   ```dart
   showDialog(
     context: context,
     builder: (_) => AlertDialog(
       content: Text('Compressing image...'),
     ),
   );
   ```

### Caching

1. **Cache decoded images**
   ```dart
   final _imageCache = <String, Uint8List>{};
   
   Uint8List getImage(String base64) {
     return _imageCache[base64] ??= base64Decode(base64);
   }
   ```

2. **Use Flutter's image cache**
   ```dart
   Image.memory(
     bytes,
     cacheWidth: 1024, // Limit memory usage
   );
   ```

### Error Handling

1. **Handle compression failures**
   ```dart
   try {
     final compressed = await compressImage(file);
   } catch (e) {
     // Show error to user
     // Offer to retry or skip image
   }
   ```

2. **Handle size limit errors**
   ```dart
   if (base64.length > 1000000) {
     showDialog(
       context: context,
       builder: (_) => AlertDialog(
         title: Text('Image Too Large'),
         content: Text('Please select a smaller image'),
       ),
     );
   }
   ```

## Security Considerations

### Firestore Security Rules

```javascript
// Validate image size in security rules
match /expenses/{expenseId} {
  allow create: if request.auth != null &&
                  // Limit base64 string to ~1MB
                  (!request.resource.data.keys().hasAny(['invoice_image_base64']) ||
                   request.resource.data.invoice_image_base64.size() < 1400000);
}
```

### Data Validation

1. **Validate base64 format**
   ```dart
   bool isValidBase64(String str) {
     try {
       base64Decode(str);
       return true;
     } catch (e) {
       return false;
     }
   }
   ```

2. **Validate image format**
   ```dart
   bool isValidImage(Uint8List bytes) {
     return img.decodeImage(bytes) != null;
   }
   ```

## Performance Considerations

### Read Performance

- **Firestore reads**: Fast (typically <100ms)
- **Base64 decode**: Fast (typically <50ms)
- **Image decode**: Moderate (100-300ms for large images)

### Write Performance

- **Image compress**: Moderate (200-500ms)
- **Base64 encode**: Fast (typically <50ms)
- **Firestore write**: Fast (typically <200ms)

### Optimization Tips

1. **Lazy load images**
   ```dart
   // Don't load all images at once
   // Load as user scrolls
   ```

2. **Use thumbnails for lists**
   ```dart
   // Store small thumbnail separately
   // Load full image only when viewing details
   ```

3. **Compress in background**
   ```dart
   // Use compute() for heavy compression
   await compute(compressImage, imageFile);
   ```

## Monitoring Usage

### Check Firestore Usage

1. Go to Firebase Console
2. Navigate to Firestore Database
3. Click "Usage" tab
4. Monitor:
   - Document reads/writes
   - Storage usage
   - Network egress

### Set Up Alerts

1. Go to Firebase Console
2. Navigate to Project Settings → Usage and billing
3. Set up budget alerts
4. Get notified before exceeding free tier

## Conclusion

This Firestore-only approach provides:

- ✅ **Zero cost** for typical usage
- ✅ **Simple setup** (no Storage configuration)
- ✅ **Good performance** for invoice-sized images
- ✅ **Easy migration path** if needs grow

Perfect for:
- Small to medium businesses
- Personal finance tracking
- Proof of concept / MVP
- Budget-conscious projects

The free tier limits are generous enough for most use cases, and the cost is minimal even if you exceed them.
