# Accessibility Quick Reference

## Quick Start

### Import Accessibility Utils
```dart
import 'package:finance_app/core/utils/accessibility_utils.dart';
import 'package:finance_app/core/widgets/accessible_button.dart';
import 'package:finance_app/core/widgets/accessible_text_field.dart';
import 'package:finance_app/core/widgets/accessible_image.dart';
import 'package:finance_app/core/widgets/accessible_list_tile.dart';
```

## Common Patterns

### 1. Accessible Button
```dart
AccessibleButton(
  label: 'Submit',
  onPressed: () => _handleSubmit(),
  icon: Icon(Icons.check),
  semanticLabel: 'Submit expense form',
)
```

### 2. Accessible Text Field
```dart
AccessibleTextField(
  controller: _controller,
  label: 'Email',
  hint: 'Enter your email',
  isRequired: true,
  validator: Validators.validateEmail,
)
```

### 3. Accessible Image
```dart
AccessibleImage(
  imageUrl: imageUrl,
  altText: 'Invoice for office supplies',
  width: 200,
  height: 200,
)
```

### 4. Haptic Feedback
```dart
// Button tap
onPressed: () {
  AccessibilityUtils.buttonTapFeedback();
  _handleAction();
}

// Important action
onPressed: () {
  AccessibilityUtils.importantActionFeedback();
  _handleDelete();
}

// Error
catch (e) {
  AccessibilityUtils.errorFeedback();
}

// Success
onSuccess: () {
  AccessibilityUtils.successFeedback();
}
```

### 5. Screen Reader Announcements
```dart
// Immediate announcement
AccessibilityUtils.announce(context, 'Expense saved');

// Delayed announcement
await AccessibilityUtils.announceDelayed(
  context,
  'Balance updated',
  delay: Duration(milliseconds: 500),
);
```

### 6. Semantic Labels
```dart
// Currency
final label = AccessibilityUtils.currencySemanticLabel(
  100.50,
  'USD',
  locale: 'en',
);

// Date
final label = AccessibilityUtils.dateSemanticLabel(
  DateTime.now(),
  locale: 'en',
);

// Form field
final label = AccessibilityUtils.formFieldSemanticLabel(
  label: 'Email',
  isRequired: true,
  hint: 'Enter your email',
);
```

### 7. Contrast Checking
```dart
final ratio = AccessibilityUtils.calculateContrastRatio(
  textColor,
  backgroundColor,
);

if (!AccessibilityUtils.meetsContrastRequirement(textColor, backgroundColor)) {
  // Use higher contrast color
  textColor = Colors.black;
}
```

### 8. Touch Target Size
```dart
// Ensure minimum size
AccessibilityUtils.ensureMinTouchTarget(
  child: IconButton(icon: Icon(Icons.edit), onPressed: _edit),
)
```

## Checklist

Before releasing a feature, verify:

- [ ] All buttons have semantic labels
- [ ] All text fields have proper labels
- [ ] All images have alt text
- [ ] Touch targets are at least 48dp
- [ ] Haptic feedback on important actions
- [ ] Text uses theme styles (scales properly)
- [ ] Contrast ratios meet 4.5:1
- [ ] Screen reader tested
- [ ] Color not sole indicator

## Testing

### Screen Reader
- **Android**: Enable TalkBack in Settings
- **iOS**: Enable VoiceOver in Settings

### Text Scaling
- Increase device font size to 200%
- Verify layouts adapt properly

### Contrast
- Test in bright sunlight
- Verify all text is readable

### Touch Targets
- Test with one hand
- Verify all buttons are easy to tap

## Resources

- Full Guide: `lib/core/utils/ACCESSIBILITY_GUIDE.md`
- Summary: `.kiro/specs/multi-flavor-ui-implementation/TASK_20_ACCESSIBILITY_SUMMARY.md`
