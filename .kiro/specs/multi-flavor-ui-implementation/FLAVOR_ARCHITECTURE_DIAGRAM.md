# Flavor Architecture Diagram

## System Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                         Flutter Application                          │
│                                                                       │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐          │
│  │  SuperAdmin  │    │    Admin     │    │     User     │          │
│  │    Flavor    │    │   Flavor     │    │   Flavor     │          │
│  └──────┬───────┘    └──────┬───────┘    └──────┬───────┘          │
│         │                   │                    │                   │
│         │                   │                    │                   │
│  ┌──────▼───────────────────▼────────────────────▼───────┐          │
│  │           FlavorConfig (Singleton)                     │          │
│  │  • Feature Flags                                       │          │
│  │  • Navigation Destinations                             │          │
│  │  • Module Enable/Disable                               │          │
│  └────────────────────────────────────────────────────────┘          │
│                                                                       │
└─────────────────────────────────────────────────────────────────────┘
```

## Flavor Entry Points

```
┌─────────────────────────────────────────────────────────────────────┐
│                         Entry Point Layer                            │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  main_superadmin.dart          main_admin.dart          main_user.dart│
│         │                            │                        │       │
│         ├─ Initialize SuperAdmin     ├─ Initialize Admin     ├─ Init User│
│         ├─ Setup DI                  ├─ Setup DI             ├─ Setup DI│
│         ├─ Restore Auth              ├─ Restore Auth         ├─ Restore Auth│
│         └─ Run MyApp()               └─ Run MyApp()          └─ Run MyApp()│
│                                                                       │
│                              ▼                                        │
│                         main.dart                                     │
│                    (Backward Compatible)                              │
│                  Detects FLAVOR env var                               │
│                                                                       │
└─────────────────────────────────────────────────────────────────────┘
```

## Build Configuration Flow

```
┌─────────────────────────────────────────────────────────────────────┐
│                      Build Configuration                             │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  Android (build.gradle.kts)              iOS (xcconfig files)        │
│  ┌──────────────────────┐               ┌──────────────────────┐    │
│  │ Product Flavors:     │               │ Schemes:             │    │
│  │  • superAdmin        │               │  • SuperAdmin        │    │
│  │  • admin             │               │  • Admin             │    │
│  │  • user              │               │  • User              │    │
│  │                      │               │                      │    │
│  │ Application IDs:     │               │ Bundle IDs:          │    │
│  │  • .superadmin       │               │  • .superadmin       │    │
│  │  • .admin            │               │  • .admin            │    │
│  │  • .user             │               │  • .user             │    │
│  │                      │               │                      │    │
│  │ App Names:           │               │ Display Names:       │    │
│  │  • strings.xml       │               │  • xcconfig          │    │
│  └──────────────────────┘               └──────────────────────┘    │
│                                                                       │
└─────────────────────────────────────────────────────────────────────┘
```

## Feature Flag Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                         Feature Flags                                │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  SuperAdmin Flags          Admin Flags              User Flags       │
│  ┌──────────────┐         ┌──────────────┐        ┌──────────────┐  │
│  │ ✅ Manage    │         │ ✅ Manage    │        │ ❌ Manage    │  │
│  │    Group     │         │    Group     │        │    Group     │  │
│  │              │         │              │        │              │  │
│  │ ✅ View      │         │ ❌ View      │        │ ❌ View      │  │
│  │    Analytics │         │    Analytics │        │    Analytics │  │
│  │              │         │              │        │              │  │
│  │ ✅ Transfer  │         │ ✅ Transfer  │        │ ❌ Transfer  │  │
│  │    Funds     │         │    Funds     │        │    Funds     │  │
│  │              │         │              │        │              │  │
│  │ ❌ Create    │         │ ✅ Create    │        │ ✅ Create    │  │
│  │    Expenses  │         │    Expenses  │        │    Expenses  │  │
│  │              │         │              │        │              │  │
│  │ ❌ Exchange  │         │ ✅ Exchange  │        │ ✅ Exchange  │  │
│  │    Currency  │         │    Currency  │        │    Currency  │  │
│  │              │         │              │        │              │  │
│  │ ❌ Export    │         │ ✅ Export    │        │ ✅ Export    │  │
│  │    Data      │         │    Data      │        │    Data      │  │
│  └──────────────┘         └──────────────┘        └──────────────┘  │
│                                                                       │
└─────────────────────────────────────────────────────────────────────┘
```

## Navigation Structure

