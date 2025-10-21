# Setup Your Computer as PocketBase Server

This guide will help you set up your Windows computer as a PocketBase server that your mobile app can connect to.

## Prerequisites

- Windows computer
- PocketBase executable
- Your computer and mobile device on the same network (WiFi)

## Step 1: Download PocketBase

1. Go to https://pocketbase.io/docs/
2. Download **PocketBase for Windows** (pocketbase_windows_amd64.zip)
3. Extract the ZIP file to a folder, for example: `C:\pocketbase`

## Step 2: Find Your Computer's IP Address

### Method 1: Using Command Prompt
1. Press `Win + R`
2. Type `cmd` and press Enter
3. Type `ipconfig` and press Enter
4. Look for "IPv4 Address" under your active network adapter (WiFi or Ethernet)
5. Note down the IP address (e.g., `192.168.1.100`)

### Method 2: Using Settings
1. Open Settings → Network & Internet
2. Click on your connection (WiFi or Ethernet)
3. Scroll down to find your IPv4 address

**Example IP addresses**:
- `192.168.1.100` (common home network)
- `192.168.0.100` (alternative home network)
- `10.0.0.100` (some routers)

## Step 3: Configure Windows Firewall

You need to allow PocketBase through the firewall so your mobile device can connect.

### Option A: Allow PocketBase through Firewall (Recommended)

1. Open **Windows Defender Firewall**
2. Click **"Allow an app or feature through Windows Defender Firewall"**
3. Click **"Change settings"** (requires admin)
4. Click **"Allow another app..."**
5. Click **"Browse..."** and navigate to `C:\pocketbase\pocketbase.exe`
6. Click **"Add"**
7. Make sure both **Private** and **Public** are checked
8. Click **OK**

### Option B: Create Firewall Rule (Advanced)

1. Open **Windows Defender Firewall with Advanced Security**
2. Click **"Inbound Rules"** → **"New Rule..."**
3. Select **"Port"** → Next
4. Select **"TCP"** and enter port **8090** → Next
5. Select **"Allow the connection"** → Next
6. Check all profiles (Domain, Private, Public) → Next
7. Name it **"PocketBase Server"** → Finish

## Step 4: Start PocketBase Server

1. Open Command Prompt or PowerShell
2. Navigate to PocketBase folder:
   ```cmd
   cd C:\pocketbase
   ```

3. Start PocketBase:
   ```cmd
   pocketbase serve --http="0.0.0.0:8090"
   ```

4. You should see output like:
   ```
   > Server started at: http://0.0.0.0:8090
   > Admin UI: http://0.0.0.0:8090/_/
   ```

**Important**: Keep this window open while using the app!

## Step 5: Setup PocketBase Admin Account

1. On your computer, open browser and go to: `http://localhost:8090/_/`
2. Create an admin account (this is for PocketBase admin, not your app)
3. Set a strong password and save it

## Step 6: Import Database Schema

1. In PocketBase Admin UI, go to **Settings** → **Import collections**
2. Click **"Load from JSON file"**
3. Select the file: `pocketbase-backend-files/pb_schema.json` from your project
4. Click **"Review"** then **"Confirm and import"**

This will create all necessary collections (users, expenses, invoice_files).

## Step 7: Configure App to Use Your Server

Update the PocketBase URL in your Flutter app:

1. Open `lib/core/config/pocketbase_config.dart`
2. Replace the baseUrl with your computer's IP:

```dart
class PocketBaseConfig {
  // Replace with your computer's IP address
  static const String baseUrl = 'http://192.168.1.100:8090'; // Use YOUR IP here
  
  static const String apiUrl = '$baseUrl/api';
  
  // Collection names
  static const String usersCollection = 'users';
  static const String expensesCollection = 'expenses';
  
  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
```

**Replace `192.168.1.100` with YOUR computer's actual IP address!**

## Step 8: Test Connection

### From Your Computer
1. Open browser: `http://localhost:8090/api/health`
2. Should see: `{"code":200,"message":"API is healthy"}`

### From Your Mobile Device
1. Make sure your phone is on the same WiFi network
2. Open browser on phone: `http://YOUR_IP:8090/api/health`
3. Should see the same health message

If you can't connect from phone:
- Check firewall settings
- Verify both devices are on same WiFi
- Try disabling Windows Firewall temporarily to test

## Step 9: Rebuild and Run App

