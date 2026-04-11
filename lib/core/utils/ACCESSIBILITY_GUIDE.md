# Accessibility Implementation Guide

This guide provides comprehensive information about accessibility features implemented in the Finance App.

## Requirements Coverage

This implementation addresses all requirements from Requirement 34:

- **34.1**: Semantic labels for all interactive elements
- **34.2**: Screen reader support (TalkBack, VoiceOver)
- **34.3**: Minimum contrast ratio of 4.5:1 for text
- **34.4**: Text scaling support up to 200%
- **34.5**: Alternative text for all images
- **34.6**: Minimum touch target size of 48dp
- **34.7**: Haptic feedback for important actions
- **34.8**: Avoid relying solely on color to convey information

## Components

### 1. AccessibilityUtils

Utility class providing accessibility helpers:

```dart
import 'package:finance_app/core/utils/accessibility_utils.dart';

// Haptic feedback
await AccessibilityUtils.buttonTapFeedback();
await AccessibilityUtils.importantActionFeedback();
await AccessibilityUtils.errorFeedback();
await AccessibilityUtils.successFeedback();
await AccessibilityUtils.selectionFeedback();

// Semantic labels
final currencyLabel = AccessibilityUtils.currencySemanticLabel(
  100.50,
  'USD',
  locale: 'en',
);

final dateLabel = AccessibilityUtils.dateSemanticLabel(
  DateTime.now(),
  locale: 'en',
);

// Contrast ratio checking
final ratio = AccessibilityUtils.calculateContrastRatio(
  Colors.black,
  Colors.white,
);

final meetsRequirement = AccessibilityUtils.meetsContrastRequirement(
  Colors.black,
  Colors.white,
);

// Announce to screen reader
AccessibilityUtils.announce(context, 'Operation completed successfully');
```

### 2. AccessibleButton

Button with proper touch targets, semantic labels, and haptic feedback:

```dart
import 'package:finance_app/core/widgets/accessible_button.dart';

AccessibleButton(
  label: 'Submit',
  onPressed: () => _handleSubmit(),
  icon: Icon(Icons.check),
  type: ButtonType.filled,
  semanticLabel: 'Submit form',
  tooltip: 'Submit the form',
)

AccessibleIconButton(
  icon: Icons.delete,
  onPressed: () => _handleDelete(),
  semanticLabel: 'Delete item',
  tooltip: 'Delete this item',
)

AccessibleFAB(
  icon: Icons.add,
  onPressed: () => _handleAdd(),
  semanticLabel: 'Add new expense',
  isExtended: true,
  extendedLabel: 'Add Expense',
)
```

### 3. AccessibleTextField

Text field with proper semantic labels and validation:

```dart
import 'package:finance_app/core/widgets/accessible_text_field.dart';

AccessibleTextField(
  controller: _emailController,
  label: 'Email',
  hint: 'Enter your email address',
  isRequired: true,
  keyboardType: TextInputType.emailAddress,
  validator: Validators.validateEmail,
)

AccessibleDropdown<String>(
  value: _selectedCurrency,
  items: [
    DropdownMenuItem(value: 'USD', child: Text('USD')),
    DropdownMenuItem(value: 'SYP', child: Text('SYP')),
    DropdownMenuItem(value: 'TRY', child: Text('TRY')),
  ],
  onChanged: (value) => setState(() => _selectedCurrency = value),
  label: 'Currency',
  isRequired: true,
)

AccessibleCheckbox(
  value: _rememberMe,
  onChanged: (value) => setState(() => _rememberMe = value ?? false),
  label: 'Remember me',
)

AccessibleSwitch(
  value: _notificationsEnabled,
  onChanged: (value) => setState(() => _notificationsEnabled = value),
  label: 'Enable notifications',
)
```

### 4. AccessibleImage

Image with proper alternative text and loading states:

