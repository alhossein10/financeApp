# Finance App

A comprehensive financial management application with dual-version architecture supporting both Admin and User versions with cloud synchronization.

## Overview

This Flutter application provides financial tracking capabilities with two distinct versions:

- **Admin Version**: Full-featured application with all modules (Currency Exchange, Expenses, Invoice Export, Cash, Cashbox) and centralized oversight of all user data
- **User Version**: Simplified application with limited modules (Currency Exchange, Expenses, Invoice Export) that automatically syncs data to the Admin version

## Features

### Common Features (Both Versions)
- Currency Exchange Tool
- Expense Tracking with Invoice Management
- Invoice Export (PDF/Excel)
- Offline-first architecture with automatic cloud sync
- Multi-language support (English, Arabic)

### Admin-Only Features
- Cash Management Module
- Cashbox Management Module
- Admin Dashboard with user statistics
- View all user-submitted expenses
- Centralized invoice image access

### Synchronization
- One-way sync from User → Admin
- Automatic background sync every 5 minutes
- Offline support with queue-based sync
- Retry logic with exponential backoff
- Real-time sync status indicators

## Architecture

### Technology Stack
- **Frontend**: Flutter (Dart)
- **Local Database**: SQLite (sqflite)
- **Cloud Backend**: PocketBase
- **State Management**: BLoC (flutter_bloc)
- **Dependency Injection**: get_it
- **Image Processing**: image package
- **Connectivity**: connectivity_plus

### Build Flavors
The application uses Flutter build flavors to create two distinct versions from a single codebase:
- `admin` flavor: Full-featured admin version
- `user` flavor: Limited user version

## Prerequisites

Before building the application, ensure you have:

1. **Flutter SDK** (3.0.0 or higher)
   ```bash
   flutter --version
   ```

2. **Dart SDK** (3.0.0 or higher)

3. **Android Studio** or **Xcode** (for mobile builds)

4. **PocketBase Server** (for cloud sync functionality)
   - Download from: https://pocketbase.io/docs/
   - Or use Docker deployment (see Deployment Guide)

## Environment Configuration

### 1. PocketBase Configuration

Create a `.env` file in the project root (or configure in code):

```env
POCKETBASE_URL=http://your-pocketbase-server.com
```

Update `lib/core/services/pocketbase_service.dart` with your PocketBase URL:

```dart
final pb = PocketBase('http://your-pocketbase-server.com');
```

### 2. PocketBase Setup

Before running the application, you must set up PocketBase collections and rules:

1. Start your PocketBase server
2. Access the Admin UI at `http://localhost:8090/_/`
3. Import the schema from `pocketbase-backend-files/pb_schema.json`
4. Configure collection rules as documented in `pocketbase-backend-files/collection_rules.md`

See the [PocketBase Setup Guide](POCKETBASE_COMPLETE_SETUP_GUIDE.md) for detailed instructions.

## Building the Application

### Install Dependencies

```bash
flutter pub get
```

### Build Admin Version

#### Android (APK)
```bash
flutter build apk --flavor admin -t lib/main_admin.dart
```

#### Android (App Bundle for Play Store)
```bash
flutter build appbundle --flavor admin -t lib/main_admin.dart
```

#### iOS
```bash
flutter build ios --flavor admin -t lib/main_admin.dart
```

#### Web
```bash
flutter build web --target lib/main_admin.dart
```

### Build User Version

#### Android (APK)
```bash
flutter build apk --flavor user -t lib/main_user.dart
```

#### Android (App Bundle for Play Store)
```bash
flutter build appbundle --flavor user -t lib/main_user.dart
```

#### iOS
```bash
flutter build ios --flavor user -t lib/main_user.dart
```

#### Web
```bash
flutter build web --target lib/main_user.dart
```

## Running the Application

### Run Admin Version

```bash
# Run on connected device/emulator
flutter run --flavor admin -t lib/main_admin.dart

# Run on specific device
flutter run --flavor admin -t lib/main_admin.dart -d <device_id>

# Run in release mode
flutter run --flavor admin -t lib/main_admin.dart --release
```

### Run User Version

```bash
# Run on connected device/emulator
flutter run --flavor user -t lib/main_user.dart

# Run on specific device
flutter run --flavor user -t lib/main_user.dart -d <device_id>

# Run in release mode
flutter run --flavor user -t lib/main_user.dart --release
```

## Application IDs

The two versions use distinct application IDs to allow side-by-side installation:

- **Admin Version**: `com.app.finance.admin`
- **User Version**: `com.app.finance.user`

## iOS Build Configuration

For iOS builds, you need to configure schemes in Xcode:

