# Debug Photo Download Issue

## Problem
- Checkmarks show initially ✅
- Click "View Invoice" → "فشل في تحميل الصورة" (Failed to load image)
- Export fails with same error
- Checkmarks disappear after failed download

## Root Cause
The app is trying to download but the URL is wrong. Need to check:

1. **What path is in database?**
   - Old format: `invoices/filename.jpg`
   - New format: `public/invoices/filename.jpg`

2. **What URL is app trying?**
   - Should be: `http://192.168.137.1:8000/storage/invoices/filename.jpg`

3. **Is file accessible?**
   - Test in browser: `http://192.168.137.1:8000/storage/invoices/FILENAME.jpg`

## Debug Steps

### Step 1: Check Database
```bash
# In Laravel project
php artisan tinker
```

```php
// Check what paths are stored
DB::table('expenses')
    ->where('has_invoice', true)
    ->select('id', 'invoice_path', 'has_invoice')
    ->get();

// Should show paths like:
// "public/invoices/abc123.jpg" (NEW - correct)
// OR
// "invoices/abc123.jpg" (OLD - needs migration)
```

### Step 2: Check File Exists
```bash
# Check if files exist in new location
ls -la storage/app/public/invoices/

# Check if symlink works
ls -la public/storage/invoices/
```

### Step 3: Test Download in Browser
Open browser and try:
```
http://192.168.137.1:8000/storage/invoices/FILENAME.jpg
```

Replace `FILENAME.jpg` with actual filename from database.

**Expected**: Image displays  
**If 404**: File not in correct location or symlink broken

### Step 4: Check App Logs
Look for these in Flutter console:
```
[FileUploadService] 📥 Downloading from: /storage/invoices/...
[FileUploadService] ✅ Downloaded invoice to: ...
OR
[FileUploadService] ❌ Failed to download invoice: ...
```

## Quick Fixes

### Fix 1: Migrate Old Data
If database has old paths (`invoices/...`):

```bash
php artisan tinker
```

```php
// Update paths
DB::table('expenses')
    ->where('invoice_path', 'like', 'invoices/%')
    ->whereNotLike('invoice_path', 'public/%')
    ->update([
        'invoice_path' => DB::raw("CONCAT('public/', invoice_path)")
    ]);

// Verify
DB::table('expenses')
    ->where('has_invoice', true)
    ->select('id', 'invoice_path')
    ->get();
```

### Fix 2: Move Old Files
If files are in old location:

```bash
# Copy old files to new location
mkdir -p storage/app/public/invoices
cp -r storage/app/invoices/* storage/app/public/invoices/
```

### Fix 3: Verify Symlink
```bash
# Check symlink
ls -la public/storage

# If broken, recreate
rm public/storage
php artisan storage:link
```

## Test Again

After fixes:

1. **Restart Laravel** (if using php artisan serve)
2. **Clear app cache** in Flutter app
3. **Reload expenses**
4. **Try viewing photo**

Should work now! ✅
