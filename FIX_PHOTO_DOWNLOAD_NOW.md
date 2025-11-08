# Fix Photo Download - Complete Guide

**Issue**: "فشل في تحميل الصورة" (Failed to load image)

---

## Step-by-Step Fix

### Step 1: Check What's in Database

```bash
cd your-laravel-project
php artisan tinker
```

```php
// Check paths
DB::table('expenses')
    ->where('has_invoice', true)
    ->select('id', 'description', 'invoice_path')
    ->get();
```

**Look at the output:**
- If you see `invoices/filename.jpg` → OLD FORMAT (needs fix)
- If you see `public/invoices/filename.jpg` → NEW FORMAT (correct)

Type `exit` to quit tinker.

---

### Step 2: Fix Database Paths (If Needed)

If you saw OLD FORMAT paths, run this:

```bash
php artisan tinker
```

```php
// Update old paths to new format
$updated = DB::table('expenses')
    ->where('invoice_path', 'like', 'invoices/%')
    ->where('invoice_path', 'not like', 'public/%')
    ->update([
        'invoice_path' => DB::raw("CONCAT('public/', invoice_path)")
    ]);

echo "Updated $updated records\n";

// Verify
DB::table('expenses')
    ->where('has_invoice', true)
    ->select('id', 'invoice_path')
    ->get();

exit
```

---

### Step 3: Move Files to Correct Location

```bash
# Create directory
mkdir -p storage/app/public/invoices

# Copy old files (if they exist)
if [ -d "storage/app/invoices" ]; then
    cp -r storage/app/invoices/* storage/app/public/invoices/
    echo "Files copied"
fi

# List files
ls -la storage/app/public/invoices/
```

---

### Step 4: Verify Symlink

```bash
# Check if symlink exists
ls -la public/storage

# If it doesn't exist or is broken, create it
rm -f public/storage
php artisan storage:link

# Verify again
ls -la public/storage
# Should show: storage -> ../storage/app/public
```

---

### Step 5: Test in Browser

1. Get a filename from Step 1 (e.g., `abc123.jpg`)
2. Open browser
3. Go to: `http://192.168.137.1:8000/storage/invoices/abc123.jpg`

**Expected**: Image displays  
**If 404**: Files not in correct location, repeat Step 3

---

### Step 6: Fix Permissions (If Needed)

```bash
chmod -R 775 storage/app/public/invoices
chmod -R 775 public/storage
```

---

### Step 7: Test in App

1. **Rebuild app**:
   ```bash
   flutter clean
   flutter pub get
   flutter run --flavor admin --dart-define=FLAVOR=admin --dart-define=API_BASE_URL=http://192.168.137.1:8000
   ```

2. **Test**:
   - Open expenses
   - See green checkmarks ✅
   - Click expense
   - Click "View Invoice"
   - Photo should display ✅

---

## Quick Fix Script

Save this as `fix_photos.sh`:

```bash
#!/bin/bash

echo "=== Fixing Photo Download ==="

# Step 1: Create directory
echo "1. Creating directory..."
mkdir -p storage/app/public/invoices

# Step 2: Copy files
echo "2. Copying files..."
if [ -d "storage/app/invoices" ]; then
    cp -r storage/app/invoices/* storage/app/public/invoices/ 2>/dev/null
    echo "   Files copied"
else
    echo "   No old files to copy"
fi

# Step 3: Fix symlink
echo "3. Creating symlink..."
rm -f public/storage
php artisan storage:link

# Step 4: Fix permissions
echo "4. Fixing permissions..."
chmod -R 775 storage/app/public/invoices 2>/dev/null
chmod -R 775 public/storage 2>/dev/null

# Step 5: Update database
echo "5. Updating database..."
php artisan tinker <<'EOF'
$updated = DB::table('expenses')
    ->where('invoice_path', 'like', 'invoices/%')
    ->where('invoice_path', 'not like', 'public/%')
    ->update(['invoice_path' => DB::raw("CONCAT('public/', invoice_path)")]);
echo "Updated $updated records\n";
exit
EOF

echo ""
echo "=== Fix Complete! ==="
echo ""
echo "Test in browser:"
echo "http://192.168.137.1:8000/storage/invoices/FILENAME.jpg"
echo ""
echo "Then rebuild Flutter app and test."
```

Run it:
```bash
chmod +x fix_photos.sh
./fix_photos.sh
```

---

## Verification

### Backend Check:
```bash
# 1. Files exist
ls -la storage/app/public/invoices/

# 2. Symlink works
ls -la public/storage/invoices/

# 3. Database correct
php artisan tinker
DB::table('expenses')->where('has_invoice', true)->pluck('invoice_path');
exit
```

### Browser Check:
```
http://192.168.137.1:8000/storage/invoices/FILENAME.jpg
```
Should display image.

### App Check:
1. Rebuild app
2. Open expenses
3. Click "View Invoice"
4. Should work ✅

---

## Still Not Working?

### Check Laravel Logs:
```bash
tail -f storage/logs/laravel.log
```

### Check App Logs:
Look for:
```
[FileUploadService] 📥 Server path: ...
[FileUploadService] 📥 Download URL: ...
[FileUploadService] ✅ Downloaded invoice to: ...
OR
[FileUploadService] ❌ Failed to download invoice: ...
```

### Common Issues:

**404 Not Found**:
- Files not in `storage/app/public/invoices/`
- Symlink broken
- Wrong filename

**403 Forbidden**:
- Permission issues
- Run: `chmod -R 775 storage/app/public/invoices`

**Connection Refused**:
- Backend not running
- Wrong API_BASE_URL
- Network issue

---

## Summary

1. ✅ Update database paths
2. ✅ Move files to public/invoices
3. ✅ Create symlink
4. ✅ Fix permissions
5. ✅ Test in browser
6. ✅ Rebuild app
7. ✅ Test in app

**That's it!** Photos should work now! 🎉
