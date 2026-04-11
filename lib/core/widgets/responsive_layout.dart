import 'package:flutter/material.dart';
import '../utils/responsive_utils.dart';

/// Responsive layout wrapper that adapts content based on screen size
/// 
/// Requirements: 31.1, 31.2, 31.3, 31.4, 31.7, 31.8
class ResponsiveLayout extends StatelessWidget {
  final Widget child;
  final bool centerContent;
  final bool applyMaxWidth;

  const ResponsiveLayout({
    super.key,
    required this.child,
    this.centerContent = false,
    this.applyMaxWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    final maxWidth = applyMaxWidth 
        ? ResponsiveUtils.getResponsiveMaxContentWidth(context)
        : double.infinity;

    Widget content = Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    );

    if (centerContent) {
      content = Center(child: content);
    }

    return content;
  }
}

/// Responsive padding wrapper
class ResponsivePadding extends StatelessWidget {
  final Widget child;
  final bool horizontal;
  final bool vertical;

  const ResponsivePadding({
    super.key,
    required this.child,
    this.horizontal = true,
    this.vertical = true,
  });

  @override
  Widget build(BuildContext context) {
    EdgeInsets padding;
    
    if (horizontal && vertical) {
      padding = ResponsiveUtils.getResponsivePadding(context);
    } else if (horizontal) {
      padding = ResponsiveUtils.getResponsiveHorizontalPadding(context);
    } else if (vertical) {
      padding = ResponsiveUtils.getResponsiveVerticalPadding(context);
    } else {
      padding = EdgeInsets.zero;
    }

    return Padding(
      padding: padding,
      child: child,
    );
  }
}

/// Responsive grid view
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double childAspectRatio;
  final double mainAxisSpacing;
  final double crossAxisSpacing;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.childAspectRatio = 1.0,
    this.mainAxisSpacing = 0,
    this.crossAxisSpacing = 0,
  });

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = ResponsiveUtils.getResponsiveGridCrossAxisCount(context);
    final spacing = ResponsiveUtils.getResponsiveSpacing(context);

    return GridView.count(
      crossAxisCount: crossAxisCount,
      childAspectRatio: childAspectRatio,
      mainAxisSpacing: mainAxisSpacing > 0 ? mainAxisSpacing : spacing,
      crossAxisSpacing: crossAxisSpacing > 0 ? crossAxisSpacing : spacing,
      padding: ResponsiveUtils.getResponsivePadding(context),
      children: children,
    );
  }
}

/// Responsive form layout
class ResponsiveForm extends StatelessWidget {
  final List<Widget> children;
  final double spacing;

  const ResponsiveForm({
    super.key,
    required this.children,
    this.spacing = 0,
  });

  @override
  Widget build(BuildContext context) {
    final columns = ResponsiveUtils.getResponsiveFormColumns(context);
    final actualSpacing = spacing > 0 
        ? spacing 
        : ResponsiveUtils.getResponsiveSpacing(context);

    if (columns == 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _addSpacing(children, actualSpacing),
      );
    }

    // Two column layout for larger screens
    final rows = <Widget>[];
    for (int i = 0; i < children.length; i += 2) {
      final leftChild = children[i];
      final rightChild = i + 1 < children.length ? children[i + 1] : null;

      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: leftChild),
            if (rightChild != null) ...[
              SizedBox(width: actualSpacing),
              Expanded(child: rightChild),
            ],
          ],
        ),
      );

      if (i + 2 < children.length) {
        rows.add(SizedBox(height: actualSpacing));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }

  List<Widget> _addSpacing(List<Widget> children, double spacing) {
    final result = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      result.add(children[i]);
      if (i < children.length - 1) {
        result.add(SizedBox(height: spacing));
      }
    }
    return result;
  }
}

/// Responsive card
class ResponsiveCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const ResponsiveCard({
    super.key,
    required this.child,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final elevation = ResponsiveUtils.getResponsiveCardElevation(context);
    final borderRadius = ResponsiveUtils.getResponsiveBorderRadius(context);
    final padding = ResponsiveUtils.getResponsivePadding(context);

    return Card(
      elevation: elevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

/// Responsive dialog
class ResponsiveDialog extends StatelessWidget {
  final String? title;
  final Widget content;
  final List<Widget>? actions;

  const ResponsiveDialog({
    super.key,
    this.title,
    required this.content,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final width = ResponsiveUtils.getResponsiveDialogWidth(context);

    return Dialog(
      child: Container(
        width: width,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null)
              Padding(
                padding: ResponsiveUtils.getResponsivePadding(context),
                child: Text(
                  title!,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            Flexible(
              child: SingleChildScrollView(
                padding: ResponsiveUtils.getResponsivePadding(context),
                child: content,
              ),
            ),
            if (actions != null && actions!.isNotEmpty)
              Padding(
                padding: ResponsiveUtils.getResponsivePadding(context),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: actions!,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Responsive button
class ResponsiveButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isFullWidth;
  final ButtonStyle? style;

  const ResponsiveButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isFullWidth = true,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final button = ElevatedButton(
      onPressed: onPressed,
      style: style,
      child: Text(label),
    );

    if (isFullWidth) {
      final width = ResponsiveUtils.getResponsiveButtonWidth(context);
      return SizedBox(
        width: width,
        child: button,
      );
    }

    return button;
  }
}

/// Responsive list tile
class ResponsiveListTile extends StatelessWidget {
  final Widget? leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const ResponsiveListTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final height = ResponsiveUtils.getResponsiveListTileHeight(context);
    final padding = ResponsiveUtils.getResponsiveHorizontalPadding(context);

    return InkWell(
      onTap: onTap,
      child: Container(
        height: height,
        padding: padding,
        child: Row(
          children: [
            if (leading != null) ...[
              leading!,
              SizedBox(width: ResponsiveUtils.getResponsiveSpacing(context)),
            ],
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  title,
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    subtitle!,
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              SizedBox(width: ResponsiveUtils.getResponsiveSpacing(context)),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Responsive image
class ResponsiveImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final bool isAvatar;

  const ResponsiveImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.isAvatar = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = isAvatar
        ? ResponsiveUtils.getResponsiveAvatarSize(context)
        : ResponsiveUtils.getResponsiveImageSize(context);

    if (isAvatar) {
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: NetworkImage(imageUrl),
      );
    }

    return Image.network(
      imageUrl,
      width: size,
      height: size,
      fit: fit,
    );
  }
}
