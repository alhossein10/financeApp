# 🔧 Photo URL Fix

## The Problem
Photos were uploading but failing to display with "Failed to load image from server".

## Root Cause
Laravel stores files in `storage/app/public/invoices/` but returns the path as `public/invoices/file.jpg`. To access these files via HTTP, Laravel needs a symbolic link.

## Solution Applied

### 1. Frontend Fix (lib/ui/expense_page.dart)
Updated the image URL construction to convert Laravel storage paths:
- Backend returns: `public/invoices/file.jpg`
- Frontend converts to: `storage/invoices/file.jpg`
- Final URL: `http://192.168.137.1:8000/storage/invoices/file.jpg`

### 2. Backend Setup Required
Run this command in your Laravel backend directory:

```bash
cd financeApp-backend-main
php artisan storage:link
```

This creates a symbolic link from `public/storage` → `storage/app/public`, allowing files to be accessed via HTTP.

## Testing

1. **Check if storage link exists:**
   ```bash
   cd financeApp-backend-main/public
   ls -la
   # You should see: storage -> ../storage/app/public
   ```

2. **If link doesn't exist, create it:**
   ```bash
   cd financeApp-backend-main
   php artisan storage:link
   ```

3. **Test in the app:**
   - Hot restart the Flutter app
   - Create a new expense with a photo
   - Click "View Invoice"
   - Photo should now load successfully

## URL Structure

**Storage Path (what backend returns):**
```
public/invoices/NtkXsfgkmPmhwBjNk54TODNLyiHfZQtHGQB1uvfL.jpg
```

**Public URL (what frontend uses):**
```
http://192.168.137.1:8000/storage/invoices/NtkXsfgkmPmhwBjNk54TODNLyiHfZQtHGQB1uvfL.jpg
```

## Alternative: Direct Public Storage

If you can't create symlinks (Windows permissions, etc.), you can modify the backend to store files directly in the `public` folder:

1. Edit `financeApp-backend-main/app/Services/FileStorageService.php`
2. Change the disk from `local` to `public`
3. Files will be stored in `public/invoices/` and accessible directly

But the symlink approach is the Laravel standard and more secure.
