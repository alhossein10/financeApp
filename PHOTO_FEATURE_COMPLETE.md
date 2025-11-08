# ✅ Photo Feature - Status & Remaining Issues

## What's Working ✅

1. **Photo Upload**: Photos upload successfully to the backend
2. **Photo Display**: "View Invoice" button works perfectly using the API endpoint
3. **Authentication**: Bearer token is properly included in requests
4. **Security**: Photos are accessed through authenticated API endpoint

## Remaining Issues 🔧

### Issue 1: Export Invoices Fails
**Problem**: When clicking "Export Invoices", it throws "No invoice images found"

**Root Cause**: The `PdfExportHelper.exportInvoiceImages()` method expects local file paths, but we're now storing server paths like `public/invoices/file.jpg`.

**Solution Options**:

**Option A: Download photos before export** (Recommended)
- Modify `exportInvoiceImages` to download photos from API first
- Cache them temporarily
- Then create the PDF

**Option B: Disable invoice export temporarily**
- Hide the "Export Invoices" button until we implement download logic
- Keep other export functions working

### Issue 2: Photos Disappear When Navigating Back
**Problem**: After viewing an expense photo and going to export page, when you return to expenses, the photos are gone (invoice status shows "No Invoice").

**Possible Causes**:
1. Backend not returning `has_invoice=true` in the expense list
2. DTO mapping issue - `invoicePath` not being mapped correctly
3. Cache being cleared incorrectly

**Debug Steps**:
1. Check API response when loading expenses
2. Verify `has_invoice` field in response
3. Check if `invoice_path` is included
4. Verify DTO mapping

## Quick Fixes

### Fix 1: Verify Backend Response

Add logging to see what the API returns:

```dart
// In expense_repository_impl.dart, getExpensesByUser method
print('[ExpenseRepository] API response: ${response.data.length} expenses');
for (var dto in response.data) {
  if (dto.hasInvoice) {
    print('[ExpenseRepository] Expense ${dto.id}: has_invoice=${dto.hasInvoice}, path=${dto.invoicePath}');
  }
}
```

### Fix 2: Disable Export Invoices Temporarily

In `lib/ui/export_page.dart`:

```dart
// Comment out or hide the export invoices button
// FilledButton.icon(
//   onPressed: _busy ? null : _exportInvoiceImages,
//   icon: const Icon(Icons.image),
//   label: Text(l10n.translate('export_invoices')),
// ),
```

### Fix 3: Check Backend Expense List Endpoint

Verify the backend returns invoice info:

```bash
curl -X GET "http://192.168.137.1:8000/api/v1/expenses" \
  -H "Authorization: Bearer YOUR_TOKEN" | jq '.data[] | {id, description, has_invoice, invoice_path}'
```

Expected output:
```json
{
  "id": 22,
  "description": "صورة ١٩",
  "has_invoice": true,
  "invoice_path": "public/invoices/NtkXsfgkmPmhwBjNk54TODNLyiHfZQtHGQB1uvfL.jpg"
}
```

## Implementation Plan

### Phase 1: Fix Photos Disappearing (Priority: HIGH)
1. Add debug logging to expense repository
2. Verify backend returns correct data
3. Check DTO mapping
4. Fix any caching issues

### Phase 2: Fix Export Invoices (Priority: MEDIUM)
1. Create a method to download invoice via API
2. Cache downloaded images temporarily
3. Update `exportInvoiceImages` to use cached files
4. Clean up temp files after export

## Code Changes Needed

### For Export Fix:

```dart
// In pdf_export_helper.dart
static Future<void> exportInvoiceImages(List<ExpenseRecord> expenses) async {
  // Filter expenses with invoices
  final expensesWithImages = expenses.where((e) => 
    e.invoiceStatus == InvoiceStatus.invoiceAvailable
  ).toList();

  if (expensesWithImages.isEmpty) {
    throw Exception('No invoice images found');
  }

  final doc = pw.Document();
  final tempDir = await getTemporaryDirectory();
  
  for (final expense in expensesWithImages) {
    try {
      // Download invoice from API
      final imageUrl = '${ApiConfig.apiUrl}/expenses/${expense.id}/invoice';
      final response = await dio.get(
        imageUrl,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          responseType: ResponseType.bytes,
        ),
      );
      
      final image = pw.MemoryImage(response.data);
      
      // Add page to PDF
      doc.addPage(/* ... */);
    } catch (e) {
      continue;
    }
  }
  
  // Save and open PDF
  // ...
}
```

## Testing Checklist

- [ ] Upload expense with photo
- [ ] Verify photo appears in expense list
- [ ] Click "View Invoice" - should display
- [ ] Navigate to another page
- [ ] Come back to expenses
- [ ] Verify photo still shows (invoice icon visible)
- [ ] Try export (should either work or show proper error)

## Summary

**Working**: Photo upload and display via API endpoint ✅  
**Broken**: Export invoices, photos disappear on navigation ❌  
**Next Step**: Add debug logging to find why photos disappear
