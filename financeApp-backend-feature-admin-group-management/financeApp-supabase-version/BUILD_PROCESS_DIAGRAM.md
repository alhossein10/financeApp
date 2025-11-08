# Build Process Diagram

## Flavor Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Finance App Project                      │
└─────────────────────────────────────────────────────────────┘
                              │
                              ├─────────────────┬──────────────────┐
                              ▼                 ▼                  ▼
                    ┌──────────────────┐ ┌──────────────┐ ┌──────────────┐
                    │   lib/main.dart  │ │main_admin.dart│ │main_user.dart│
                    │  (Shared Code)   │ │(Admin Entry) │ │(User Entry)  │
                    └──────────────────┘ └──────────────┘ └──────────────┘
                              │                 │                  │
                              │                 ▼                  ▼
                              │         ┌──────────────────────────────┐
                              │         │   FlavorConfig.initialize()  │
                              │         │   - Admin: Full features     │
                              │         │   - User: Limited features   │
                              │         └──────────────────────────────┘
                              │                 │                  │
                              └─────────────────┴──────────────────┘
                                                │
                                                ▼
                                    ┌───────────────────────┐
                                    │      MyApp Widget     │
                                    │  (Flavor-aware UI)    │
                                    └───────────────────────┘
```

## Build Flow

### Development Build (build_dev.bat)

```
┌─────────────────┐
│  Start Script   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Select Flavor:  │
│ 1. Admin        │
│ 2. User         │
│ 3. Both         │
└────────┬────────┘
         │
         ├──────────────────┬──────────────────┐
         ▼                  ▼                  ▼
┌──────────────┐   ┌──────────────┐   ┌──────────────┐
│ Build Admin  │   │  Build User  │   │  Build Both  │
│    Debug     │   │    Debug     │   │    Debug     │
└──────┬───────┘   └──────┬───────┘   └──────┬───────┘
       │                  │                  │
       ▼                  ▼                  ▼
┌──────────────────────────────────────────────────┐
│  Output: build/app/outputs/flutter-apk/          │
│  - app-admin-debug.apk                           │
│  - app-user-debug.apk                            │
└──────────────────────────────────────────────────┘
```

### Production Build (build_releases.bat)

```
┌─────────────────┐
│  Start Script   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Clean Releases  │
│   Directory     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Flutter Clean   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Flutter Pub Get │
└────────┬────────┘
         │
         ├──────────────────────────┬──────────────────────────┐
         ▼                          ▼                          ▼
┌──────────────────┐      ┌──────────────────┐      ┌──────────────────┐
│   Build User     │      │   Build User     │      │   Build Admin    │
│   APK Release    │      │   AAB Release    │      │   APK Release    │
└────────┬─────────┘      └────────┬─────────┘      └────────┬─────────┘
         │                         │                         │
         ▼                         ▼                         ▼
┌──────────────────┐      ┌──────────────────┐      ┌──────────────────┐
│ Copy to releases │      │ Copy to releases │      │ Copy to releases │
│ finance-user-    │      │ finance-user-    │      │ finance-admin-   │
│ release.apk      │      │ release.aab      │      │ release.apk      │
└──────────────────┘      └──────────────────┘      └────────┬─────────┘
                                                              │
                                                              ▼
                                                    ┌──────────────────┐
                                                    │   Build Admin    │
                                                    │   AAB Release    │
                                                    └────────┬─────────┘
                                                             │
                                                             ▼
                                                    ┌──────────────────┐
                                                    │ Copy to releases │
                                                    │ finance-admin-   │
                                                    │ release.aab      │
                                                    └────────┬─────────┘
                                                             │
         ┌───────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────┐
│  Output: releases/                              │
│  ✓ finance-user-release.apk                     │
│  ✓ finance-user-release.aab                     │
│  ✓ finance-admin-release.apk                    │
│  ✓ finance-admin-release.aab                    │
└─────────────────────────────────────────────────┘
```

## Clean Process (clean_build.bat)

```
┌─────────────────┐
│  Start Clean    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Stop Gradle    │
│    Daemons      │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Flutter Clean   │
└────────┬────────┘
         │
         ├──────────────┬──────────────┬──────────────┐
         ▼              ▼              ▼              ▼
┌──────────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐
│Remove android│ │  Remove  │ │  Remove  │ │  Remove  │
│  .gradle/    │ │android/  │ │  build/  │ │releases/ │
│              │ │app/build/│ │          │ │          │
└──────────────┘ └──────────┘ └──────────┘ └──────────┘
         │              │              │              │
         └──────────────┴──────────────┴──────────────┘
                              │
                              ▼
                    ┌──────────────────┐
                    │  Clean Complete  │
                    └──────────────────┘
