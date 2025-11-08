# Finance App Deployment Guide

This guide provides comprehensive instructions for deploying the Finance App's backend (PocketBase) and distributing the Admin and User versions of the application.

## Table of Contents

1. [PocketBase Local Setup](#pocketbase-local-setup)
2. [PocketBase Cloud Deployment](#pocketbase-cloud-deployment)
3. [Collection Rules Configuration](#collection-rules-configuration)
4. [Application Distribution](#application-distribution)
5. [Post-Deployment Verification](#post-deployment-verification)
6. [Maintenance and Monitoring](#maintenance-and-monitoring)

---

## PocketBase Local Setup

### Prerequisites

- Operating System: Windows, macOS, or Linux
- Minimum 512MB RAM
- 1GB free disk space

### Step 1: Download PocketBase

1. Visit https://pocketbase.io/docs/
2. Download the appropriate binary for your operating system:
   - Windows: `pocketbase_windows_amd64.zip`
   - macOS: `pocketbase_darwin_amd64.zip` (Intel) or `pocketbase_darwin_arm64.zip` (Apple Silicon)
   - Linux: `pocketbase_linux_amd64.zip`

3. Extract the archive to a directory (e.g., `~/pocketbase` or `C:\pocketbase`)

### Step 2: Initialize PocketBase

```bash
# Navigate to PocketBase directory
cd ~/pocketbase  # or cd C:\pocketbase on Windows

# Start PocketBase (creates initial database)
./pocketbase serve  # or pocketbase.exe serve on Windows
```

PocketBase will start on `http://127.0.0.1:8090`

### Step 3: Create Admin Account

1. Open your browser and navigate to `http://127.0.0.1:8090/_/`
2. Create an admin account (this is your PocketBase admin, not the app admin)
3. Set a strong password and save credentials securely

### Step 4: Import Schema

1. In the PocketBase Admin UI, go to **Settings** → **Import collections**
2. Upload the schema file: `pocketbase-backend-files/pb_schema.json`
3. Click **Import** to create all required collections

This will create the following collections:
- `users` - User accounts with role field
- `expenses` - Expense records with sync metadata
- `invoice_files` - Invoice image attachments

### Step 5: Configure Collection Rules

1. Navigate to **Collections** in the PocketBase Admin UI
2. For each collection, configure the rules as documented in `pocketbase-backend-files/collection_rules.md`

See [Collection Rules Configuration](#collection-rules-configuration) section below for detailed rules.

### Step 6: Test Local Setup

```bash
# Test API health
curl http://127.0.0.1:8090/api/health

# Expected response: {"code":200,"message":"API is healthy"}
```

### Step 7: Configure App to Use Local PocketBase

Update `lib/core/services/pocketbase_service.dart`:

```dart
final pb = PocketBase('http://127.0.0.1:8090');
```

For Android emulator, use `http://10.0.2.2:8090` instead of `127.0.0.1`.

---

## PocketBase Cloud Deployment

### Option 1: Render.com Deployment (Recommended)

#### Prerequisites
- Render.com account (free tier available)
- GitHub account
- PocketBase project files

#### Step 1: Prepare Repository

1. Create a new GitHub repository or use existing one
2. Ensure `pocketbase-backend-files/Dockerfile` is in the repository
3. Push your code to GitHub

#### Step 2: Create Render Web Service

1. Log in to [Render.com](https://render.com)
2. Click **New** → **Web Service**
3. Connect your GitHub repository
4. Configure the service:
   - **Name**: `finance-app-pocketbase`
   - **Environment**: `Docker`
   - **Region**: Choose closest to your users
   - **Branch**: `main` (or your default branch)
   - **Dockerfile Path**: `pocketbase-backend-files/Dockerfile`

#### Step 3: Configure Environment

Set the following environment variables in Render:

```
PORT=8090
```

#### Step 4: Add Persistent Disk

1. In the service settings, scroll to **Disks**
2. Click **Add Disk**
3. Configure:
   - **Name**: `pocketbase-data`
   - **Mount Path**: `/pb_data`
   - **Size**: 1GB (adjust based on needs)

This ensures your database persists across deployments.

#### Step 5: Deploy

1. Click **Create Web Service**
2. Wait for deployment to complete (5-10 minutes)
3. Note your service URL: `https://finance-app-pocketbase.onrender.com`

#### Step 6: Configure Admin Account

1. Navigate to `https://your-service.onrender.com/_/`
2. Create admin account on first visit
3. Import schema from `pocketbase-backend-files/pb_schema.json`
4. Configure collection rules

#### Step 7: Update App Configuration

Update `lib/core/services/pocketbase_service.dart`:

```dart
final pb = PocketBase('https://your-service.onrender.com');
```

### Option 2: Docker Deployment (Self-Hosted)

#### Prerequisites
- Docker installed
- Server with public IP or domain
- Minimum 1GB RAM

#### Step 1: Build Docker Image

```bash
cd pocketbase-backend-files
docker build -t finance-pocketbase .
```

#### Step 2: Run Container

```bash
docker run -d \
  --name pocketbase \
  -p 8090:8090 \
  -v pocketbase_data:/pb_data \
  --restart unless-stopped \
  finance-pocketbase
```

#### Step 3: Configure Reverse Proxy (Optional but Recommended)

Use Nginx or Caddy to add HTTPS:

**Nginx Configuration:**
```nginx
server {
    listen 80;
    server_name pocketbase.yourdomain.com;
    
    location / {
        proxy_pass http://localhost:8090;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

Then add SSL with Let's Encrypt:
```bash
sudo certbot --nginx -d pocketbase.yourdomain.com
```

### Option 3: PocketBase Cloud (When Available)

PocketBase is developing an official cloud hosting solution. Check https://pocketbase.io for updates.

---

## Collection Rules Configuration

### Users Collection

**API Rules:**

```javascript
// List/Search Rule
@request.auth.id != ""

// View Rule
@request.auth.id != "" && (id = @request.auth.id || @request.auth.role = "admin")

// Create Rule
@request.data.email != "" && @request.data.password != ""

// Update Rule
@request.auth.id != "" && id = @request.auth.id

// Delete Rule
@request.auth.id != "" && id = @request.auth.id
```

**Fields:**
- `username` (Text, Required, Unique)
- `email` (Email, Required, Unique)
- `password` (Password, Required, Min 8 characters)
- `role` (Number, Default: 0) - 0 = user, 1 = admin
- `profilePicture` (File, Optional)

### Expenses Collection

**API Rules:**

```javascript
// List/Search Rule - Users see only their expenses, admins see all
@request.auth.id != "" && (@request.auth.role = 1 || user_id = @request.auth.id)

// View Rule - Users see only their expenses, admins see all
@request.auth.id != "" && (@request.auth.role = 1 || user_id = @request.auth.id)

// Create Rule - Users can create their own expenses
@request.auth.id != "" && @request.data.user_id = @request.auth.id

// Update Rule - No updates allowed (immutable)
@request.auth.id = ""

// Delete Rule - No deletes allowed (immutable)
@request.auth.id = ""
```

**Fields:**
- `user_id` (Number, Required)
- `username` (Text, Required)
- `user_email` (Email, Required)
- `local_expense_id` (Number, Required)
- `description` (Text, Required)
- `price_usd` (Number, Optional)
- `price_syp` (Number, Optional)
- `price_try` (Number, Optional)
- `invoice_status` (Number, Required)
- `invoice_file_id` (Text, Optional) - Reference to invoice_files
- `expense_date` (Date, Required)
- `synced_at` (Date, Required)

### Invoice Files Collection

**API Rules:**

```javascript
// List/Search Rule - Users see only their files, admins see all
@request.auth.id != "" && (@request.auth.role = 1 || user_id = @request.auth.id)

// View Rule - Users see only their files, admins see all
@request.auth.id != "" && (@request.auth.role = 1 || user_id = @request.auth.id)

// Create Rule - Users can upload their own files
@request.auth.id != "" && @request.data.user_id = @request.auth.id

// Update Rule - No updates allowed
@request.auth.id = ""

// Delete Rule - Admins only
@request.auth.id != "" && @request.auth.role = 1
```

**Fields:**
- `user_id` (Number, Required)
- `expense_id` (Number, Required)
- `file` (File, Required, Max 10MB)

**File Settings:**
- Max file size: 10MB
- Allowed types: image/jpeg, image/png, image/heic
- Thumb sizes: 100x100, 500x500

### Applying Rules via Admin UI

1. Navigate to **Collections** in PocketBase Admin UI
2. Click on each collection name
3. Go to **API Rules** tab
4. Paste the rules for each operation (List, View, Create, Update, Delete)
5. Click **Save changes**

### Applying Rules via Import

Alternatively, the rules are included in `pocketbase-backend-files/pb_schema.json` and will be imported automatically when you import the schema.

---

## Application Distribution

### Admin Version Distribution

The Admin version should be distributed internally only, NOT to public app stores.

#### Option 1: Firebase App Distribution (Recommended)

1. **Setup Firebase Project**
   ```bash
   npm install -g firebase-tools
   firebase login
   firebase init
   ```

2. **Build Admin APK**
   ```bash
   flutter build apk --flavor admin -t lib/main_admin.dart --release
   ```

3. **Upload to Firebase**
   ```bash
   firebase appdistribution:distribute \
     build/app/outputs/flutter-apk/app-admin-release.apk \
     --app YOUR_FIREBASE_APP_ID \
     --groups "admins" \
     --release-notes "Admin version release"
   ```

4. **Invite Administrators**
   - Go to Firebase Console → App Distribution
   - Add admin email addresses to the "admins" group
   - They'll receive invitation emails with download links

#### Option 2: TestFlight (iOS)

1. **Build iOS Archive**
   ```bash
   flutter build ios --flavor admin -t lib/main_admin.dart --release
   ```

2. **Upload to App Store Connect**
   - Open Xcode
   - Product → Archive
   - Distribute App → TestFlight
   - Upload to App Store Connect

3. **Add Internal Testers**
   - Go to App Store Connect → TestFlight
   - Add admin users as internal testers
   - They'll receive TestFlight invitation

#### Option 3: Direct APK Distribution

1. **Build Signed APK**
   ```bash
   flutter build apk --flavor admin -t lib/main_admin.dart --release
   ```

2. **Distribute via Secure Channel**
   - Upload to secure file sharing (Google Drive, Dropbox)
   - Share link only with authorized administrators
   - Require authentication to access

3. **Installation Instructions for Admins**
   - Enable "Install from Unknown Sources" on Android
   - Download APK
   - Install and launch

### User Version Distribution

The User version can be distributed publicly through official app stores.

#### Google Play Store (Android)

1. **Create Google Play Developer Account**
   - Visit https://play.google.com/console
   - Pay one-time $25 registration fee

2. **Prepare App Bundle**
   ```bash
   flutter build appbundle --flavor user -t lib/main_user.dart --release
   ```

3. **Create App Listing**
   - Go to Google Play Console
   - Create new app
   - Fill in app details, screenshots, description
   - Set content rating
   - Set pricing (Free)

4. **Upload App Bundle**
   - Go to Release → Production
   - Create new release
   - Upload `build/app/outputs/bundle/userRelease/app-user-release.aab`
   - Add release notes
   - Review and rollout

5. **Configure App Signing**
   - Use Google Play App Signing (recommended)
   - Upload your upload key

#### Apple App Store (iOS)

1. **Create Apple Developer Account**
   - Visit https://developer.apple.com
   - Enroll in Apple Developer Program ($99/year)

2. **Prepare iOS Build**
   ```bash
   flutter build ios --flavor user -t lib/main_user.dart --release
   ```

3. **Create App in App Store Connect**
   - Go to https://appstoreconnect.apple.com
   - Create new app
   - Fill in app information
   - Add screenshots and description

4. **Upload Build**
   - Open Xcode
   - Product → Archive
   - Distribute App → App Store Connect
   - Upload build

5. **Submit for Review**
   - Select build in App Store Connect
   - Complete all required information
   - Submit for review
   - Wait for approval (typically 1-3 days)

#### Web Deployment

1. **Build Web Version**
   ```bash
   # User version
   flutter build web --target lib/main_user.dart --release
   
   # Admin version (if needed)
   flutter build web --target lib/main_admin.dart --release
   ```

2. **Deploy to Hosting**

   **Option A: Firebase Hosting**
   ```bash
   firebase init hosting
   firebase deploy --only hosting
   ```

   **Option B: Netlify**
   - Drag and drop `build/web` folder to Netlify
   - Or connect GitHub repository for automatic deployments

   **Option C: GitHub Pages**
   ```bash
   # Add to repository
   git add build/web
   git commit -m "Deploy web version"
   git push origin main
   
   # Enable GitHub Pages in repository settings
   ```

---

## Post-Deployment Verification

### Backend Verification

1. **Test PocketBase API**
   ```bash
   # Health check
   curl https://your-pocketbase-url.com/api/health
   
   # Test authentication
   curl -X POST https://your-pocketbase-url.com/api/collections/users/auth-with-password \
     -H "Content-Type: application/json" \
     -d '{"identity":"test@example.com","password":"testpassword"}'
   ```

2. **Verify Collections**
   - Log in to PocketBase Admin UI
   - Check all collections are created
   - Verify rules are applied correctly

3. **Test File Upload**
   - Create a test expense with image in the app
   - Verify image appears in PocketBase Admin UI under invoice_files collection

### App Verification

1. **Test User Version**
   - Install user version on test device
   - Create user account
   - Create expense with invoice image
   - Verify sync status shows "Synced"
   - Check expense appears in PocketBase

2. **Test Admin Version**
   - Install admin version on test device
   - Log in with admin account (role = 1)
   - Open Admin Dashboard
   - Verify user-submitted expenses appear
   - Verify invoice images load correctly

3. **Test Offline Functionality**
   - Turn off device internet
   - Create expense in user version
   - Verify sync status shows "Pending"
   - Turn on internet
   - Verify automatic sync occurs
   - Check sync status changes to "Synced"

### Security Verification

1. **Test Access Control**
   - Log in as regular user
   - Attempt to access admin dashboard (should fail)
   - Verify user can only see their own expenses

2. **Test Data Isolation**
   - Create expense as User A
   - Log in as User B
   - Verify User B cannot see User A's expenses
   - Log in as Admin
   - Verify Admin can see both users' expenses

3. **Test Collection Rules**
   - Attempt to update an expense (should fail - immutable)
   - Attempt to delete an expense as user (should fail)
   - Attempt to delete as admin (should succeed for invoice_files only)

---

## Maintenance and Monitoring

### PocketBase Maintenance

#### Backup Strategy

1. **Automated Backups**
   ```bash
   # Create backup script
   #!/bin/bash
   DATE=$(date +%Y%m%d_%H%M%S)
   tar -czf pocketbase_backup_$DATE.tar.gz /pb_data
   
   # Upload to cloud storage (example: AWS S3)
   aws s3 cp pocketbase_backup_$DATE.tar.gz s3://your-backup-bucket/
   ```

2. **Schedule with Cron**
   ```bash
   # Run daily at 2 AM
   0 2 * * * /path/to/backup_script.sh
   ```

3. **Render.com Backups**
   - Render automatically backs up persistent disks
   - Manual backups: Download disk snapshot from Render dashboard

#### Database Maintenance

1. **Monitor Database Size**
   ```bash
   # Check pb_data size
   du -sh /pb_data
   ```

2. **Clean Old Files** (if needed)
   - Review invoice_files collection
   - Delete files for deleted expenses
   - Use PocketBase Admin UI or API

#### Update PocketBase

1. **Check for Updates**
   - Visit https://github.com/pocketbase/pocketbase/releases

2. **Update Process**
   ```bash
   # Backup first!
   tar -czf pb_data_backup.tar.gz /pb_data
   
   # Download new version
   wget https://github.com/pocketbase/pocketbase/releases/download/vX.X.X/pocketbase_X.X.X_linux_amd64.zip
   
   # Extract and replace
   unzip pocketbase_X.X.X_linux_amd64.zip
   
   # Restart service
   ./pocketbase serve
   ```

### Application Monitoring

#### User Metrics

Track in analytics (Firebase Analytics, Google Analytics):
- Daily active users
- Expense creation rate
- Sync success/failure rate
- Average sync time
- Image upload success rate

#### Error Monitoring

Use crash reporting (Firebase Crashlytics, Sentry):
- Monitor sync failures
- Track image upload errors
- Monitor authentication issues
- Track API errors

#### Performance Monitoring

- Monitor app startup time
- Track sync operation duration
- Monitor image compression time
- Track database query performance

### Scaling Considerations

#### When to Scale PocketBase

Scale when you experience:
- Response times > 500ms
- CPU usage consistently > 80%
- Memory usage > 80%
- Storage > 80% capacity

#### Scaling Options

1. **Vertical Scaling**
   - Increase server resources (CPU, RAM)
   - On Render: Upgrade to higher tier plan

2. **Horizontal Scaling**
   - PocketBase doesn't support clustering yet
   - Consider migrating to PostgreSQL + custom API if needed

3. **Storage Scaling**
   - Increase disk size on Render
   - Move images to dedicated storage (AWS S3, Cloudinary)

### Support and Troubleshooting

#### Common Issues

1. **Sync Failures**
   - Check PocketBase server status
   - Verify collection rules
   - Check authentication tokens
   - Review error logs in app

2. **Image Upload Failures**
   - Check file size limits
   - Verify image compression works
   - Check PocketBase storage quota
   - Review network connectivity

3. **Performance Issues**
   - Monitor database size
   - Check for slow queries
   - Review image sizes
   - Consider CDN for images

#### Getting Help

- PocketBase Documentation: https://pocketbase.io/docs/
- PocketBase GitHub: https://github.com/pocketbase/pocketbase
- Flutter Documentation: https://docs.flutter.dev/
- Project Issues: [Your GitHub repository]

---

## Security Best Practices

### Production Checklist

- [ ] Change default PocketBase admin password
- [ ] Enable HTTPS for PocketBase (use reverse proxy)
- [ ] Configure CORS properly
- [ ] Set up rate limiting
- [ ] Enable PocketBase logs
- [ ] Implement backup strategy
- [ ] Set up monitoring and alerts
- [ ] Review and test collection rules
- [ ] Secure API keys and credentials
- [ ] Enable two-factor authentication for admin accounts
- [ ] Regular security audits
- [ ] Keep PocketBase updated

### Data Privacy

- Comply with GDPR/CCPA if applicable
- Implement data retention policies
- Provide user data export functionality
- Implement user data deletion
- Encrypt sensitive data
- Use secure connections (HTTPS)
- Log access to sensitive data

---

## Conclusion

This deployment guide covers the complete process of deploying the Finance App backend and distributing both Admin and User versions. Follow the steps carefully and verify each stage before proceeding to the next.

For additional help, refer to:
- [README.md](README.md) - Build instructions
- [POCKETBASE_COMPLETE_SETUP_GUIDE.md](POCKETBASE_COMPLETE_SETUP_GUIDE.md) - Detailed PocketBase setup
- [pocketbase-backend-files/collection_rules.md](pocketbase-backend-files/collection_rules.md) - Collection rules reference

Good luck with your deployment!
