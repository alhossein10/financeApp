# Run App on Mobile Device

## Quick Steps

### 1. Find Your Computer's IP Address

Open Command Prompt and run:
```bash
ipconfig
```

Look for **IPv4 Address** under your WiFi or Ethernet adapter.  
Example: `192.168.1.100`

### 2. Connect Your Mobile

- Connect your Android phone via USB
- Enable USB Debugging on your phone
- Make sure your phone and computer are on the **same WiFi network**

### 3. Run the Command

Replace `YOUR_COMPUTER_IP` with the IP you found:

**User Version:**
```bash
flutter run -d android --dart-define=FLAVOR=user --dart-define=API_BASE_URL=http://YOUR_COMPUTER_IP:8000/api/v1
```

**Admin Version:**
```bash
flutter run -d android --dart-define=FLAVOR=admin --dart-define=API_BASE_URL=http://YOUR_COMPUTER_IP:8000/api/v1
```

## Example

If your IP is `192.168.1.100`:

```bash
flutter run -d android --dart-define=FLAVOR=user --dart-define=API_BASE_URL=http://192.168.1.100:8000/api/v1
```

## Test Backend Connection First

On your mobile browser, visit:
```
http://YOUR_COMPUTER_IP:8000/api/v1/organizations
```

You should see JSON with your 3 organizations. If this works, the app will work too!

## Common Issues

### "Connection Refused" or "Timeout"

**Problem**: Mobile can't reach your computer

**Solutions**:
1. Make sure both devices are on the same WiFi
2. Check Windows Firewall - allow Laravel/PHP through firewall
3. Try disabling Windows Firewall temporarily to test
4. Make sure backend is running on `0.0.0.0:8000` (not `127.0.0.1`)

### How to Allow Through Firewall

1. Open Windows Defender Firewall
2. Click "Allow an app through firewall"
3. Find PHP or add it manually
4. Allow both Private and Public networks

### Alternative: Create Firewall Rule

Run as Administrator:
```bash
netsh advfirewall firewall add rule name="Laravel Backend" dir=in action=allow protocol=TCP localport=8000
```

## Verify Setup

### Check if backend is accessible:

From your mobile browser:
```
http://YOUR_IP:8000/api/v1/organizations
```

From another computer on same network:
```
http://YOUR_IP:8000/api/v1/organizations
```

If both work, the Flutter app will work!

## Using Batch File

1. Edit `run_mobile_user.bat`
2. Replace `YOUR_COMPUTER_IP` with your actual IP
3. Save and double-click to run

## iOS Device

For iOS, use the same command but with `-d ios`:

```bash
flutter run -d ios --dart-define=FLAVOR=user --dart-define=API_BASE_URL=http://YOUR_COMPUTER_IP:8000/api/v1
```

## Wireless Debugging (Optional)

After first USB connection, you can use wireless debugging:

1. Connect via USB first
2. Run: `adb tcpip 5555`
3. Find phone's IP: Settings > About > Status > IP address
4. Run: `adb connect PHONE_IP:5555`
5. Disconnect USB
6. Run flutter command as normal

---

**Remember**: Your backend runs on `0.0.0.0:8000` which means it's accessible from any device on your network. Just use your computer's IP address instead of `127.0.0.1`!
