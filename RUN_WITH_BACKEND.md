# Run App with Backend API

## The Issue

The registration page shows a spinning indicator because the app can't reach your backend API. This happens when:

1. The API base URL is not configured
2. The app is using the default `http://localhost:8000` which doesn't work
3. Your backend is running on a different IP address

## Your Backend Info

Based on your Postman tests, your backend is working at:
- Base URL: `{{base_url}}`
- Organizations endpoint: `{{base_url}}/organizations` ✅ Working
- Departments endpoint: `{{base_url}}/organizations/{{organization_id}}/departments` ✅ Working

## Solution

You need to run the app with the correct API base URL.

### Step 1: Find Your Backend URL

Check your Postman environment variables to see what `{{base_url}}` is set to. It's probably something like:
- `http://192.168.1.XXX:8000` (if backend is on your local network)
- `http://localhost:8000` (if backend is on same machine)
- `http://10.0.2.2:8000` (if using Android emulator)

### Step 2: Run the App with Correct URL

Replace `YOUR_BACKEND_URL` with your actual backend URL:

**For Windows (User flavor):**
```bash
flutter clean
flutter run -d windows --dart-define=FLAVOR=user --dart-define=API_BASE_URL=YOUR_BACKEND_URL/api/v1
```

**Example with IP address:**
```bash
flutter run -d windows --dart-define=FLAVOR=user --dart-define=API_BASE_URL=http://192.168.1.100:8000/api/v1
```

**For Android (User flavor):**
```bash
flutter clean
flutter run -d android --dart-define=FLAVOR=user --dart-define=API_BASE_URL=YOUR_BACKEND_URL/api/v1
```

### Step 3: Verify Connection

When the app starts, check the console logs for:
```
🔵 [AUTH_API] Fetching organizations...
🔵 [AUTH_API] Response received!
✅ [AUTH_API] Successfully loaded 3 organizations
```

If you see errors like:
```
❌ [AUTH_API] Organizations endpoint error: ...
```

Then the API base URL is wrong or the backend is not reachable.

## Quick Test Commands

### If your backend is at http://192.168.1.100:8000

```bash
# Windows
flutter run -d windows --dart-define=FLAVOR=user --dart-define=API_BASE_URL=http://192.168.1.100:8000/api/v1

# Android
flutter run -d android --dart-define=FLAVOR=user --dart-define=API_BASE_URL=http://192.168.1.100:8000/api/v1
```

### If your backend is at http://localhost:8000

```bash
# Windows
flutter run -d windows --dart-define=FLAVOR=user --dart-define=API_BASE_URL=http://localhost:8000/api/v1

# Android Emulator (use 10.0.2.2 instead of localhost)
flutter run -d android --dart-define=FLAVOR=user --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
```

## What Should Happen

After running with the correct API base URL:

1. ✅ Registration page loads instantly
2. ✅ Organization dropdown shows your 3 organizations:
   - هيئة الاتصالات (ID: 1)
   - هيئة الاتصالات (ID: 2)
   - هيئة الاتصالات (ID: 3)
3. ✅ After selecting organization, departments load:
   - إدارة الإشارة
   - إدارة الحرب الالكترونية
   - إدارة الشبكات
   - إدارة المالية
   - إدارة المعلوماتية
   - إدارة الموارد البشرية

## Troubleshooting

### Still showing "Default Organization"?

The app is falling back to default because it can't reach the API. Check:

1. **Backend is running**: Visit `YOUR_BACKEND_URL/api/v1/organizations` in your browser
2. **Firewall**: Make sure Windows Firewall allows the connection
3. **Network**: Make sure your device can reach the backend IP
4. **CORS**: Make sure Laravel CORS is configured to allow your app

### How to check what URL the app is using?

Look for this log when the app starts:
```
[ApiClient] Request: GET http://YOUR_URL/api/v1/organizations
```

If it shows `http://localhost:8000` but your backend is elsewhere, you need to specify the correct URL.

## Create a Run Script

Create `run_user_app.bat` for easy launching:

```batch
@echo off
echo Starting Finance App (User) with Backend
echo.
echo Backend URL: http://192.168.1.100:8000/api/v1
echo.
flutter run -d windows --dart-define=FLAVOR=user --dart-define=API_BASE_URL=http://192.168.1.100:8000/api/v1
```

Replace the IP address with your actual backend URL, then just double-click the file to run!
