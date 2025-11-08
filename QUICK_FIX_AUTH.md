# Quick Fix - Authentication Not Working

## The Problem
- You see blue logs with your credentials
- Spinner keeps spinning
- Nothing happens

## The Cause
**Laravel backend is not responding to the API request.**

This means one of these is true:
1. Laravel is not running
2. Wrong IP address
3. Firewall is blocking
4. Not on same WiFi network

## Quick Fix (5 Steps)

### Step 1: Make Sure Laravel is Running

Open a terminal in your Laravel project:

```bash
cd financeApp-backend-main
php artisan serve --host=0.0.0.0
```

You should see:
```
Laravel development server started: http://0.0.0.0:8000
```

**Keep this terminal open!** Don't close it.

### Step 2: Find Your Computer's IP Address

**Windows:**
```bash
ipconfig
```
Look for "IPv4 Address" under your WiFi adapter (e.g., `192.168.6.18`)

**Mac/Linux:**
```bash
ifconfig
```
Look for "inet" under your WiFi adapter (e.g., `192.168.6.18`)

### Step 3: Test with Browser

Open your phone's browser and go to:
```
http://192.168.6.18:8000
```
(Replace with your actual IP)

**Expected:** You should see Laravel welcome page  
**If not working:** Check firewall or WiFi

### Step 4: Allow PHP Through Firewall

**Windows:**
1. Search "Windows Defender Firewall"
2. Click "Allow an app through firewall"
3. Click "Change settings"
4. Find "PHP" or click "Allow another app"
5. Browse to `C:\php\php.exe` (or wherever PHP is installed)
6. Check both "Private" and "Public"
7. Click OK

**Mac:**
1. System Preferences → Security & Privacy
2. Firewall tab
3. Click lock to make changes
4. Firewall Options
5. Click "+" and add PHP
6. Allow incoming connections

### Step 5: Run Flutter App

```bash
flutter run --flavor user --dart-define=API_BASE_URL=http://192.168.6.18:8000
```
(Replace with your actual IP)

Now try to register. You should see either:
- ✅ Success (green logs)
- ❌ Clear error message after 15 seconds

## Still Not Working?

### Test with cURL

```bash
curl -v http://192.168.6.18:8000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"name":"Test","email":"test@test.com","password":"Test123!","password_confirmation":"Test123!"}'
```

**If this works:** Problem is in Flutter app  
**If this fails:** Problem is with Laravel/network

## Common Issues

### "Connection refused"
- Laravel is not running
- **Fix:** Start Laravel with `php artisan serve --host=0.0.0.0`

### "Timeout"
- Firewall is blocking
- **Fix:** Allow PHP through firewall

### "Network unreachable"
- Phone and computer on different WiFi
- **Fix:** Connect both to same WiFi network

### "Can't access from browser"
- Wrong IP address
- **Fix:** Double-check IP with `ipconfig`/`ifconfig`

## Checklist

- [ ] Laravel is running (`php artisan serve --host=0.0.0.0`)
- [ ] I can see "Laravel development server started" message
- [ ] I found my computer's IP address
- [ ] I can open `http://MY_IP:8000` in phone's browser
- [ ] PHP is allowed through firewall
- [ ] Phone and computer on same WiFi
- [ ] I'm using the correct IP in Flutter app

## Expected Result

After fixing, you should see:

```
🔵 [BLOC] Registration requested for: test@example.com
🔵 [AUTH] Starting registration for: test@example.com
🔵 [AUTH] API URL: http://192.168.6.18:8000/api/v1/auth/register
🟢 [AUTH] Registration response received: 201
🟢 [AUTH] Response data: {token: ..., user: {...}}
🟢 [AUTH] Token stored successfully
🟢 [BLOC] Registration successful for user: test@example.com
```

Then the app should navigate to the home screen!

---

**Most Common Fix:** Just make sure Laravel is running with `php artisan serve --host=0.0.0.0` and keep that terminal open! 🚀