```

## Flavor Decision Tree

```
                        ┌─────────────────┐
                        │  Which Flavor?  │
                        └────────┬────────┘
                                 │
                ┌────────────────┴────────────────┐
                ▼                                 ▼
        ┌───────────────┐                ┌───────────────┐
        │  Admin Flavor │                │  User Flavor  │
        └───────┬───────┘                └───────┬───────┘
                │                                │
                ▼                                ▼
    ┌───────────────────────┐        ┌───────────────────────┐
    │ Package:              │        │ Package:              │
    │ com.app.finance.admin │        │ com.app.finance.user  │
    │                       │        │                       │
    │ App Name:             │        │ App Name:             │
    │ Finance Admin         │        │ Finance               │
    │                       │        │                       │
    │ Features:             │        │ Features:             │
    │ ✓ Admin Dashboard     │        │ ✗ Admin Dashboard     │
    │ ✓ Database Mgmt       │        │ ✗ Database Mgmt       │
    │ ✓ User Management     │        │ ✗ User Management     │
    │ ✓ Cash Management     │        │ ✗ Cash Management     │
    │ ✓ Cashbox Module      │        │ ✗ Cashbox Module      │
    │ ✓ Currency Tools      │        │ ✓ Currency Tools      │
    │ ✓ Expenses            │        │ ✓ Expenses            │
    │ ✓ Export              │        │ ✓ Export              │
    └───────────────────────┘        └───────────────────────┘
```

## File Structure Flow

```
finance_app/
│
├── lib/
│   ├── main.dart ──────────────────┐
│   │                                │
│   ├── main_admin.dart ─────┐      │
│   │   └─> FlavorConfig     │      │
│   │       .initialize(     │      │
│   │         AppFlavor      │      │
│   │         .admin)        │      │
│   │                        │      │
│   ├── main_user.dart ──────┤      │
│   │   └─> FlavorConfig     │      │
│   │       .initialize(     │      │
│   │         AppFlavor      │      │
│   │         .user)         │      │
│   │                        │      │
│   └── core/                │      │
│       └── config/          │      │
│           └── flavor_      │      │
│               config.dart ─┴──────┴─> MyApp()
│
├── android/
│   └── app/
│       └── build.gradle.kts
│           ├─> productFlavors {
│           │     admin { ... }
│           │     user { ... }
│           │   }
│           └─> Generates APK/AAB
│
├── Scripts:
│   ├── clean_build.bat ──> Cleanup
│   ├── build_dev.bat ────> Debug APKs
│   └── build_releases.bat > Production APKs + AABs
│
└── Output:
    ├── build/app/outputs/flutter-apk/ (Debug)
    └── releases/ (Production)
```

## Command Flow Examples

### Example 1: Run Admin in Development

```
Command: flutter run --flavor admin -t lib/main_admin.dart
   │
   ├─> Reads: lib/main_admin.dart
   │     └─> Calls: FlavorConfig.initialize(AppFlavor.admin)
   │           └─> Sets: appName = "Finance Admin"
   │                     applicationId = "com.app.finance.admin"
   │                     enableCashModule = true
   │                     enableCashboxModule = true
   │                     ... (all features enabled)
   │
   ├─> Reads: android/app/build.gradle.kts
   │     └─> Uses: admin flavor configuration
   │
   └─> Launches: Finance Admin app on device
```

### Example 2: Build User Release

```
Command: flutter build apk --release --flavor user -t lib/main_user.dart
   │
   ├─> Reads: lib/main_user.dart
   │     └─> Calls: FlavorConfig.initialize(AppFlavor.user)
   │           └─> Sets: appName = "Finance"
   │                     applicationId = "com.app.finance.user"
   │                     enableCashModule = false
   │                     enableCashboxModule = false
   │                     ... (limited features)
   │
   ├─> Reads: android/app/build.gradle.kts
   │     └─> Uses: user flavor configuration
   │
   ├─> Compiles: Release mode (optimized)
   │
   └─> Outputs: build/app/outputs/flutter-apk/app-user-release.apk
```

## Distribution Flow

```
┌──────────────────┐
│  Development     │
│  (Your Machine)  │
└────────┬─────────┘
         │
         │ build_releases.bat
         │
         ▼
┌──────────────────┐
│  releases/       │
│  - APK files     │
│  - AAB files     │
└────────┬─────────┘
         │
         ├─────────────────────┬─────────────────────┐
         ▼                     ▼                     ▼
┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐
│  Direct Install  │  │  Google Play     │  │  Internal Test   │
│  (APK)           │  │  Store (AAB)     │  │  (APK/AAB)       │
│                  │  │                  │  │                  │
│  - Testing       │  │  - Production    │  │  - QA Team       │
│  - Beta Users    │  │  - Public Users  │  │  - Stakeholders  │
└──────────────────┘  └──────────────────┘  └──────────────────┘
```

## Quick Reference

| Action | Command |
|--------|---------|
| Clean | `clean_build.bat` |
| Dev Build | `build_dev.bat` |
| Production | `build_releases.bat` |
| Run Admin | `flutter run --flavor admin -t lib/main_admin.dart` |
| Run User | `flutter run --flavor user -t lib/main_user.dart` |

---

**Note:** This diagram shows the complete build and flavor system architecture. Refer to `BUILD_INSTRUCTIONS.md` for detailed step-by-step instructions.