1. Open `ios/Runner.xcworkspace` in Xcode
2. Follow the instructions in `ios/FLAVOR_SETUP_INSTRUCTIONS.md`
3. Configure separate schemes for Admin and User versions
4. Set distinct bundle identifiers:
   - Admin: `com.app.finance.admin`
   - User: `com.app.finance.user`

## Testing

### Run All Tests
```bash
flutter test
```

### Run Specific Test Files
```bash
# Unit tests
flutter test test/core/config/flavor_config_test.dart
flutter test test/core/services/pocketbase_storage_service_test.dart
flutter test test/core/services/cloud_sync_service_test.dart

# Integration tests
flutter test test/integration/sync_flow_integration_test.dart
```

### Run Tests with Coverage
```bash
flutter test --coverage
```

## Project Structure

```
lib/
├── core/
│   ├── config/
│   │   └── flavor_config.dart          # Build flavor configuration
│   ├── services/
│   │   ├── pocketbase_service.dart     # PocketBase client
│   │   ├── pocketbase_storage_service.dart  # Image storage
│   │   ├── cloud_sync_service.dart     # Synchronization logic
│   │   └── connectivity_service.dart   # Network monitoring
│   └── utils/
│       └── image_compression.dart      # Image optimization
├── features/
│   ├── admin/                          # Admin-only features
│   │   └── presentation/
│   │       ├── pages/
│   │       │   └── admin_dashboard_page.dart
│   │       └── bloc/
│   │           └── admin_bloc.dart
│   ├── expenses/                       # Expense tracking
│   ├── auth/                           # Authentication
│   └── ...
├── ui/
│   └── widgets/
│       └── sync_status_indicator.dart  # Sync status UI
├── main.dart                           # Default entry point
├── main_admin.dart                     # Admin flavor entry
└── main_user.dart                      # User flavor entry

pocketbase-backend-files/
├── pb_schema.json                      # PocketBase schema
├── collection_rules.md                 # Security rules
├── setup_collections.md                # Setup instructions
└── Dockerfile                          # Docker deployment
```

## Deployment

### Admin Version Distribution
The Admin version should be distributed internally:
- Use internal distribution platforms (Firebase App Distribution, TestFlight)
- Do NOT publish to public app stores
- Restrict access to authorized administrators only

### User Version Distribution
The User version can be distributed publicly:
- Google Play Store (Android)
- Apple App Store (iOS)
- Web hosting for web version

### PocketBase Deployment
See the [Deployment Guide](DEPLOYMENT_GUIDE.md) for detailed instructions on:
- Local PocketBase setup
- Docker deployment
- Render.com deployment
- Collection rules configuration
- Security best practices

## Troubleshooting

### Build Issues

**Problem**: Flavor not recognized
```
Error: Unknown flavor: admin
```
**Solution**: Ensure you're using the correct build command with `-t` flag:
```bash
flutter run --flavor admin -t lib/main_admin.dart
```

**Problem**: iOS build fails with bundle identifier conflict
**Solution**: Check Xcode scheme configuration and ensure distinct bundle identifiers are set

### Sync Issues

**Problem**: Expenses not syncing
**Solution**: 
1. Check PocketBase server is running and accessible
2. Verify network connectivity
3. Check sync status in the app UI
4. Review PocketBase collection rules

**Problem**: Image upload fails
**Solution**:
1. Check file size (images are compressed to max 1920px width)
2. Verify PocketBase file upload limits
3. Check storage quota

### PocketBase Connection Issues

**Problem**: Cannot connect to PocketBase
**Solution**:
1. Verify PocketBase URL in configuration
2. Check firewall/network settings
3. Ensure PocketBase server is running
4. Test connection: `curl http://your-pocketbase-url/api/health`

## Security Considerations

- Admin version requires admin-level authentication
- User data is isolated (users can only see their own data)
- PocketBase collection rules enforce role-based access control
- Invoice images are stored with proper access restrictions
- All API calls include authentication tokens
- Sensitive data is encrypted in local storage

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests: `flutter test`
5. Submit a pull request

## Documentation

- [PocketBase Setup Guide](POCKETBASE_COMPLETE_SETUP_GUIDE.md)
- [Deployment Guide](DEPLOYMENT_GUIDE.md)
- [Build Flavor Setup](BUILD_FLAVOR_SETUP_COMPLETE.md)
- [iOS Flavor Configuration](ios/FLAVOR_SETUP_INSTRUCTIONS.md)
- [Security Implementation](SECURITY_AUDIT_IMPLEMENTATION.md)

## License

[Add your license information here]

## Support

For issues and questions:
- Check the troubleshooting section above
- Review the documentation files
- Open an issue on the repository
