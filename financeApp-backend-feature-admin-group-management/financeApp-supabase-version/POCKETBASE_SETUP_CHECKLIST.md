# PocketBase Setup Checklist

Use this checklist to track your progress through the PocketBase setup.

## ☐ Part 1: Local PocketBase Setup

- [ ] Download PocketBase for your OS
- [ ] Extract to folder (C:\pocketbase or ~/pocketbase)
- [ ] Run PocketBase locally
- [ ] Access admin UI at http://127.0.0.1:8090/_/
- [ ] Create admin account
- [ ] Verify admin dashboard loads

## ☐ Part 2: Configure Collections & Rules

### Users Collection
- [ ] Edit users collection
- [ ] Add `role` field (Select: user, admin)
- [ ] Add `created_at` field (Date)
- [ ] Add `updated_at` field (Date)
- [ ] Set API rules for users collection
- [ ] Save changes

### Expenses Collection
- [ ] Create new collection named "expenses"
- [ ] Add `user_id` field (Relation to users)
- [ ] Add `expense_id` field (Number)
- [ ] Add `description` field (Text)
- [ ] Add `price_usd` field (Number)
- [ ] Add `price_syp` field (Number)
- [ ] Add `price_try` field (Number)
- [ ] Add `invoice_status` field (Number)
- [ ] Add `invoice_image` field (File, max 5MB)
- [ ] Add `expense_date` field (Date)
- [ ] Add `sync_status` field (Select: pending, syncing, synced, failed)
- [ ] Add `synced_at` field (Date)
- [ ] Set API rules for expenses collection
- [ ] Save collection

### Create Admin User
- [ ] Go to users collection
- [ ] Create new record
- [ ] Set email: admin@example.com (or your email)
- [ ] Set password
- [ ] Set role: admin
- [ ] Save record

## ☐ Part 3: Deploy to Fly.io

### Install Fly CLI
- [ ] Install Fly CLI for your OS
- [ ] Run `fly auth signup` or `fly auth login`
- [ ] Verify authentication successful

### Create Deployment Files
- [ ] Create folder: pocketbase-deploy
- [ ] Create Dockerfile
- [ ] Create fly.toml
- [ ] Verify files are correct

### Deploy
- [ ] Run `fly launch`
- [ ] Choose app name
- [ ] Select region
- [ ] Decline PostgreSQL and Redis
- [ ] Run `fly volumes create pb_data --size 3`
- [ ] Run `fly deploy`
- [ ] Wait for deployment to complete
- [ ] Run `fly status` to get URL
- [ ] Note your URL: ___________________________

### Configure Deployed PocketBase
- [ ] Open https://your-app.fly.dev/_/
- [ ] Create admin account
- [ ] Recreate users collection configuration
- [ ] Recreate expenses collection configuration
- [ ] Create admin user record
- [ ] Verify collections and rules are correct

## ☐ Part 4: Flutter Integration

### Update Dependencies
- [ ] Update pubspec.yaml with PocketBase packages
- [ ] Run `flutter pub get`
- [ ] Verify no dependency conflicts

### Update Configuration
- [ ] Open lib/core/config/pocketbase_config.dart
- [ ] Replace baseUrl with your Fly.io URL
- [ ] Save file

### Initialize in App
- [ ] Open lib/main.dart
- [ ] Add PocketBaseService().initialize() in main()
- [ ] Save file

## ☐ Part 5: Testing & Verification

### Test Authentication
- [ ] Create test login code
- [ ] Run app
- [ ] Try logging in with admin credentials
- [ ] Verify login successful
- [ ] Check isAdmin returns true

### Test Expense Sync
- [ ] Create test expense sync code
- [ ] Run app
- [ ] Create a test expense
- [ ] Verify sync successful (returns record ID)
- [ ] Check admin dashboard for synced expense

### Verify in Admin Dashboard
- [ ] Open https://your-app.fly.dev/_/
- [ ] Login with admin credentials
- [ ] Go to expenses collection
- [ ] Verify test expense appears
- [ ] Check all fields are correct
- [ ] Verify image uploaded (if included)

## ☐ Final Verification

- [ ] Local PocketBase works
- [ ] Deployed PocketBase accessible
- [ ] Flutter app connects successfully
- [ ] Authentication works
- [ ] Expense sync works
- [ ] Admin can see all expenses
- [ ] Users can see only their expenses
- [ ] Images upload correctly

## Notes & Issues

Record any problems or important information:

```
Fly.io App Name: ___________________________

Fly.io URL: ___________________________

Admin Email: ___________________________

Admin Password: ___________________________

Issues Encountered:
_____________________________________________
_____________________________________________
_____________________________________________

Solutions:
_____________________________________________
_____________________________________________
_____________________________________________
```

## Next Steps

After completing this checklist:

1. ✅ Mark Task 1 as complete
2. ➡️ Proceed to Task 2: Implement build flavor configuration system
3. 🧪 Integrate sync service into expense creation flow
4. 📱 Test on real devices

## Quick Commands Reference

```bash
# Local PocketBase
./pocketbase serve

# Fly.io Commands
fly status                    # Check app status
fly logs                      # View logs
fly ssh console              # SSH into app
fly volumes list             # Check storage
fly apps restart <app-name>  # Restart app
fly dashboard                # Open web dashboard

# Flutter
flutter pub get              # Install dependencies
flutter run                  # Run app
flutter clean                # Clean build
```

## Troubleshooting Quick Fixes

**Can't connect to PocketBase:**
- Check URL in pocketbase_config.dart
- Verify Fly.io app is running: `fly status`
- Check logs: `fly logs`

**Authentication fails:**
- Verify user exists in admin dashboard
- Check email/password are correct
- Ensure role field is set

**Sync fails:**
- Check API rules in expenses collection
- Verify user is authenticated
- Check logs for error messages

**Image upload fails:**
- Verify file size < 5MB
- Check file type is image
- Ensure invoice_image field exists