```dart
import 'package:finance_app/core/widgets/accessible_image.dart';

AccessibleImage(
  imageUrl: 'https://example.com/image.jpg',
  altText: 'Profile picture of John Doe',
  width: 200,
  height: 200,
  fit: BoxFit.cover,
)

AccessibleAssetImage(
  assetPath: 'assets/images/logo.png',
  altText: 'Company logo',
  width: 100,
  height: 100,
)

AccessibleAvatar(
  imageUrl: user.profileImageUrl,
  name: user.name,
  radius: 24,
)
```

### 5. AccessibleListTile

List tile with proper semantic labels and touch targets:

```dart
import 'package:finance_app/core/widgets/accessible_list_tile.dart';

AccessibleListTile(
  title: 'Expense #123',
  subtitle: '\$50.00 - Office Supplies',
  leading: Icon(Icons.receipt),
  trailing: Icon(Icons.chevron_right),
  onTap: () => _viewExpense(),
  index: 0,
  totalItems: 10,
)

AccessibleCard(
  onTap: () => _handleTap(),
  semanticLabel: 'Balance card, USD 1,234.56',
  child: Column(
    children: [
      Text('USD Balance'),
      Text('\$1,234.56'),
    ],
  ),
)

AccessibleExpansionTile(
  title: 'Filter Options',
  children: [
    // Filter widgets
  ],
)
```

## Best Practices

### 1. Semantic Labels

Always provide meaningful semantic labels:

```dart
// Good
Semantics(
  label: 'Delete expense, double tap to confirm',
  button: true,
  child: IconButton(icon: Icon(Icons.delete), onPressed: _delete),
)

// Bad
IconButton(icon: Icon(Icons.delete), onPressed: _delete)
```

### 2. Touch Targets

Ensure all interactive elements meet minimum size:

```dart
// Good
AccessibilityUtils.ensureMinTouchTarget(
  child: IconButton(icon: Icon(Icons.edit), onPressed: _edit),
)

// Bad
IconButton(
  iconSize: 16, // Too small
  icon: Icon(Icons.edit),
  onPressed: _edit,
)
```

### 3. Contrast Ratios

Check contrast ratios for text:

```dart
final textColor = Colors.grey.shade700;
final backgroundColor = Colors.white;

if (!AccessibilityUtils.meetsContrastRequirement(textColor, backgroundColor)) {
  // Use a darker color
  textColor = Colors.grey.shade900;
}
```

### 4. Text Scaling

Support text scaling up to 200%:

```dart
// Good - Uses theme text styles that scale
Text(
  'Balance',
  style: Theme.of(context).textTheme.bodyLarge,
)

// Bad - Fixed font size
Text(
  'Balance',
  style: TextStyle(fontSize: 16), // Won't scale
)
```

### 5. Haptic Feedback

Provide haptic feedback for actions:

```dart
// Button tap
onPressed: () {
  AccessibilityUtils.buttonTapFeedback();
  _handleAction();
}

// Important action (delete, submit)
onPressed: () {
  AccessibilityUtils.importantActionFeedback();
  _handleDelete();
}

// Error
catch (e) {
  AccessibilityUtils.errorFeedback();
  _showError(e);
}

// Success
onSuccess: () {
  AccessibilityUtils.successFeedback();
  _showSuccess();
}
```

### 6. Screen Reader Announcements

Announce important state changes:

```dart
// After successful operation
AccessibilityUtils.announce(context, 'Expense created successfully');

// After error
AccessibilityUtils.announce(context, 'Error: Unable to save expense');

// With delay (for state changes)
await AccessibilityUtils.announceDelayed(
  context,
  'Balance updated',
  delay: Duration(milliseconds: 500),
);
```

### 7. Alternative Text for Images

Always provide descriptive alternative text:

```dart
// Good
AccessibleImage(
  imageUrl: expense.invoiceUrl,
  altText: 'Invoice for office supplies purchase on ${expense.date}',
)

// Bad
Image.network(expense.invoiceUrl) // No alt text
```

### 8. Color Independence

Don't rely solely on color:

