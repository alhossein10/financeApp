# Responsive Design Quick Reference

## Screen Size Breakpoints

| Size | Width Range | Example Devices |
|------|-------------|-----------------|
| Small Phone | < 360dp | iPhone SE, small Android phones |
| Standard Phone | 360-600dp | iPhone 12, most Android phones |
| Large Phone | 600-840dp | iPhone 12 Pro Max, large Android phones |
| Tablet | > 840dp | iPad, Android tablets |

## Quick Access

### Check Screen Size
```dart
final screenSize = context.screenSize;
// or
final screenSize = ResponsiveUtils.getScreenSize(context);
```

### Check Orientation
```dart
if (context.isPortrait) { /* portrait layout */ }
if (context.isLandscape) { /* landscape layout */ }
```

### Get Responsive Values
```dart
// Padding
final padding = context.responsivePadding;

// Spacing
final spacing = context.responsiveSpacing;

// Icon size
final iconSize = context.responsiveIconSize;

// Font multiplier
final multiplier = context.fontSizeMultiplier;
```

## Common Widgets

### Responsive Page
```dart
ResponsiveScaffold(
  title: 'Page Title',
  body: ResponsiveContainer(
    child: YourContent(),
  ),
  navigationDestinations: [...],
)
```

### Responsive Text
```dart
// Heading
ResponsiveHeading('Title', level: HeadingLevel.h1)

// Body text
ResponsiveBodyText('Content', size: BodyTextSize.medium)

// Label
ResponsiveLabel('Label', size: LabelSize.small)
```

### Responsive Form
```dart
ResponsiveForm(
  children: [
    TextField(...),
    TextField(...),
  ],
)
```

### Responsive Card
```dart
ResponsiveCard(
  onTap: () {},
  child: YourContent(),
)
```

### Responsive Button
```dart
ResponsiveButton(
  label: 'Submit',
  onPressed: () {},
)
```

### Responsive List
```dart
ListView.builder(
  padding: context.responsivePadding,
  itemBuilder: (context, index) {
    return ResponsiveListTile(
      leading: Icon(Icons.person, size: context.responsiveIconSize),
      title: ResponsiveBodyText(items[index].name),
      subtitle: ResponsiveBodyText(items[index].email, size: BodyTextSize.small),
    );
  },
)
```

### Responsive Grid
```dart
ResponsiveGrid(
  children: items.map((item) => 
    ResponsiveCard(child: Text(item.name))
  ).toList(),
)
```

### Responsive Dialog
```dart
showDialog(
  context: context,
  builder: (context) => ResponsiveDialog(
    title: 'Confirm',
    content: Text('Are you sure?'),
    actions: [
      TextButton(onPressed: () {}, child: Text('Cancel')),
      ElevatedButton(onPressed: () {}, child: Text('OK')),
    ],
  ),
)
```

## Responsive Values by Screen Size

| Value | Small | Standard | Large | Tablet |
|-------|-------|----------|-------|--------|
| Padding | 8 | 12 | 16 | 24 |
| Spacing | 8 | 12 | 16 | 24 |
| Font × | 0.9 | 1.0 | 1.1 | 1.2 |
| Icon | 20 | 24 | 28 | 32 |
| Avatar | 40 | 48 | 56 | 64 |
| Image | 80 | 100 | 120 | 150 |

## Navigation Modes

| Device | Portrait | Landscape |
|--------|----------|-----------|
| Phone | Bottom Nav | Bottom Nav |
| Tablet | Bottom Nav | Side Nav Rail |

## Grid Columns

| Device | Portrait | Landscape |
|--------|----------|-----------|
| Small Phone | 1 | 2 |
| Standard Phone | 2 | 3 |
| Large Phone | 3 | 4 |
| Tablet | 4 | 5 |

## Form Columns

| Device | Portrait | Landscape |
|--------|----------|-----------|
| Small Phone | 1 | 1 |
| Standard Phone | 1 | 2 |
| Large Phone | 1 | 2 |
| Tablet | 2 | 2 |

## Best Practices

### ✅ Do
- Use ResponsiveScaffold for pages with navigation
- Use ResponsiveText for all text
- Use context extensions for values
- Test on multiple screen sizes
- Test both orientations
- Support text scaling up to 200%

### ❌ Don't
- Hardcode padding values
- Hardcode font sizes
- Hardcode icon sizes
- Ignore orientation changes
- Forget to test on tablets
- Block text scaling

## Testing Checklist

- [ ] Small phone portrait
- [ ] Small phone landscape
- [ ] Standard phone portrait
- [ ] Standard phone landscape
- [ ] Large phone portrait
- [ ] Large phone landscape
- [ ] Tablet portrait
- [ ] Tablet landscape
- [ ] Text scaling 100%
- [ ] Text scaling 150%
- [ ] Text scaling 200%

## Common Patterns

### Responsive Page Layout
```dart
ResponsiveScaffold(
  title: 'Page',
  body: SingleChildScrollView(
    padding: context.responsivePadding,
    child: Column(
      children: [
        ResponsiveHeading('Title', level: HeadingLevel.h1),
        SizedBox(height: context.responsiveSpacing * 2),
        ResponsiveForm(children: [...]),
        SizedBox(height: context.responsiveSpacing * 2),
        ResponsiveButton(label: 'Submit', onPressed: () {}),
      ],
    ),
  ),
)
```

### Responsive Card List
```dart
ListView.builder(
  padding: context.responsivePadding,
  itemBuilder: (context, index) {
    return ResponsiveCard(
      onTap: () {},
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveHeading(item.title, level: HeadingLevel.h4),
          SizedBox(height: context.responsiveSpacing / 2),
          ResponsiveBodyText(item.description),
        ],
      ),
    );
  },
)
```

### Responsive Image Grid
```dart
ResponsiveGrid(
  childAspectRatio: 1.0,
  children: images.map((url) =>
    ResponsiveImage(imageUrl: url)
  ).toList(),
)
```

## Troubleshooting

### Text Overflow
```dart
ResponsiveText(
  'Long text...',
  maxLines: 2,
  overflow: TextOverflow.ellipsis,
)
```

### Layout Overflow
```dart
SingleChildScrollView(
  padding: context.responsivePadding,
  child: YourContent(),
)
```

### Small Touch Targets
```dart
// Use responsive widgets - they handle sizing automatically
ResponsiveButton(label: 'Tap', onPressed: () {})
```

## More Information

See `lib/core/utils/RESPONSIVE_DESIGN_GUIDE.md` for complete documentation.