1. Clean and rebuild the app:
   ```bash
   flutter clean
   flutter pub get
   flutter run --flavor admin -t lib/main_admin.dart
   ```

2. Register a new user in the app
3. Check PocketBase Admin UI to verify user was created

## Step 10: Keep Server Running

### Option A: Manual Start (Development)
- Open Command Prompt each time
- Run: `cd C:\pocketbase && pocketbase serve --http="0.0.0.0:8090"`
- Keep window open

### Option B: Create Batch File (Easier)
1. Create file `C:\pocketbase\start-server.bat`
2. Add this content:
   ```batch
   @echo off
   cd /d C:\pocketbase
   pocketbase serve --http="0.0.0.0:8090"
   pause
   ```
3. Double-click this file to start server

### Option C: Windows Service (Advanced)
Use NSSM (Non-Sucking Service Manager) to run PocketBase as a Windows service:

1. Download NSSM from https://nssm.cc/download
2. Extract and run as admin:
   ```cmd
   nssm install PocketBase
   ```
3. Configure:
   - Path: `C:\pocketbase\pocketbase.exe`
   - Startup directory: `C:\pocketbase`
   - Arguments: `serve --http="0.0.0.0:8090"`
4. Click "Install service"
5. Start service: `nssm start PocketBase`

## Troubleshooting

### Can't connect from mobile device

**Check 1: Same Network**
- Ensure phone and computer are on same WiFi
- Don't use mobile data on phone

**Check 2: Firewall**
```cmd
# Test if port is open
netstat -an | findstr :8090
```
Should show: `0.0.0.0:8090` or `[::]:8090`

**Check 3: Ping Test**
From phone browser, try: `http://YOUR_IP:8090`

**Check 4: Windows Firewall**
Temporarily disable to test:
- Settings → Windows Security → Firewall & network protection
- Turn off for Private network (temporarily)
- Test connection
- Turn back on and add proper rule

### PocketBase won't start

**Error: Port already in use**
```cmd
# Find what's using port 8090
netstat -ano | findstr :8090

# Kill the process (replace PID with actual number)
taskkill /PID <PID> /F
```

**Error: Permission denied**
- Run Command Prompt as Administrator
- Or move PocketBase to a folder you have write access to

### App shows "Connection refused"

1. Verify PocketBase is running:
   ```cmd
   curl http://localhost:8090/api/health
   ```

2. Check IP address in app config matches your computer's IP

3. Try using computer's hostname instead of IP:
   ```dart
   static const String baseUrl = 'http://YOUR-COMPUTER-NAME:8090';
   ```

### Data not syncing

1. Check PocketBase logs in Command Prompt window
2. Verify collection rules are imported correctly
3. Check app has internet permission in `AndroidManifest.xml`:
   ```xml
   <uses-permission android:name="android.permission.INTERNET"/>
   ```

## Security Notes

⚠️ **Important Security Considerations**:

1. **Local Network Only**: This setup only works on your local network (home/office WiFi)

2. **Not for Production**: Don't use this for production apps with real users

3. **Firewall**: Only allow PocketBase through firewall on trusted networks

4. **Admin Password**: Use a strong password for PocketBase admin account

5. **HTTPS**: For production, use HTTPS with proper SSL certificates

## Next Steps

Once local setup works:

1. **Test all features**: Register, login, create expenses, sync
2. **Check sync status**: Verify data appears in PocketBase Admin UI
3. **Test offline**: Turn off WiFi, create expense, turn on WiFi, verify sync
4. **Deploy to cloud**: When ready, deploy to Render.com or other hosting (see DEPLOYMENT_GUIDE.md)

## Quick Reference

**Start Server**:
```cmd
cd C:\pocketbase
pocketbase serve --http="0.0.0.0:8090"
```

**Access Admin UI**:
- From computer: `http://localhost:8090/_/`
- From phone: `http://YOUR_IP:8090/_/`

**Test API**:
- From computer: `http://localhost:8090/api/health`
- From phone: `http://YOUR_IP:8090/api/health`

**App Config**:
```dart
static const String baseUrl = 'http://YOUR_IP:8090';
```

**Stop Server**:
- Press `Ctrl + C` in Command Prompt window

## Support

If you encounter issues:
1. Check PocketBase logs in Command Prompt
2. Verify firewall settings
3. Test connection from phone browser first
4. Check both devices are on same WiFi
5. Try restarting PocketBase server
