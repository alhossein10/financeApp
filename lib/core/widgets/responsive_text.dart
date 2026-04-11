import 'package:flutter/material.dart';
import '../utils/responsive_utils.dart';

/// Responsive text widget that scales font size based on screen size
/// 
/// Requirements: 31.5, 34.4
class ResponsiveText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool applyResponsiveScaling;

  const ResponsiveText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.applyResponsiveScaling = true,
  });

  @override
  Widget build(BuildContext context) {
    TextStyle? effectiveStyle = style;

    if (applyResponsiveScaling && effectiveStyle != null) {
      final multiplier = ResponsiveUtils.getFontSizeMultiplier(context);
      final fontSize = effectiveStyle.fontSize;
      
      if (fontSize != null) {
        effectiveStyle = effectiveStyle.copyWith(
          fontSize: fontSize * multiplier,
        );
      }
    }

    return Text(
      text,
      style: effectiveStyle,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      // Support text scaling up to 200% as per accessibility requirements
      textScaleFactor: MediaQuery.of(context).textScaleFactor.clamp(1.0, 2.0),
    );
  }
}

/// Responsive heading text
class ResponsiveHeading extends StatelessWidget {
  final String text;
  final HeadingLevel level;
  final TextAlign? textAlign;
  final int? maxLines;

  const ResponsiveHeading(
    this.text, {
    super.key,
    this.level = HeadingLevel.h1,
    this.textAlign,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    TextStyle? style;

    switch (level) {
      case HeadingLevel.h1:
        style = theme.textTheme.headlineLarge;
        break;
      case HeadingLevel.h2:
        style = theme.textTheme.headlineMedium;
        break;
      case HeadingLevel.h3:
        style = theme.textTheme.headlineSmall;
        break;
      case HeadingLevel.h4:
        style = theme.textTheme.titleLarge;
        break;
      case HeadingLevel.h5:
        style = theme.textTheme.titleMedium;
        break;
      case HeadingLevel.h6:
        style = theme.textTheme.titleSmall;
        break;
    }

    return ResponsiveText(
      text,
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
    );
  }
}

/// Responsive body text
class ResponsiveBodyText extends StatelessWidget {
  final String text;
  final BodyTextSize size;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final Color? color;
  final FontWeight? fontWeight;

  const ResponsiveBodyText(
    this.text, {
    super.key,
    this.size = BodyTextSize.medium,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.color,
    this.fontWeight,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    TextStyle? style;

    switch (size) {
      case BodyTextSize.large:
        style = theme.textTheme.bodyLarge;
        break;
      case BodyTextSize.medium:
        style = theme.textTheme.bodyMedium;
        break;
      case BodyTextSize.small:
        style = theme.textTheme.bodySmall;
        break;
    }

    if (color != null || fontWeight != null) {
      style = style?.copyWith(
        color: color,
        fontWeight: fontWeight,
      );
    }

    return ResponsiveText(
      text,
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

/// Responsive label text
class ResponsiveLabel extends StatelessWidget {
  final String text;
  final LabelSize size;
  final TextAlign? textAlign;
  final Color? color;

  const ResponsiveLabel(
    this.text, {
    super.key,
    this.size = LabelSize.medium,
    this.textAlign,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    TextStyle? style;

    switch (size) {
      case LabelSize.large:
        style = theme.textTheme.labelLarge;
        break;
      case LabelSize.medium:
        style = theme.textTheme.labelMedium;
        break;
      case LabelSize.small:
        style = theme.textTheme.labelSmall;
        break;
    }

    if (color != null) {
      style = style?.copyWith(color: color);
    }

    return ResponsiveText(
      text,
      style: style,
      textAlign: textAlign,
    );
  }
}

/// Heading levels
enum HeadingLevel {
  h1,
  h2,
  h3,
  h4,
  h5,
  h6,
}

/// Body text sizes
enum BodyTextSize {
  large,
  medium,
  small,
}

/// Label sizes
enum LabelSize {
  large,
  medium,
  small,
}
