# Finance App - PocketBase Version

## Overview

This is the **PocketBase version** of the Finance App. It uses:
- **SQLite** for local storage
- **PocketBase** for cloud sync and authentication
- **Self-hosted backend** on Fly.io/Render

## Features

### ✅ Current Features:
- 📱 **Dual App Versions** - User and Admin apps
- 💰 **Multi-Currency Support** - USD, SYP, TRY
- 📊 **Expense Tracking** - Create, edit, delete expenses
- 💸 **Income Management** - Track incoming money
- 🔄 **Transfer Tracking** - Money transfers between accounts
- 📄 **Invoice Management** - Upload and manage receipts
- 🔐 **Authentication** - Secure user accounts
- ☁️ **Cloud Sync** - Real-time data synchronization
- 👨‍💼 **Admin Dashboard** - View all user data
- 📱 **Offline Support** - Works without internet
- 🌍 **Arabic Localization** - Full RTL support

### 🔄 Sync Features:
- **Real-time sync** between User and Admin apps
- **Offline-first** - Works without internet
- **Automatic retry** - Failed syncs retry automatically
- **Conflict resolution** - Handles sync conflicts
- **File upload** - Invoice images sync to cloud

## Quick Start

### 1. Deploy PocketBase Backend

Follow the deployment guide:
```bash
# See: FLYIO_QUICK_DEPLOY.md
fly launch
fly deploy
```

### 2. Update Configuration

```dart
// lib/core/config/pocketbase_config.dart
static const String baseUrl = 'https://your-app.fly.dev';
```

### 3. Build Apps

```bash
# User version
flutter build apk --flavor user --target lib/main_user.dart

# Admin version  
flutter build apk --flavor admin --target lib/main_admin.dart
```

### 4. Setup PocketBase Collections

Follow: `MANUAL_COLLECTION_SETUP.md`

## Architecture

### Backend Architecture:
```
PocketBase Server (Fly.io)
├── SQLite Database
├── File Storage
├── Authentication
├── Real-time Subscriptions
└── REST API
```

### App Architecture:
```
Flutter Apps
├── Local SQLite Database
├── PocketBase Sync Service
├── Offline-First Design
├── Clean Architecture
└── BLoC State Management
```

## Deployment

### Backend Deployment:
1. **Fly.io** (Recommended)
   - Free tier available
   - Easy deployment
   - Global CDN
   - See: `FLYIO_QUICK_DEPLOY.md`

2. **Render** (Alternative)
   - Free tier available
   - Docker support
   - See: `RENDER_POCKETBASE_DEPLOYMENT_GUIDE.md`

3. **Self-hosted** (Advanced)
   - Full control
   - Custom domain
   - See: `SETUP_LOCAL_POCKETBASE_SERVER.md`

### App Distribution:
- **Direct APK** - Install manually
- **Internal Testing** - Google Play Console
- **Enterprise** - MDM solutions

## Configuration

### Environment Setup:
```dart
// lib/core/config/pocketbase_config.dart
class PocketBaseConfig {
  static const String baseUrl = 'https://your-app.fly.dev';
  static const String usersCollection = 'users';
  static const String expensesCollection = 'expenses';
}
```

### Build Flavors:
- **User Flavor** - Regular user functionality
- **Admin Flavor** - Administrative features

## Sync Behavior

### User App → Admin App:
1. User creates expense locally
2. App syncs to PocketBase when online
3. Admin app fetches from PocketBase
4. Real-time updates via WebSocket

### Offline Handling:
1. All operations work offline
2. Changes queued for sync
3. Automatic sync when online
4. Conflict resolution on sync

## Performance

### Benchmarks:
- **Sync Speed**: ~500ms per expense
- **Offline Performance**: Native SQLite speed
- **File Upload**: Depends on connection
- **Real-time Updates**: <100ms latency

### Optimization:
- **Batch Sync** - Multiple items at once
- **Incremental Sync** - Only changed data
- **Compression** - Images compressed before upload
- **Caching** - Aggressive local caching

## Security

### Authentication:
- **Email/Password** - Standard authentication
- **JWT Tokens** - Secure session management
- **Role-based Access** - User/Admin roles
- **Session Timeout** - Automatic logout

