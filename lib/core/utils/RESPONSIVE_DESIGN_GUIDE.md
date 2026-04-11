# Responsive Design Guide

This guide explains how to use the responsive design utilities in the Finance App to create layouts that adapt to different screen sizes and orientations.

## Requirements Coverage

- **31.1**: Adapt layouts for small phones (< 360dp)
- **31.2**: Adapt layouts for standard phones (360-600dp)
- **31.3**: Adapt layouts for large phones/small tablets (600-840dp)
- **31.4**: Adapt layouts for tablets (> 840dp)
- **31.5**: Use responsive font sizes
- **31.6**: Test portrait and landscape orientations
- **31.7**: Ensure minimum touch target size 48dp
- **31.8**: Support text scaling up to 200%

## Screen Size Breakpoints

The app uses four screen size categories:

- **Small Phone**: < 360dp width
- **Standard Phone**: 360-600dp width
- **Large Phone**: 600-840dp width
- **Tablet**: > 840dp width

## Basic Usage

### 1. Using ResponsiveUtils

```dart
import 'package:finance_app/core/utils/responsive_utils.dart';

// Get current screen size
final screenSize = ResponsiveUtils.getScreenSize(context);

// Check orientation
final isPortrait = ResponsiveUtils.isPortrait(context);
final isLandscape = ResponsiveUtils.isLandscape(context);

// Get responsive values
final padding = ResponsiveUtils.getResponsivePadding(context);
final spacing = ResponsiveUtils.getResponsiveSpacing(context);
final iconSize = ResponsiveUtils.getResponsiveIconSize(context);
```

### 2. Using Context Extensions

```dart
// Easier access through context extensions
final screenSize = context.screenSize;
final isPortrait = context.isPortrait;
final padding = context.responsivePadding;
final spacing = context.responsiveSpacing;
```

## Responsive Widgets

### ResponsiveLayout

Wraps content with max-width constraints for tablets:

```dart
ResponsiveLayout(
  centerContent: true,
  child: YourContent(),
)
```

### ResponsivePadding

Applies screen-size-appropriate padding:

```dart
ResponsivePadding(
  horizontal: true,
  vertical: true,
  child: YourContent(),
)
```

### ResponsiveText

Text that scales based on screen size:

```dart
ResponsiveText(
  'Hello World',
  style: Theme.of(context).textTheme.bodyLarge,
)

// Or use specialized text widgets
ResponsiveHeading(
  'Page Title',
  level: HeadingLevel.h1,
)

ResponsiveBodyText(
  'Body content',
  size: BodyTextSize.medium,
)

ResponsiveLabel(
  'Label',
  size: LabelSize.small,
)
```

### ResponsiveCard

Card with responsive elevation and border radius:

```dart
ResponsiveCard(
  onTap: () {},
  child: YourContent(),
)
```

### ResponsiveButton

Button with responsive width:

```dart
ResponsiveButton(
  label: 'Submit',
  onPressed: () {},
  isFullWidth: true,
)
```

### ResponsiveForm

Form layout that adapts to screen size:

```dart
ResponsiveForm(
  children: [
    TextField(decoration: InputDecoration(labelText: 'Name')),
    TextField(decoration: InputDecoration(labelText: 'Email')),
    TextField(decoration: InputDecoration(labelText: 'Phone')),
  ],
)
```

On small/standard phones: Single column
On large phones/tablets: Two columns

### ResponsiveGrid

Grid that adjusts column count based on screen size:

```dart
ResponsiveGrid(
  childAspectRatio: 1.5,
  children: [
    Card(child: Text('Item 1')),
    Card(child: Text('Item 2')),
    Card(child: Text('Item 3')),
  ],
)
```

### ResponsiveScaffold

Scaffold that switches between bottom navigation and side navigation:

```dart
ResponsiveScaffold(
  title: 'Page Title',
  body: YourContent(),
  navigationDestinations: [
    NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
    NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
  ],
  currentNavigationIndex: 0,
  onNavigationIndexChanged: (index) {},
)
```

