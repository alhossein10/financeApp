# Fly.io Quick Deploy Guide for PocketBase

## Why Fly.io?

✅ **Free tier** - No credit card required for testing
✅ **Persistent storage** - Your data is safe
✅ **Easy deployment** - 5 commands and you're done
✅ **Global CDN** - Fast from anywhere
✅ **Perfect for PocketBase** - Designed for apps like this

## Prerequisites

- Fly.io account (free): https://fly.io/app/sign-up
- Fly CLI installed

## Step 1: Install Fly CLI (2 minutes)

### Windows:
```powershell
powershell -Command "iwr https://fly.io/install.ps1 -useb | iex"
```

### Mac/Linux:
```bash
curl -L https://fly.io/install.sh | sh
```

## Step 2: Login to Fly.io (1 minute)

```bash
fly auth login
```

This opens your browser to login.

## Step 3: Create fly.toml (1 minute)

Create a file `fly.toml` in your `pocketbase-backend-files` folder:

```toml
app = "your-finance-app"  # Change this to your app name

[build]
  image = "ghcr.io/muchobien/pocketbase:latest"

[env]
  PB_ADMIN_EMAIL = "admin@example.com"
  PB_ADMIN_PASSWORD = "your-secure-password-here"

[[services]]
  internal_port = 8090
  protocol = "tcp"

  [[services.ports]]
    handlers = ["http"]
    port = 80

  [[services.ports]]
    handlers = ["tls", "http"]
    port = 443

[mounts]
  source = "pb_data"
  destination = "/pb_data"
```

## Step 4: Deploy (2 minutes)

```bash
cd pocketbase-backend-files
fly launch --no-deploy
fly volumes create pb_data --size 1
fly deploy
```

## Step 5: Get Your URL (1 minute)

```bash
fly info
```

You'll see something like:
```
Hostname = your-finance-app.fly.dev
```

That's your URL! 🎉

## Step 6: Update Your Flutter App (1 minute)

```dart
// File: lib/core/config/pocketbase_config.dart
static const String baseUrl = 'https://your-finance-app.fly.dev';
```

## Step 7: Setup PocketBase (5 minutes)

1. Open: `https://your-finance-app.fly.dev/_/`
2. Login with the admin credentials from fly.toml
3. Follow `MANUAL_COLLECTION_SETUP.md` to create collections

## Step 8: Rebuild Apps (5 minutes)

```bash
flutter build apk --flavor user --target lib/main_user.dart
flutter build apk --flavor admin --target lib/main_admin.dart
```

## Done! 🎉

Total time: ~15 minutes

Your PocketBase is now:
- ✅ Running in the cloud
- ✅ Accessible from anywhere
- ✅ Free (within limits)
- ✅ Persistent storage
- ✅ Ready for sync!

## Useful Commands

### Check logs:
```bash
fly logs
```

### Check status:
```bash
fly status
```

### Open admin UI:
```bash
fly open
# Then add /_/ to the URL
```

### Scale up (if needed):
```bash
fly scale vm shared-cpu-1x
```

### Check storage:
```bash
fly volumes list
```

## Free Tier Limits

Fly.io free tier includes:
- ✅ 3 shared-cpu-1x VMs
- ✅ 3GB persistent storage
- ✅ 160GB outbound data transfer

This is MORE than enough for your finance app!

## Troubleshooting

### "App name already taken"
Change the app name in fly.toml to something unique.

### "Volume not found"
Make sure you created the volume:
```bash
fly volumes create pb_data --size 1
```

### "Can't connect to PocketBase"
Check if it's running:
```bash
fly status
```

### "Admin UI not loading"
Make sure you're using `/_/` at the end:
```
https://your-app.fly.dev/_/
```

## Cost Estimate

For your app:
- **Development/Testing**: FREE ✅
- **Production (small scale)**: FREE ✅
- **Production (larger scale)**: ~$5-10/month

## Next Steps

1. Deploy to Fly.io (follow this guide)
2. Update URL in Flutter app
3. Rebuild apps
4. Setup collections
5. Test sync
6. Celebrate! 🎉

## Alternative: Render

If you prefer Render instead:
- Follow: `RENDER_POCKETBASE_DEPLOYMENT_GUIDE.md`
- Similar process, different platform
- Also has free tier

## Questions?

**Q: Do I need a credit card?**
A: Not for the free tier!

**Q: Will my data be safe?**
A: Yes! Fly.io has persistent volumes.

**Q: Can I use a custom domain?**
A: Yes! Fly.io supports custom domains.

**Q: What if I exceed free tier?**
A: Fly.io will notify you. You can upgrade or optimize.

**Q: Can I migrate later?**
A: Yes! PocketBase data is portable.