```
┌─────────────────────────────────────────────────────────────────────┐
│                      Navigation Destinations                         │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  SuperAdmin                Admin                   User              │
│  ┌──────────────┐         ┌──────────────┐        ┌──────────────┐  │
│  │ 1. Groups    │         │ 1. Groups    │        │ 1. Home      │  │
│  │    🏢        │         │    🏢        │        │    🏠        │  │
│  │              │         │              │        │              │  │
│  │ 2. Cash      │         │ 2. Cash      │        │ 2. Exchange  │  │
│  │    💰        │         │    💰        │        │    💱        │  │
│  │              │         │              │        │              │  │
│  │ 3. Transfers │         │ 3. Exchange  │        │ 3. Expenses  │  │
│  │    🔄        │         │    💱        │        │    🧾        │  │
│  │              │         │              │        │              │  │
│  │ 4. Analytics │         │ 4. Expenses  │        │ 4. Export    │  │
│  │    📊        │         │    🧾        │        │    📤        │  │
│  │              │         │              │        │              │  │
│  │ 5. Profile   │         │ 5. Export    │        │ 5. Profile   │  │
│  │    👤        │         │    📤        │        │    👤        │  │
│  │              │         │              │        │              │  │
│  │              │         │ 6. Profile   │        │              │  │
│  │              │         │    👤        │        │              │  │
│  └──────────────┘         └──────────────┘        └──────────────┘  │
│                                                                       │
└─────────────────────────────────────────────────────────────────────┘
```

## Module Availability Matrix

```
┌─────────────────────────────────────────────────────────────────────┐
│                      Module Availability                             │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  Module                  SuperAdmin    Admin       User              │
│  ─────────────────────────────────────────────────────────          │
│  Cash Module                 ✅          ✅          ❌              │
│  Cashbox Module              ✅          ✅          ❌              │
│  Currency Module             ❌          ✅          ✅              │
│  Expenses Module             ✅          ✅          ✅              │
│  Export Module               ❌          ✅          ✅              │
│  Admin Dashboard             ❌          ✅          ❌              │
│  Fund Box                    ✅          ✅          ✅              │
│  Audit Logs                  ✅          ✅          ❌              │
│  User Management             ✅          ✅          ❌              │
│  SuperAdmin Cash Page        ✅          ❌          ❌              │
│  SuperAdmin Expenses Page    ✅          ❌          ❌              │
│                                                                       │
└─────────────────────────────────────────────────────────────────────┘
```