### Data Protection:
- **HTTPS** - All communication encrypted
- **Local Encryption** - Sensitive data encrypted
- **Access Control** - User can only see own data
- **Admin Isolation** - Admin data separate

## Monitoring

### Server Monitoring:
```bash
# Check server status
fly status

# View logs
fly logs

# Monitor resources
fly dashboard
```

### App Monitoring:
- **Sync Status** - Visual indicators
- **Error Logging** - Detailed error messages
- **Performance Metrics** - Built-in analytics

## Troubleshooting

### Common Issues:

1. **Sync Not Working**
   - Check PocketBase URL
   - Verify internet connection
   - Check server status
   - See: `SYNC_TROUBLESHOOTING_GUIDE.md`

2. **Authentication Errors**
   - Clear app data
   - Check credentials
   - Verify server is running

3. **File Upload Failures**
   - Check file size limits
   - Verify storage permissions
   - Check network stability

### Debug Commands:
```bash
# Check PocketBase health
curl https://your-app.fly.dev/api/health

# View app logs
flutter logs

# Check sync status
# (Built into app UI)
```

## Development

### Local Development:
```bash
# Run PocketBase locally
./pocketbase serve

# Run Flutter app
flutter run --flavor user --target lib/main_user.dart
```

### Testing:
```bash
# Run tests
flutter test

# Integration tests
flutter test integration_test/
```

## Costs

### Fly.io Hosting:
- **Free Tier**: Perfect for development
- **Production**: ~$5-10/month
- **High Traffic**: Scales automatically

### Development:
- **Flutter**: Free
- **PocketBase**: Free (open source)
- **Total**: $0-10/month

## Support

### Documentation:
- `DEPLOYMENT_GUIDE.md` - Complete deployment guide
- `MANUAL_COLLECTION_SETUP.md` - Database setup
- `SYNC_TROUBLESHOOTING_GUIDE.md` - Sync issues
- `FLYIO_QUICK_DEPLOY.md` - Quick deployment

### Community:
- **PocketBase Docs**: https://pocketbase.io/docs/
- **Flutter Docs**: https://flutter.dev/docs
- **Fly.io Docs**: https://fly.io/docs/

## Comparison with Supabase Version

| Feature | PocketBase | Supabase |
|---------|------------|----------|
| **Setup** | 30 minutes | 15 minutes |
| **Cost** | $0-10/month | $0-25/month |
| **Control** | Full control | Managed |
| **Scaling** | Manual | Automatic |
| **Database** | SQLite | PostgreSQL |

See: `COMPARISON.md` for detailed comparison

## Migration

### To Supabase Version:
If you want to switch to Supabase later:
1. Export data from PocketBase
2. Follow `SUPABASE_MIGRATION_GUIDE.md`
3. Import data to Supabase
4. Switch to Supabase branch

### Data Export:
```bash
# Export PocketBase data
./pocketbase export

# Convert to Supabase format
# (Custom scripts available)
```

## Roadmap

### Planned Features:
- [ ] **Push Notifications** - Real-time alerts
- [ ] **Backup/Restore** - Data backup functionality
- [ ] **Multi-tenant** - Support multiple organizations
- [ ] **Advanced Analytics** - Detailed reporting
- [ ] **API Extensions** - Custom endpoints

### Performance Improvements:
- [ ] **Faster Sync** - Optimize sync algorithms
- [ ] **Better Caching** - Smarter cache strategies
- [ ] **Compression** - Better file compression
- [ ] **Batch Operations** - More efficient batching

## Contributing

### Development Setup:
```bash
# Clone repository
git clone https://github.com/alhossein10/financeApp.git
cd financeApp

# Switch to PocketBase version
git checkout main

# Install dependencies
flutter pub get

# Run locally
flutter run --flavor user
```

### Code Style:
- Follow Flutter/Dart conventions
- Use clean architecture principles
- Write tests for new features
- Document public APIs

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- **PocketBase** - Amazing backend-as-a-service
- **Flutter** - Excellent cross-platform framework
- **Fly.io** - Reliable hosting platform
- **Community** - All contributors and users

---

**Ready to deploy?** Start with `FLYIO_QUICK_DEPLOY.md` 🚀