On tablets in landscape: Uses side navigation rail
Otherwise: Uses bottom navigation bar

### ResponsiveDialog

Dialog with responsive width:

```dart
showDialog(
  context: context,
  builder: (context) => ResponsiveDialog(
    title: 'Confirm',
    content: Text('Are you sure?'),
    actions: [
      TextButton(onPressed: () {}, child: Text('Cancel')),
      ElevatedButton(onPressed: () {}, child: Text('Confirm')),
    ],
  ),
)
```

### ResponsiveBottomSheet

Bottom sheet with responsive sizing:

```dart
ResponsiveBottomSheet.show(
  context: context,
  title: 'Options',
  child: YourContent(),
)
```

## Responsive Values

### Padding and Spacing

```dart
// Responsive padding
final padding = context.responsivePadding;
// Small: 8, Standard: 12, Large: 16, Tablet: 24

// Responsive spacing
final spacing = context.responsiveSpacing;
// Small: 8, Standard: 12, Large: 16, Tablet: 24
```

### Font Sizes

```dart
// Font size multiplier
final multiplier = context.fontSizeMultiplier;
// Small: 0.9, Standard: 1.0, Large: 1.1, Tablet: 1.2

// Apply to custom text
Text(
  'Custom Text',
  style: TextStyle(
    fontSize: 16 * context.fontSizeMultiplier,
  ),
)
```

### Icons

```dart
// Responsive icon size
Icon(
  Icons.home,
  size: context.responsiveIconSize,
)
// Small: 20, Standard: 24, Large: 28, Tablet: 32
```

### Images and Avatars

```dart
// Responsive image
ResponsiveImage(
  imageUrl: 'https://example.com/image.jpg',
  isAvatar: true,
)

// Or manually
CircleAvatar(
  radius: context.responsiveAvatarSize / 2,
  backgroundImage: NetworkImage(url),
)
// Small: 40, Standard: 48, Large: 56, Tablet: 64
```

## Orientation Handling

### Check Orientation

```dart
if (context.isLandscape) {
  // Landscape-specific layout
} else {
  // Portrait-specific layout
}
```

### Adaptive Grid

```dart
// Grid automatically adjusts columns based on orientation
final columns = context.responsiveGridCrossAxisCount;
// Increases in landscape mode
```

## Best Practices

### 1. Always Use Responsive Utilities

❌ Don't:
```dart
Padding(
  padding: EdgeInsets.all(16),
  child: Text('Hello'),
)
```

✅ Do:
```dart
ResponsivePadding(
  child: ResponsiveText('Hello'),
)
```

### 2. Use Context Extensions

❌ Don't:
```dart
final spacing = ResponsiveUtils.getResponsiveSpacing(context);
```

✅ Do:
```dart
final spacing = context.responsiveSpacing;
```

### 3. Test on Multiple Screen Sizes

Always test your layouts on:
- Small phone (e.g., iPhone SE)
- Standard phone (e.g., iPhone 12)
- Large phone (e.g., iPhone 12 Pro Max)
- Tablet (e.g., iPad)

### 4. Test Both Orientations

Test portrait and landscape modes, especially for:
- Forms
- Lists
- Grids
- Navigation

### 5. Support Text Scaling

All text automatically supports scaling up to 200%:
```dart
ResponsiveText(
  'This text scales with system settings',
  style: Theme.of(context).textTheme.bodyLarge,
)
```

### 6. Ensure Touch Targets

All interactive elements automatically meet the 48dp minimum:
```dart
// Buttons, IconButtons, and ListTiles automatically have proper sizing
ElevatedButton(
  onPressed: () {},
  child: Text('Button'),
)
```

## Common Patterns

### Responsive List Item

