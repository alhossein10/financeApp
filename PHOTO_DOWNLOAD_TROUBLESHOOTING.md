# Photo Download Troubleshooting Guide

**Issue**: "فشل في تحميل الصورة" (Failed to load image)

---

## Quick Diagnosis

Run these commands to diagnose the issue:

### 1. Check Database Paths
```bash
cd your-laravel-project
php artisan tinker
```

```php
// See what paths are stored
$expenses = DB::table('expenses')
    ->where('has_invoice', true)
    ->select('id', 'description', 'invoice_path', 'has_invoice')
    ->get();

foreach ($expenses as $expense) {
    echo "ID: {$expense->id} | Path: {$expense->invoice_path}\n";
}

exit
```

**Expected Output**:
```
ID: 1 | Path: public/invoices/abc123.jpg  ← GOOD (new format)
ID: 2 | Path: invoices/def456.jpg         ← BAD (old format, needs migration)
```

### 2. Check Files Exist
```bash
# Check new location
ls -la storage/app/public/invoices/

# Check old location
ls -la storage/app/invoices/
```

### 3. Check Symlink
```bash
ls -la public/storage

# Should show:
# storage -> ../storage/app/public
```

### 4. Test Download in Browser
```
http://192.168.137.1:8000/storage/invoices/FILENAME.jpg
```

Replace `FILENAME.jpg` with actual filename from step 1.

---

## Common Issues & Fixes

### Issue 1: Old Path Format in Database

**Symptom**: Database has `invoices/filename.jpg` instead of `public/invoices/filename.jpg`

**Fix**:
```bash
php artisan tinker
```

```php
// Update all old paths to new format
DB::table('expenses')
    ->where('invoice_path', 'like', 'invoices/%')
    ->where('invoice_path', 'not like', 'public/%')
    ->update([
        'invoice_path' => DB::raw("CONCAT('public/', invoice_path)")
    ]);

// Verify the update
DB::table('expenses')
    ->where('has_invoice', true)
    ->select('id', 'invoice_path')
    ->get();

exit
```

### Issue 2: Files in Wrong Location

**Symptom**: Files exist in `storage/app/invoices/` but not in `storage/app/public/invoices/`

**Fix**:
```bash
# Create directory if it doesn't exist
mkdir -p storage/app/public/invoices

# Copy files to new location
cp -r storage/app/invoices/* storage/app/public/invoices/

# Verify files copied
ls -la storage/app/public/invoices/
```

### Issue 3: Broken Symlink

**Symptom**: `public/storage` doesn't exist or points to wrong location

**Fix**:
```bash
# Remove old symlink if exists
rm -f public/storage

# Create new symlink
php artisan storage:link

# Verify
ls -la public/storage
# Should show: storage -> ../storage/app/public
```

### Issue 4: Wrong Permissions

**Symptom**: 403 Forbidden when accessing files

**Fix**:
```bash
# Fix permissions
chmod -R 775 storage/app/public/invoices
chmod -R 775 public/storage

# If using www-data user
chown -R www-data:www-data storage/app/public/invoices
chown -R www-data:www-data public/storage
```

### Issue 5: Laravel Not Serving Files

**Symptom**: 404 Not Found for `/storage/invoices/...`

**Fix**:

Check `.htaccess` or nginx config allows access to `/storage/` directory.

**Apache (.htaccess)**:
```apache
# Should already be there, but verify:
RewriteEngine On
RewriteCond %{REQUEST_FILENAME} !-d
RewriteCond %{REQUEST_FILENAME} !-f
RewriteRule ^ index.php [L]
```

**Nginx**:
```nginx
location /storage {
    alias /path/to/your/project/storage/app/public;
}
```

---

## Complete Fix Script

Run this script to fix everything at once:

```bash
#!/bin/bash

echo "=== Photo Download Fix Script ==="

# Step 1: Create directory
echo "Creating public/invoices directory..."
mkdir -p storage/app/public/invoices

# Step 2: Copy old files
echo "Copying old files..."
if [ -d "storage/app/invoices" ]; then
    cp -r storage/app/invoices/* storage/app/public/invoices/ 2>/dev/null || true
fi

# Step 3: Fix symlink
echo "Creating storage symlink..."
rm -f public/storage
php artisan storage:link

# Step 4: Fix permissions
echo "Fixing permissions..."
chmod -R 775 storage/app/public/invoices
chmod -R 775 public/storage

# Step 5: Update database
echo "Updating database paths..."
php artisan tinker <<EOF
DB::table('expenses')
    ->where('invoice_path', 'like', 'invoices/%')
    ->where('invoice_path', 'not like', 'public/%')
    ->update(['invoice_path' => DB::raw("CONCAT('public/', invoice_path)")]);
    
echo "Updated " . DB::table('expenses')->where('invoice_path', 'like', 'public/invoices/%')->count() . " records\n";
exit
EOF

echo "=== Fix Complete! ==="
echo ""
echo "Verification:"
echo "1. Check files: ls -la storage/app/public/invoices/"
echo "2. Check symlink: ls -la public/storage"
echo "3. Test in browser: http://192.168.137.1:8000/storage/invoices/FILENAME.jpg"
echo ""
```

Save as `fix_photo_download.sh` and run:
```bash
chmod +x fix_photo_download.sh
./fix_photo_download.sh
```

---

## Verification Steps

After applying fixes:

### 1. Backend Verification
```bash
# Check database
php artisan tinker
DB::table('expenses')->where('has_invoice', true)->select('id', 'invoice_path')->get();
exit

# Check files
ls -la storage/app/public/invoices/

# Check symlink
ls -la public/storage

# Test in browser
# Open: http://192.168.137.1:8000/storage/invoices/FILENAME.jpg
```

### 2. Frontend Verification
```bash
# Rebuild app
flutter clean
flutter pub get
flutter run --flavor admin --dart-define=FLAVOR=admin --dart-define=API_BASE_URL=http://192.168.137.1:8000
```

### 3. Test Flow
1. Open app
2. Go to expenses
3. See green checkmarks ✅
4. Click expense with photo
5. Click "View Invoice"
6. Photo should display ✅

---

## Still Not Working?

### Check Laravel Logs
```bash
tail -f storage/logs/lara