# PocketBase Deployment on Render - Complete Guide

## Overview

This guide shows you how to deploy PocketBase to Render's free tier. 

**Important Notes:**
- ✅ No credit card required
- ✅ Free forever
- ⚠️ Sleeps after 15 minutes of inactivity (30-60 second wake-up time)
- ✅ ~1 GB storage
- ✅ 100 GB bandwidth/month

---

## Prerequisites

1. **GitHub account** (free)
2. **Render account** - Sign up at https://render.com (free, no card required)
3. **PocketBase locally configured** (you're doing this part)

---

## Part 1: Prepare Your Repository

### Step 1.1: Create Dockerfile in Repository Root

The Dockerfile must be in the root of your repository for Render to find it.

Create `Dockerfile` in the root:

```dockerfile
FROM alpine:latest

ARG PB_VERSION=0.22.0

RUN apk add --no-cache \
    unzip \
    ca-certificates

# Download and install PocketBase
ADD https://github.com/pocketbase/pocketbase/releases/download/v${PB_VERSION}/pocketbase_${PB_VERSION}_linux_amd64.zip /tmp/pb.zip
RUN unzip /tmp/pb.zip -d /pb/ && \
    chmod +x /pb/pocketbase

# Create data directory
RUN mkdir -p /pb/pb_data

EXPOSE 8080

# Start PocketBase
CMD ["/pb/pocketbase", "serve", "--http=0.0.0.0:8080", "--dir=/pb/pb_data"]
```

### Step 1.2: Create .gitignore

Create `.gitignore` in the root (or add to existing):

```
pb_data/
*.db
*.db-shm
*.db-wal
```

### Step 1.3: Create README

Create `README.md` in the root:

```markdown
# PocketBase Backend for Finance App

This is the PocketBase backend deployed on Render.

## Deployment

This repository is automatically deployed to Render when changes are pushed to the main branch.

## Local Development

1. Download PocketBase from https://pocketbase.io/
2. Run: `./pocketbase serve`
3. Access admin UI at http://127.0.0.1:8090/_/

## Production URL

https://your-app-name.onrender.com
```

---

## Part 2: Push to GitHub

### Step 2.1: Update Your Existing Repository

Since you already have the repository at https://github.com/alhossein10/pocketbase-backend, you need to add the Dockerfile to it:

```bash
# Make sure you're in your pocketbase-backend repository
cd /path/to/pocketbase-backend

# Add the Dockerfile
git add Dockerfile .gitignore README.md
git commit -m "Add Dockerfile for Render deployment"
git push origin main
```

**Important**: The Dockerfile MUST be in the root of the repository, not in a subfolder!

---

## Part 3: Deploy to Render

### Step 3.1: Sign Up for Render

1. Go to https://render.com
2. Click **"Get Started"**
3. Sign up with GitHub (easiest option)
4. Authorize Render to access your repositories

### Step 3.2: Create New Web Service

1. Click **"New +"** button (top right)
2. Select **"Web Service"**
3. Click **"Build and deploy from a Git repository"**
4. Click **"Next"**

### Step 3.3: Connect Repository

1. Find your `pocketbase-backend` repository
2. Click **"Connect"**

### Step 3.4: Configure Service

Fill in these settings:

**Basic Settings:**
- **Name**: `finance-app-backend` (or your choice)
- **Region**: Choose closest to you
- **Branch**: `main`
- **Root Directory**: Leave empty
- **Runtime**: `Docker`

**Build Settings:**
- **Dockerfile Path**: `Dockerfile`

**Instance Type:**
- Select **"Free"** (should be selected by default)

**Advanced Settings (click "Advanced"):**
- **Auto-Deploy**: Yes (enabled by default)

### Step 3.5: Create Service

1. Click **"Create Web Service"** button at the bottom
2. Wait for initial deployment (5-10 minutes)
3. Watch the logs for any errors

### Step 3.6: Add Persistent Disk (CRITICAL!)

After the service is created, you need to add persistent storage:

1. In your service dashboard, click **"Settings"** in the left sidebar
2. Scroll down to the **"Disks"** section
3. Click **"Add Disk"**
4. Configure:
   - **Name**: `pb_data`
   - **Mount Path**: `/pb/pb_data`
   - **Size**: `1 GB` (free tier limit)
5. Click **"Save Changes"**
6. Your service will automatically redeploy with the disk attached

**Important**: Without this disk, all your data (users, expenses, images) will be lost every time the service restarts or redeploys!

---

## Part 4: Verify Deployment

### Step 4.1: Get Your URL

After deployment completes:

1. Your URL will be shown at the top: `https://finance-app-backend.onrender.com`
2. Copy this URL - you'll need it for Flutter config

### Step 4.2: Access Admin Dashboard

1. Open: `https://finance-app-backend.onrender.com/_/`
2. **First time**: Create admin account
3. **Important**: This is your production admin account!

### Step 4.3: Configure Collections

Since you're doing the PocketBase setup yourself, configure:

1. **Users collection** with role field
2. **Expenses collection** with all required fields
3. **API Rules** for both collections
4. **Create admin user** with role="admin"

(Follow the same steps from the PocketBase guide Part 2)

---

## Part 5: Update Flutter Configuration

### Step 5.1: Update PocketBase Config

Open `lib/core/config/pocketbase_config.dart`:

```dart
class PocketBaseConfig {
  // Replace with your Render URL
  static const String baseUrl = 'https://finance-app-backend.onrender.com';
  
  static const String apiUrl = '$baseUrl/api';
  
  // Collection names
  static const String usersCollection = 'users';
  static const String expensesCollection = 'expenses';
}
```

### Step 5.2: Test Connection

Create a simple test in your Flutter app:

```dart
import 'package:your_app/core/services/pocketbase_service.dart';

void testConnection() async {
  final pbService = PocketBaseService();
  pbService.initialize();
  
  try {
    await pbService.login('admin@example.com', 'your-password');
    print('✅ Connected to Render PocketBase!');
    print('Is admin: ${pbService.isAdmin}');
  } catch (e) {
    print('❌ Connection failed: $e');
  }
}
```

---

## Part 6: Handle the "Sleeping" Issue

### Understanding Sleep Behavior

Your Render app will sleep after 15 minutes of inactivity. Here's how to handle it:

### Option 1: Show Loading State (Recommended)

Update your Flutter app to show a loading indicator:

```dart
// In your sync service or API calls
Future<void> syncWithRetry() async {
  try {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Connecting to server...'),
          ],
        ),
      ),
    );
    
    // Make request (may take 30-60 sec if sleeping)
    await syncService.syncExpense(...);
    
    // Hide loading
    Navigator.pop(context);
  } catch (e) {
    // Handle error
  }
}
```

### Option 2: Keep-Alive Ping (Optional)

Create a simple keep-alive service (not recommended for free tier):

```dart
class KeepAliveService {
  Timer? _timer;
  
  void start() {
    // Ping every 10 minutes to keep awake
    _timer = Timer.periodic(Duration(minutes: 10), (_) async {
      try {
        await http.get(Uri.parse('${PocketBaseConfig.baseUrl}/api/health'));
      } catch (e) {
        // Ignore errors
      }
    });
  }
  
  void stop() {
    _timer?.cancel();
  }
}
```

**Note**: This uses bandwidth and may not be worth it for free tier.

---

## Part 7: Monitoring & Maintenance

### View Logs

1. Go to Render Dashboard
2. Click on your service
3. Click **"Logs"** tab
4. View real-time logs

### Check Status

1. Dashboard shows service status
2. Green = Running
3. Yellow = Deploying
4. Red = Error

### Restart Service

If something goes wrong:

1. Go to service dashboard
2. Click **"Manual Deploy"** → **"Clear build cache & deploy"**

### Update PocketBase Version

To update PocketBase:

1. Edit `Dockerfile`
2. Change `ARG PB_VERSION=0.22.0` to new version
3. Commit and push to GitHub
4. Render will auto-deploy

---

## Part 8: Backup Your Data

### Manual Backup

1. Go to Render Dashboard
2. Click on your service
3. Click **"Shell"** tab
4. Run:
   ```bash
   cd /pb/pb_data
   tar -czf backup.tar.gz .
   ```
5. Download the backup file

### Automated Backup (Advanced)

Consider setting up automated backups to:
- Google Drive
- Dropbox
- GitHub (for small databases)

---

## Troubleshooting

### Issue: "Service Unavailable" or 503 Error

**Cause**: App is sleeping

**Solution**: Wait 30-60 seconds for it to wake up

### Issue: "Cannot connect to server"

**Solutions**:
1. Check Render dashboard - is service running?
2. Check logs for errors
3. Verify URL is correct in Flutter config
4. Try accessing `https://your-app.onrender.com/_/` directly

### Issue: Data Lost After Deploy

**Cause**: Persistent disk not configured

**Solution**:
1. Go to service settings
2. Add persistent disk at `/pb/pb_data`
3. Redeploy

### Issue: "Out of Memory" Errors

**Cause**: Free tier has 512 MB RAM limit

**Solutions**:
1. Reduce image sizes before upload
2. Limit concurrent operations
3. Consider upgrading to paid tier ($7/month)

---

## Free Tier Limits

### Render Free Tier

| Resource | Limit |
|----------|-------|
| RAM | 512 MB |
| Storage | 1 GB (persistent disk) |
| Bandwidth | 100 GB/month |
| Sleep | After 15 min inactivity |
| Build Time | 500 hours/month |

### Estimated Capacity

- **~2,000 expenses** with images (500KB each)
- **~5,000 expenses** without images
- **Unlimited users** (within bandwidth)

---

## Upgrading to Paid Tier

If you need always-on service:

1. Go to service settings
2. Change instance type to **"Starter"** ($7/month)
3. Benefits:
   - No sleeping
   - More RAM (512 MB → 2 GB)
   - Faster performance
   - Priority support

---

## Summary

You now have:
- ✅ PocketBase deployed on Render (free)
- ✅ ~1 GB storage for expenses and images
- ✅ Automatic HTTPS
- ✅ Auto-deploy from GitHub
- ✅ Persistent data storage
- ⚠️ Sleeps after 15 min (30-60 sec wake-up)

**Your PocketBase URL**: `https://finance-app-backend.onrender.com`

**Next Steps**:
1. Configure PocketBase collections (you're doing this)
2. Update Flutter config with your Render URL
3. Test connection from Flutter app
4. Proceed to Task 2: Build Flavor Configuration

---

## Support & Resources

- **Render Docs**: https://render.com/docs
- **PocketBase Docs**: https://pocketbase.io/docs/
- **Render Community**: https://community.render.com/
- **PocketBase Discussions**: https://github.com/pocketbase/pocketbase/discussions

---

## Cost Comparison

| Provider | Cost | Storage | Always-On | Setup |
|----------|------|---------|-----------|-------|
| **Render** | Free | 1 GB | ❌ Sleeps | Easy (Web UI) |
| **Fly.io** | Free | 3 GB | ✅ Yes | Medium (CLI) |
| **Railway** | $5 credit | 1 GB | ✅ Yes | Easy (Web UI) |

**Total Cost with Render: $0/month** (within free tier)

Good luck with your deployment! 🚀