```dart
ResponsiveListTile(
  leading: ResponsiveImage(
    imageUrl: user.profileImageUrl,
    isAvatar: true,
  ),
  title: ResponsiveBodyText(
    user.name,
    size: BodyTextSize.large,
    fontWeight: FontWeight.bold,
  ),
  subtitle: ResponsiveBodyText(
    user.email,
    size: BodyTextSize.small,
  ),
  trailing: Icon(
    Icons.chevron_right,
    size: context.responsiveIconSize,
  ),
  onTap: () {},
)
```

### Responsive Form Field

```dart
ResponsiveForm(
  children: [
    TextField(
      decoration: InputDecoration(
        labelText: 'Name',
        contentPadding: context.responsivePadding,
      ),
    ),
    TextField(
      decoration: InputDecoration(
        labelText: 'Email',
        contentPadding: context.responsivePadding,
      ),
    ),
  ],
)
```

### Responsive Card List

```dart
ListView.builder(
  padding: context.responsivePadding,
  itemCount: items.length,
  itemBuilder: (context, index) {
    return ResponsiveCard(
      onTap: () {},
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveHeading(
            items[index].title,
            level: HeadingLevel.h4,
          ),
          SizedBox(height: context.responsiveSpacing),
          ResponsiveBodyText(
            items[index].description,
            size: BodyTextSize.medium,
          ),
        ],
      ),
    );
  },
)
```

### Responsive Page Layout

```dart
ResponsiveScaffold(
  title: 'Page Title',
  body: ResponsiveContainer(
    centerContent: true,
    child: Column(
      children: [
        ResponsiveHeading(
          'Welcome',
          level: HeadingLevel.h1,
        ),
        SizedBox(height: context.responsiveSpacing * 2),
        ResponsiveForm(
          children: [
            // Form fields
          ],
        ),
        SizedBox(height: context.responsiveSpacing * 2),
        ResponsiveButton(
          label: 'Submit',
          onPressed: () {},
        ),
      ],
    ),
  ),
)
```

## Testing Responsive Layouts

### Using Device Preview

```dart
import 'package:device_preview/device_preview.dart';

void main() {
  runApp(
    DevicePreview(
      enabled: true,
      builder: (context) => MyApp(),
    ),
  );
}
```

### Manual Testing Checklist

- [ ] Small phone (< 360dp) - Portrait
- [ ] Small phone (< 360dp) - Landscape
- [ ] Standard phone (360-600dp) - Portrait
- [ ] Standard phone (360-600dp) - Landscape
- [ ] Large phone (600-840dp) - Portrait
- [ ] Large phone (600-840dp) - Landscape
- [ ] Tablet (> 840dp) - Portrait
- [ ] Tablet (> 840dp) - Landscape
- [ ] Text scaling at 100%
- [ ] Text scaling at 150%
- [ ] Text scaling at 200%

## Troubleshooting

### Text Overflow

If text overflows:
```dart
ResponsiveText(
  'Long text that might overflow',
  maxLines: 2,
  overflow: TextOverflow.ellipsis,
)
```

### Layout Overflow

If layout overflows:
```dart
SingleChildScrollView(
  padding: context.responsivePadding,
  child: YourContent(),
)
```

### Touch Targets Too Small

Use responsive widgets that automatically handle sizing:
```dart
// Instead of custom GestureDetector
ResponsiveButton(
  label: 'Tap Me',
  onPressed: () {},
)
```

## Performance Considerations

- Responsive utilities are lightweight and cached
- Context extensions have minimal overhead
- Use `const` constructors where possible
- Avoid rebuilding responsive widgets unnecessarily

## Migration Guide

To migrate existing code to use responsive design:

1. Replace hardcoded padding with `ResponsivePadding` or `context.responsivePadding`
2. Replace `Text` with `ResponsiveText` or specialized text widgets
3. Replace `Scaffold` with `ResponsiveScaffold` where navigation is needed
4. Replace hardcoded sizes with responsive utilities
5. Test on multiple screen sizes and orientations
