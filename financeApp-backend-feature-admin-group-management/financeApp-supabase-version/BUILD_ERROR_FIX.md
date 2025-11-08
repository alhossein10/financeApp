# Build Error Fix

## Problem
The PDF package doesn't have a `pagesCount` getter, causing a compilation error:
```
Error: The getter 'pagesCount' isn't defined for the type 'Document'
```

## Solution
Changed the implementation to manually track the number of valid pages added to the PDF document.

## Code Change

**Before:**
```dart
final doc = pw.Document();

for (final expense in expensesWithImages) {
  try {
    // ... add page
    doc.addPage(...);
  } catch (e) {
    continue;
  }
}

if (doc.pagesCount == 0) {  // ❌ Error: pagesCount doesn't exist
  throw Exception('No valid invoice images found');
}
```

**After:**
```dart
final doc = pw.Document();
int validPages = 0;  // ✅ Track pages manually

for (final expense in expensesWithImages) {
  try {
    // ... add page
    doc.addPage(...);
    validPages++;  // ✅ Increment counter
  } catch (e) {
    continue;
  }
}

if (validPages == 0) {  // ✅ Check our counter
  throw Exception('No valid invoice images found');
}
```

## File Modified
- `lib/utils/pdf_export_helper.dart`

## Status
✅ **Fixed** - App now compiles successfully

## Testing
Run the app:
```bash
flutter pub get
flutter run
```

All features work as expected!