## Data Flow Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                         Data Flow                                    │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  User Interaction                                                    │
│         │                                                            │
│         ▼                                                            │
│  ┌──────────────┐                                                    │
│  │   UI Layer   │                                                    │
│  │  (Widgets)   │                                                    │
│  └──────┬───────┘                                                    │
│         │                                                            │
│         │ Check Feature Flag                                         │
│         ▼                                                            │
│  ┌──────────────────────┐                                            │
│  │   FlavorConfig       │                                            │
│  │  .isFeatureEnabled() │                                            │
│  └──────┬───────────────┘                                            │
│         │                                                            │
│         ├─ Allowed ──────────────┐                                   │
│         │                        │                                   │
│         │                        ▼                                   │
│         │                 ┌──────────────┐                           │
│         │                 │  BLoC/State  │                           │
│         │                 │  Management  │                           │
│         │                 └──────┬───────┘                           │
│         │                        │                                   │
│         │                        ▼                                   │
│         │                 ┌──────────────┐                           │
│         │                 │  Repository  │                           │
│         │                 └──────┬───────┘                           │
│         │                        │                                   │
│         │                        ▼                                   │
│         │                 ┌──────────────┐                           │
│         │                 │  API/Cache   │                           │
│         │                 └──────────────┘                           │
│         │                                                            │
│         └─ Denied ──────────────┐                                    │
│                                 │                                    │
│                                 ▼                                    │
│                          Show Error/Hide UI                          │
│                                                                       │
└─────────────────────────────────────────────────────────────────────┘
```

## Build Process Flow

```
┌─────────────────────────────────────────────────────────────────────┐
│                      Build Process                                   │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  flutter build apk --flavor admin -t lib/main_admin.dart            │
│         │                                                            │
│         ▼                                                            │
│  ┌──────────────────────┐                                            │
│  │  Gradle reads        │                                            │
│  │  build.gradle.kts    │                                            │
│  └──────┬───────────────┘                                            │
│         │                                                            │
│         ▼                                                            │
│  ┌──────────────────────┐                                            │
│  │  Select 'admin'      │                                            │
│  │  product flavor      │                                            │
│  └──────┬───────────────┘                                            │
│         │                                                            │
│         ▼                                                            │
│  ┌──────────────────────┐                                            │
│  │  Apply flavor        │                                            │
│  │  configuration:      │                                            │
│  │  • App ID            │                                            │
│  │  • App Name          │                                            │
│  │  • Resources         │                                            │
│  └──────┬───────────────┘                                            │
│         │                                                            │
│         ▼                                                            │
│  ┌──────────────────────┐                                            │
│  │  Compile with        │                                            │
│  │  main_admin.dart     │                                            │
│  └──────┬───────────────┘                                            │
│         │                                                            │
│         ▼                                                            │
│  ┌──────────────────────┐                                            │
│  │  Initialize          │                                            │
│  │  FlavorConfig.admin  │                                            │
│  └──────┬───────────────┘                                            │
│         │                                                            │
│         ▼                                                            │
│  ┌──────────────────────┐                                            │
│  │  Generate APK with   │                                            │
│  │  admin configuration │                                            │
│  └──────────────────────┘                                            │
│                                                                       │
└─────────────────────────────────────────────────────────────────────┘
```

## Runtime Flavor Detection

```
┌─────────────────────────────────────────────────────────────────────┐
│                   Runtime Initialization                             │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  App Launch                                                          │
│      │                                                               │
│      ▼                                                               │
│  main_[flavor].dart                                                  │
│      │                                                               │
│      ├─ WidgetsFlutterBinding.ensureInitialized()                   │
│      │                                                               │
│      ├─ FlavorConfig.initialize(AppFlavor.[flavor])                 │
│      │      │                                                        │
│      │      ├─ Create FlavorConfig instance                         │
│      │      ├─ Set feature flags                                    │
│      │      ├─ Set navigation destinations                          │
│      │      └─ Store as singleton                                   │
│      │                                                               │
│      ├─ await di.initializeDependencies()                           │
│      │      │                                                        │
│      │      ├─ Register repositories                                │
│      │      ├─ Register BLoCs                                       │
│      │      ├─ Register services                                    │
│      │      └─ Configure API client                                 │
│      │                                                               │
│      ├─ await di.restoreAuthToken()                                 │
│      │      │                                                        │
│      │      └─ Load saved auth state                                │
│      │                                                               │
│      └─ runApp(MyApp())                                              │
│             │                                                        │
│             ├─ Build MaterialApp                                    │
│             ├─ Set app title from FlavorConfig                      │
│             ├─ Configure routes                                     │
│             └─ Show AuthenticationWrapper                           │
│                                                                       │
└─────────────────────────────────────────────────────────────────────┘
```

## Flavor Isolation

```
┌─────────────────────────────────────────────────────────────────────┐
│                      Flavor Isolation                                │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  Device                                                              │
│  ┌────────────────────────────────────────────────────────┐         │
│  │                                                         │         │
│  │  ┌──────────────────┐  ┌──────────────────┐           │         │
│  │  │  Finance         │  │  Finance Admin   │           │         │
│  │  │  SuperAdmin      │  │                  │           │         │
│  │  │                  │  │  App ID:         │           │         │
│  │  │  App ID:         │  │  .admin          │           │         │
│  │  │  .superadmin     │  │                  │           │         │
│  │  │                  │  │  Data:           │           │         │
│  │  │  Data:           │  │  /data/admin/    │           │         │
│  │  │  /data/super/    │  │                  │           │         │
│  │  │                  │  │  Features:       │           │         │
│  │  │  Features:       │  │  • Groups        │           │         │
│  │  │  • Groups        │  │  • Cash          │           │         │
│  │  │  • Cash          │  │  • Exchange      │           │         │
│  │  │  • Transfers     │  │  • Expenses      │           │         │
│  │  │  • Analytics     │  │  • Export        │           │         │
│  │  └──────────────────┘  └──────────────────┘           │         │
│  │                                                         │         │
│  │  ┌──────────────────┐                                  │         │
│  │  │  Finance         │                                  │         │
│  │  │                  │                                  │         │
│  │  │  App ID:         │                                  │         │
│  │  │  .user           │                                  │         │
│  │  │                  │                                  │         │
│  │  │  Data:           │                                  │         │
│  │  │  /data/user/     │                                  │         │
│  │  │                  │                                  │         │
│  │  │  Features:       │                                  │         │
│  │  │  • Home          │                                  │         │
│  │  │  • Exchange      │                                  │         │
│  │  │  • Expenses      │                                  │         │
│  │  │  • Export        │                                  │         │
│  │  └──────────────────┘                                  │         │
│  │                                                         │         │
│  │  All three apps can coexist on same device             │         │
│  │  Each has separate data storage                        │         │
│  │  Each has unique app identifier                        │         │
│  │                                                         │         │
│  └─────────────────────────────────────────────────────────┘         │
│                                                                       │
└─────────────────────────────────────────────────────────────────────┘
```

## Summary

This architecture provides:

1. **Complete Separation**: Each flavor is a distinct app with unique ID
2. **Shared Codebase**: Maximum code reuse through shared components
3. **Feature Control**: Granular feature flags for precise control
4. **Navigation Flexibility**: Pre-configured navigation per flavor
5. **Build Simplicity**: Single command builds any flavor
6. **Runtime Safety**: Compile-time and runtime checks prevent unauthorized access
7. **Testability**: Each flavor can be tested independently
8. **Scalability**: Easy to add new flavors or modify existing ones

The flavor system ensures that:
- SuperAdmins manage Admins and view analytics
- Admins manage Users and handle group operations
- Users track personal finances independently
- All three can coexist on the same device
- Features are properly isolated per role
