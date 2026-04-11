# Multi-Flavor Application UI Implementation

## Overview

This specification defines the complete implementation of a three-flavor Finance application system with distinct user experiences for Superadmin, Admin, and User roles. The system uses Flutter's flavor system to create separate applications while maximizing code reuse.

## Specification Documents

- **[requirements.md](./requirements.md)**: Complete requirements with 35 user stories and acceptance criteria
- **[design.md](./design.md)**: Comprehensive architecture and component design
- **[tasks.md](./tasks.md)**: Implementation plan with 30 major tasks and 100+ subtasks

## Key Features

### Superadmin Flavor
- Group code generation on registration
- Admin group management with member viewing
- Financial box with manual incoming amounts
- USD-only transfers to Admins
- Aggregated analytics across all Admin groups
- No expense creation, exchange, or export features

### Admin Flavor
- Join Superadmin group using group code
- User group management
- Financial box with incoming from Superadmin and outgoing to Users
- Currency exchange (USD → SYP/TRY)
- Exchange log for Admin and all group Users
- Expense management for Admin and all group Users
- Export functionality (PDF, Excel, image bundle)

### User Flavor
- Join Admin group using group code
- Personal financial box with incoming transfers
- Currency exchange (USD → SYP/TRY)
- Personal exchange log
- Personal expense management
- Export functionality for personal data

## Technical Stack

- **Framework**: Flutter
- **State Management**: BLoC pattern
- **API Integration**: Laravel backend (v3.1 API)
- **Local Storage**: Hive/SQLite for caching
- **Secure Storage**: flutter_secure_storage
- **Image Handling**: image_picker, image_compression
- **Localization**: flutter_localizations (English, Arabic)
- **Testing**: flutter_test, mockito, integration_test

## Architecture Highlights

### Flavor System
- Three separate main entry points
- Flavor-specific configuration with feature flags
- Shared components with flavor-aware behavior
- Independent app identifiers and names

### Data Models
- Multi-currency support (USD, SYP, TRY)
- Group hierarchy (Superadmin → Admin → User)
- Enhanced models with profile images
- Balance-based exchanges

### Key Services
- BalanceVerificationService: Pre-operation balance checks
- FilterPersistenceService: Cross-page filter persistence
- ImageUploadService: Profile image handling
- OfflineQueueService: Operation queuing when offline

## Implementation Approach

### Phase 1: Foundation (Tasks 1-5)
Set up flavor configuration, data models, balance verification, authentication flows, and navigation structure.

### Phase 2: Core Features (Tasks 6-14)
Implement group management, financial box, transfers, exchanges, expenses, export, and analytics for all flavors.

### Phase 3: Enhancement (Tasks 15-17)
Add profile images, filter persistence, and offline support.

### Phase 4: Polish (Tasks 18-23)
Implement loading states, error handling, localization, accessibility, responsive design, performance optimization, and security.

### Phase 5: Quality Assurance (Tasks 24-27)
Comprehensive testing including unit tests, widget tests, integration tests, and flavor-specific tests.

### Phase 6: Deployment (Tasks 28-30)
Build configuration, deployment scripts, documentation, and final testing.

## Getting Started

### Prerequisites
- Flutter SDK (latest stable)
- Android Studio / Xcode
- Laravel backend running (see backend repository)
- Postman collection for API testing

### Running Different Flavors

```bash
# Superadmin flavor
flutter run --flavor superadmin --target lib/main_superadmin.dart

# Admin flavor
flutter run --flavor admin --target lib/main_admin.dart

# User flavor
flutter run --flavor user --target lib/main_user.dart
```

### Building APKs

```bash
# Superadmin APK
flutter build apk --flavor superadmin --target lib/main_superadmin.dart

# Admin APK
flutter build apk --flavor admin --target lib/main_admin.dart

# User APK
flutter build apk --flavor user --target lib/main_user.dart
```

## Testing

### Run All Tests
```bash
flutter test
```

### Run Integration Tests
```bash
flutter test integration_test/
```

### Run Tests for Specific Flavor
```bash
flutter test --flavor superadmin
flutter test --flavor admin
flutter test --flavor user
```

## Key Design Decisions

### Why Three Separate Flavors?
- Clear separation of concerns
- Role-specific user experience
- Independent deployment and updates
- Simplified navigation and feature access
- Better security through feature isolation

### Why Balance Verification Service?
- Prevent overspending before API call
- Better user experience with immediate feedback
- Reduce unnecessary API calls
- Client-side validation for financial operations

### Why Filter Persistence?
- Seamless user experience between Expenses and Export
- Maintain user context during navigation
- Reduce repetitive filter selection
- Consistent data view across related pages

### Why Offline Support?
- Work without internet connection
- Queue operations for later sync
- Display cached data
- Better user experience in poor connectivity

## Data Visibility Rules

### Superadmin Can View:
- All Admins in their group
- Admin profile images and financial boxes
- Aggregated analytics from all Admin groups
- Expenses grouped by Admin group (read-only)

### Admin Can View:
- All Users in their group
- User profile images and financial data
- All expenses from Admin and Users
- All exchanges from Admin and Users
- Group-wide financial interactions

### User Can View:
- Only their own financial data
- Only their own expenses
- Only their own exchange history
- Incoming transfers from their Admin
- Their group information

## Financial Tracking Constraints

All financial operations (transfers, exchanges, expenses) require:
1. **Pre-operation balance check** on client side
2. **Sufficient balance** in the required currency
3. **Immediate rejection** if balance insufficient
4. **Clear error message** with current balance
5. **Balance refresh** after successful operation

## Security Considerations

- Tokens stored in secure storage
- Auto-logout after 30 minutes inactivity
- HTTPS for all API communications
- Certificate pinning
- Encrypted sensitive data at rest
- Role-based access control
- Input validation on all forms

## Localization

- **Supported Languages**: English, Arabic
- **RTL Support**: Full RTL layout for Arabic
- **Number Formatting**: Locale-specific
- **Date Formatting**: Locale-specific
- **Currency Formatting**: Currency-specific symbols

## Accessibility

- Screen reader support (TalkBack, VoiceOver)
- Minimum contrast ratio 4.5:1
- Text scaling up to 200%
- Minimum touch target 48dp
- Semantic labels for all elements
- Haptic feedback for actions
- Alternative text for images

## Performance Targets

- Home page load: < 2 seconds (4G)
- List scrolling: 60fps
- Image compression: < 1MB
- Pagination: 15 items per page (max 100)
- API response cache: Frequently accessed data
- Smooth animations: 60fps

## Contributing

When implementing tasks:
1. Read the requirements and design documents
2. Follow the task order in tasks.md
3. Mark tasks as in-progress before starting
4. Write tests alongside implementation
5. Update documentation as needed
6. Mark tasks as complete when done
7. Request code review before merging

## Support

For questions or issues:
- Review the requirements.md for feature specifications
- Check design.md for implementation guidance
- Consult tasks.md for task details
- Review existing similar implementations
- Contact the development team

## License

[Your License Here]

## Changelog

### Version 1.0.0 (Initial Spec)
- Complete requirements specification (35 requirements)
- Comprehensive design document
- Detailed implementation plan (30 tasks, 100+ subtasks)
- Three-flavor architecture
- Multi-currency support
- Group-based hierarchy
- Balance verification system
- Offline support
- Localization (English, Arabic)
- Accessibility compliance
