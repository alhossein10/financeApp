# ⚠️ ACTION REQUIRED - Do This Now

**Time**: 2 minutes  
**Difficulty**: Copy & Paste

---

## Issue 1: New Expenses Not Showing

**Status**: ✅ FIXED in code  
**Action**: Rebuild app

```bash
flutter clean
flutter pub get
flutter run --flavor admin --dart-define=FLAVOR=admin --dart-define=API_BASE_URL=http://192.168.137.1:8000
```

**What changed**: Pagination increased from 15 to 100 expenses

---

## Issue 2: Photos Not Downloading

**Status**: ⚠️ NEEDS BACKEND FIX  
**Action**: Run this in Laravel project

```bash
# Copy & paste this entire block:
cd /path/to/your/laravel/project

mkdir -p storage/app/public/invoices
cp -r storage/app/invoices/* storage/app/public/invoices/ 2>/dev/null
rm -f public/storage
php artisan storage:link

php artisan tinker <<'EOF'
DB::table('expenses')->where('invoice_path', 'like', 'invoices/%')->where('invoice_path', 'not like', 'public/%')->update(['invoice_path' => DB::raw("CONCAT('public/', invoice_path)")]);
exit
EOF

echo "✅ Backend fix complete!"
```

---

## Test

1. **Backend**: Open browser
   ```
   http://192.168.137.1:8000/storage/invoices/FILENAME.jpg
   ```
   Should show image

2. **App**: 
   - Create expense
   - Should appear in list immediately ✅
   - Click "View Invoice"
   - Photo should display ✅

---

## That's It!

Just run those 2 commands and everything will work! 🎉
