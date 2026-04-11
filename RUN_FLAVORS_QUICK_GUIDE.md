# Quick Guide: Run All Flavors with Custom API Host

**API Host:** `192.168.137.1:8000`

## Quick Commands

### 1. User Flavor
```bash
flutter run --flavor user --dart-define=API_BASE_URL=http://192.168.137.1:8000 --dart-define=ENVIRONMENT=development --dart-define=DEBUG_LOGGING=true
```

### 2. Admin Flavor
```bash
flutter run --flavor admin --dart-define=API_BASE_URL=http://192.168.137.1:8000 --dart-define=ENVIRONMENT=development --dart-define=DEBUG_LOGGING=true
```

### 3. SuperAdmin Flavor
```bash
flutter run --flavor superAdmin --dart-define=API_BASE_URL=http://192.168.137.1:8000 --dart-define=ENVIRONMENT=development --dart-define=DEBUG_LOGGING=true
```

## Using the Batch Script

**Windows:**
```bash
run_all_flavors_test.bat
```

Then select:
- `1` for User flavor
- `2` for Admin flavor
- `3` for SuperAdmin flavor
- `4` to run all sequentially

## Testing Specific Device

### Run on specific device:
```bash
# List devices
flutter devices

# Run on specific device (replace DEVICE_ID)
flutter run --flavor user --dart-define=API_BASE_URL=http://192.168.137.1:8000 -d DEVICE_ID
```

### Run on Chrome (Web):
```bash
flutter run --flavor user --dart-define=API_BASE_URL=http://192.168.137.1:8000 -d chrome
```

### Run on Android Emulator:
```bash
flutter run --flavor user --dart-define=API_BASE_URL=http://192.168.137.1:8000 -d emulator-5554
```

## Build APKs for Testing

### User APK:
```bash
flutter build apk --flavor user --dart-define=API_BASE_URL=http://192.168.137.1:8000 --dart-define=ENVIRONMENT=development
```

### Admin APK:
```bash
flutter build apk --flavor admin --dart-define=API_BASE_URL=http://192.168.137.1:8000 --dart-define=ENVIRONMENT=development
```

### SuperAdmin APK:
```bash
flutter build apk --flavor superAdmin --dart-define=API_BASE_URL=http://192.168.137.1:8000 --dart-define=ENVIRONMENT=development
```

## Testing Checklist

### User Flavor Tests:
- [ ] Register new user
- [ ] Login
- [ ] View fund box (USD, SYP, TRY)
- [ ] Create expense in USD
- [ ] Create expense in SYP
- [ ] Create expense in TRY
- [ ] Upload invoice photo
- [ ] Create exchange (USD → SYP)
- [ ] Create exchange (USD → TRY)
- [ ] View exchange history
- [ ] Join admin group (use group code)
- [ ] Export expenses to PDF
- [ ] Export expenses to Excel

### Admin Flavor Tests:
- [ ] Register admin with SuperAdmin group code
- [ ] Login
- [ ] View dashboard stats
- [ ] View group members
- [ ] Transfer funds to user
- [ ] View user fund boxes
- [ ] View group expenses
- [ ] Regenerate group code
- [ ] Remove group member
- [ ] View audit logs
- [ ] Export system-wide data

### SuperAdmin Flavor Tests:
- [ ] Register SuperAdmin (creates group)
- [ ] Login
- [ ] View analytics (15 days, month, all)
- [ ] View SuperAdmin group info
- [ ] View admin members
- [ ] Transfer funds to admin
- [ ] View admin fund boxes
- [ ] Regenerate SuperAdmin group code
- [ ] Remove admin from group
- [ ] View aggregated expenses by admin group

## Troubleshooting

### Cannot connect to API:
1. Check if Laravel backend is running on `192.168.137.1:8000`
2. Verify firewall allows connections
3. Test API manually: `curl http://192.168.137.1:8000/api/v1/organizations`

### Wrong API URL:
Check the app logs for the actual API URL being used:
```
flutter run --flavor user --dart-define=API_BASE_URL=http://192.168.137.1:8000 --dart-define=DEBUG_LOGGING=true
```

Look for log output showing API configuration.

### Device cannot reach host:
- Ensure device and host are on same network
- For Android emulator, use `10.0.2.2` instead of `192.168.137.1`
- For iOS simulator, use `localhost` or actual IP

### Android Emulator Special Case:
```bash
# Use 10.0.2.2 for Android emulator (maps to host's localhost)
flutter run --flavor user --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

## Environment Variables Explained

| Variable | Value | Purpose |
|----------|-------|---------|
| `API_BASE_URL` | `http://192.168.137.1:8000` | Backend API host |
| `ENVIRONMENT` | `development` | Environment mode |
| `DEBUG_LOGGING` | `true` | Enable detailed logs |

## Quick Test Flow

### 1. Start Backend:
```bash
# On your Laravel backend server
php artisan serve --host=192.168.137.1 --port=8000
```

### 2. Run User Flavor:
```bash
run_all_flavors_test.bat
# Select option 1
```

### 3. Test Registration:
- Open app
- Register as User
- Check backend logs for API calls

### 4. Test Admin Flavor:
```bash
run_all_flavors_test.bat
# Select option 2
```

### 5. Test SuperAdmin Flavor:
```bash
run_all_flavors_test.bat
# Select option 3
```

## Production Testing

For production testing with different host:
```bash
# Replace with your production host
flutter run --flavor user --dart-define=API_BASE_URL=https://your-production-api.com --dart-define=ENVIRONMENT=production
```

## Notes

- All commands include `DEBUG_LOGGING=true` for detailed logs
- API calls will show in console with request/response details
- Bearer token authentication is automatic
- Multi-currency support (USD, SYP, TRY) is enabled
- All 66 Postman endpoints are implemented

## Support

If you encounter issues:
1. Check `RUN_FLAVORS_QUICK_GUIDE.md` (this file)
2. Review `TROUBLESHOOTING.md`
3. Check API logs on backend
4. Verify network connectivity
5. Test with Postman first

---

**Created:** 2025-11-16  
**API Host:** 192.168.137.1:8000  
**Flavors:** User, Admin, SuperAdmin
