# Watermark Background Implementation

## Overview
Added the eagle logo (`assets/images/eagle_with_text.png`) as a centered watermark background to all major pages in both admin and user flavors.

## Implementation

### 1. Created Reusable Widget
**File:** `lib/core/widgets/watermark_background.dart`

A reusable `WatermarkBackground` widget that:
- Displays the eagle logo as a centered, semi-transparent background
- Default opacity: 0.05 (5%) - subtle and non-intrusive
- Responsive sizing: 60% of screen width
- Can be customized with different opacity values

### 2. Updated Pages

#### Admin Flavor Pages:
- ✅ Admin Dashboard (`admin_dashboard_page.dart`)
- ✅ Group Management (`group_management_page.dart`)
- ✅ Expense Page (`expense_page.dart`)
- ✅ Cash Inbox Page (`cash_inbox_page.dart`)
- ✅ Export Page (`export_page.dart`)
- ✅ Currency Tool (`currency_tool_page.dart`)

#### User Flavor Pages:
- ✅ User Exchange Page (`user_exchange_page.dart`)
- ✅ Profile Page (`profile_page.dart`)
- ✅ Expense Page (`expense_page.dart`)
- ✅ Cash Inbox Page (`cash_inbox_page.dart`)
- ✅ Export Page (`export_page.dart`)
- ✅ Currency Tool (`currency_tool_page.dart`)

#### Auth Pages (Both Flavors):
- ✅ Login Page (`login_page.dart`)
- ✅ Register Page (`register_page.dart`)

## Usage

To add watermark to any new page:

```dart
import 'package:your_app/core/widgets/watermark_background.dart';

// Wrap your page body with WatermarkBackground
body: WatermarkBackground(
  child: YourPageContent(),
),

// Or customize opacity
body: WatermarkBackground(
  opacity: 0.08, // More visible
  child: YourPageContent(),
),
```

## Asset Configuration

The watermark image is already configured in `pubspec.yaml`:
```yaml
assets:
  - assets/images/
```

This includes `assets/images/eagle_with_text.png`.

## Visual Impact

- **Subtle branding**: The watermark is visible but doesn't interfere with content
- **Professional appearance**: Adds brand identity to every page
- **Consistent experience**: Same watermark across admin and user flavors
- **Performance**: Minimal impact as it's a single cached image

## Testing

All updated files have been validated with no syntax or compilation errors.