```dart
// Good - Uses icon + color
Row(
  children: [
    Icon(Icons.error, color: Colors.red),
    Text('Error', style: TextStyle(color: Colors.red)),
  ],
)

// Bad - Color only
Container(
  color: Colors.red,
  child: Text('Error'),
)
```

## Testing Accessibility

### 1. Screen Reader Testing

**Android (TalkBack):**
1. Settings → Accessibility → TalkBack → Enable
2. Navigate using swipe gestures
3. Verify all elements are announced correctly

**iOS (VoiceOver):**
1. Settings → Accessibility → VoiceOver → Enable
2. Navigate using swipe gestures
3. Verify all elements are announced correctly

### 2. Text Scaling Testing

```dart
// Test with different text scale factors
MaterialApp(
  builder: (context, child) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaleFactor: 2.0, // Test at 200%
      ),
      child: child!,
    );
  },
)
```

### 3. Contrast Testing

Use the contrast checker utility:

```dart
void testContrast() {
  final theme = Theme.of(context);
  final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
  final backgroundColor = theme.scaffoldBackgroundColor;
  
  final ratio = AccessibilityUtils.calculateContrastRatio(
    textColor,
    backgroundColor,
  );
  
  print('Contrast ratio: $ratio');
  assert(ratio >= AccessibilityUtils.minContrastRatio);
}
```

### 4. Touch Target Testing

Enable visual debugging:

```dart
MaterialApp(
  debugShowCheckedModeBanner: false,
  showSemanticsDebugger: true, // Shows semantic boundaries
)
```

## Common Issues and Solutions

### Issue 1: Small Touch Targets

**Problem:** Buttons are too small to tap easily

**Solution:**
```dart
// Wrap with minimum touch target
AccessibilityUtils.ensureMinTouchTarget(
  child: IconButton(icon: Icon(Icons.edit), onPressed: _edit),
)
```

### Issue 2: Missing Semantic Labels

**Problem:** Screen reader doesn't announce element purpose

**Solution:**
```dart
// Add semantic label
Semantics(
  label: 'Edit expense',
  button: true,
  child: IconButton(icon: Icon(Icons.edit), onPressed: _edit),
)
```

### Issue 3: Poor Contrast

**Problem:** Text is hard to read

**Solution:**
```dart
// Check and adjust contrast
if (!AccessibilityUtils.meetsContrastRequirement(textColor, bgColor)) {
  textColor = Colors.black; // Use higher contrast color
}
```

### Issue 4: Text Doesn't Scale

**Problem:** Text remains small when user increases font size

**Solution:**
```dart
// Use theme text styles
Text(
  'Balance',
  style: Theme.of(context).textTheme.bodyLarge, // Scales automatically
)
```

### Issue 5: No Haptic Feedback

**Problem:** No tactile response when tapping buttons

**Solution:**
```dart
// Add haptic feedback
onPressed: () {
  AccessibilityUtils.buttonTapFeedback();
  _handleAction();
}
```

## Checklist

Use this checklist to ensure accessibility compliance:

- [ ] All interactive elements have semantic labels
- [ ] All buttons meet minimum touch target size (48dp)
- [ ] All text has sufficient contrast ratio (4.5:1)
- [ ] All text scales properly up to 200%
- [ ] All images have alternative text
- [ ] Haptic feedback provided for important actions
- [ ] Screen reader announces all elements correctly
- [ ] Color is not the only way to convey information
- [ ] Forms have proper validation and error messages
- [ ] Loading and error states are announced
- [ ] Navigation is keyboard accessible
- [ ] Focus indicators are visible

## Resources

- [Flutter Accessibility Guide](https://docs.flutter.dev/development/accessibility-and-localization/accessibility)
- [WCAG 2.1 Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)
- [Material Design Accessibility](https://material.io/design/usability/accessibility.html)
- [iOS Accessibility](https://developer.apple.com/accessibility/)
- [Android Accessibility](https://developer.android.com/guide/topics/ui/accessibility)
