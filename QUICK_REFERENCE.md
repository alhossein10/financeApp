# Quick Reference Card

## 🔧 Fixes Applied

✅ **Profile Page Error** - Fixed database column name issue  
✅ **Logout Error** - Fixed "unauthorized access" error  
✅ **PocketBase Setup Guide** - Complete Windows server setup instructions

## 🚀 Quick Start

### 1. Rebuild App
```bash
flutter clean
flutter pub get
flutter run --flavor admin -t lib/main_admin.dart
```

### 2. Test Fixes
- Open Profile → Should load without error
- Click Logout → Should work immediately
- Log back in → Should work normally

## 🖥️ Setup PocketBase Server (5 Minutes)

### Download & Start
1. Download: https://pocketbase.io/docs/ (Windows version)
2. Extract to `C:\pocketbase`
3. Open Command Prompt:
   ```cmd
   cd C:\pocketbase
   pocketbase serve --http="0.0.0.0:8090"
   ```

### Find Your IP
```cmd
ipconfig
```
Look for "IPv4 Address" (e.g., `192.168.1.100`)

### Configure Firewall
1. Windows Defender Firewall
2. "Allow an app through firewall"
3. Add `pocketbase.exe`
4. Check Private and Public

### Setup Admin
1. Browser: `http://localhost:8090/_/`
2. Create admin account
3. Settings → Import collections
4. Upload: `pocketbase-backend-files/pb_schema.json`

**If import fails**: See `POCKETBASE_FRESH_START.md` for fresh start guide

### Update App
Edit `lib/core/config/pocketbase_config.dart`:
```dart
static const String baseUrl = 'http://192.168.1.100:8090'; // YOUR IP
```

### Rebuild & Test
```bash
flutter clean && flutter pub get
flutter run --flavor admin -t lib/main_admin.dart
```

## 📱 Test Connection

### From Computer
```
http://localhost:8090/api/health
```
Should show: `{"code":200,"message":"API is healthy"}`

### From Phone
```
http://YOUR_IP:8090/api/health
```
Should show same message

## 🔍 Troubleshooting

### Profile Still Shows Error
```bash
# Clear app data and reinstall
flutter clean
flutter pub get
flutter run
```

### Logout Still Shows Error
- Clear app data
- Uninstall and reinstall app
- Check you're using latest code

### Can't Connect to PocketBase
1. Check firewall allows port 8090
2. Verify phone and computer on same WiFi
3. Try disabling firewall temporarily
4. Check IP address is correct

### PocketBase Won't Start
```cmd
# Check if port is in use
netstat -ano | findstr :8090

# Kill process if needed
taskkill /PID <PID> /F
```

## 📚 Documentation

- **FIXES_SUMMARY.md** - What was fixed and why
- **SETUP_LOCAL_POCKETBASE_SERVER.md** - Detailed PocketBase setup
- **DATABASE_AND_AUTH_FIXES.md** - Technical details
- **DEPLOYMENT_GUIDE.md** - Cloud deployment guide
- **README.md** - Build instructions

## 🎯 Common Commands

### Start PocketBase
```cmd
cd C:\pocketbase
pocketbase serve --http="0.0.0.0:8090"
```

### Build Admin Version
```bash
flutter build apk --flavor admin -t lib/main_admin.dart
```

### Build User Version
```bash
flutter build apk --flavor user -t lib/main_user.dart
```

### Run Tests
```bash
flutter test
```

### Clear Database (Admin Only)
1. Log in as admin
2. Profile → Database Management
3. Clear All Data

## 🔐 Default Credentials

**After Database Clear**:
- Email: `default@finance.app`
- Password: `password`
- Role: Regular user (0)

**To Make Admin**:
Update role to 1 in database or PocketBase

## ⚡ Quick Checks

### Is PocketBase Running?
```cmd
curl http://localhost:8090/api/health
```

### What's My IP?
```cmd
ipconfig | findstr IPv4
```

### Is Port Open?
```cmd
netstat -an | findstr :8090
```

### Check Firewall
```cmd
netsh advfirewall firewall show rule name=all | findstr 8090
```

## 🎨 App Features

### Admin Version
- ✅ All modules (Cash, Cashbox, Currency, Expenses, Export)
- ✅ Admin Dashboard
- ✅ View all user data
- ✅ Database Management

### User Version
- ✅ Limited modules (Currency, Expenses, Export)
- ✅ Auto-sync to Admin
- ✅ Offline support

## 🌐 Network Setup

### Local Development
```dart
// lib/core/config/pocketbase_config.dart
static const String baseUrl = 'http://192.168.1.100:8090';
```

### Android Emulator
```dart
static const String baseUrl = 'http://10.0.2.2:8090';
```

### Production
```dart
static const String baseUrl = 'https://your-domain.com';
```

## 💡 Tips

1. **Keep PocketBase Running**: Don't close Command Prompt window
2. **Same WiFi**: Phone and computer must be on same network
3. **Firewall**: Allow PocketBase through Windows Firewall
4. **IP Changes**: If IP changes, update app config and rebuild
5. **Offline Works**: App works without PocketBase, syncs when available

## 🆘 Need Help?

1. Check error message in app
2. Check PocketBase logs in Command Prompt
3. Review documentation files
4. Test connection from phone browser first
5. Verify firewall settings

## ✅ Success Indicators

- [ ] Profile page loads
- [ ] Logout works immediately
- [ ] Can access PocketBase Admin UI
- [ ] Phone can reach PocketBase API
- [ ] Expenses sync to PocketBase
- [ ] Sync status shows "Synced"
- [ ] Images upload successfully

## 🎉 You're Done!

Once all checks pass:
1. App is fully functional
2. PocketBase is connected
3. Data syncs automatically
4. Ready for testing/development

For production deployment, see **DEPLOYMENT_GUIDE.md**
