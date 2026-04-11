import 'package:flutter/material.dart';
import '../utils/accessibility_utils.dart';

/// Accessible list tile with proper semantic labels and touch targets
/// 
/// Requirements: 34.1, 34.2, 34.6, 34.7
class AccessibleListTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final String? semanticLabel;
  final int? index;
  final int? totalItems;
  final bool enabled;

  const AccessibleListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.semanticLabel,
    this.index,
    this.totalItems,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveSemanticLabel = semanticLabel ??
        AccessibilityUtils.listItemSemanticLabel(
          title: title,
          subtitle: subtitle,
          index: index,
          total: totalItems,
        );

    return Semantics(
      label: effectiveSemanticLabel,
      button: onTap != null,
      enabled: enabled,
      child: ExcludeSemantics(
        child: ListTile(
          title: Text(
            title,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          subtitle: subtitle != null
              ? Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodyMedium,
                )
              : null,
          leading: leading,
          trailing: trailing,
          onTap: enabled ? _handleTap : null,
          onLongPress: enabled ? _handleLongPress : null,
          // Ensure minimum touch target height
          minVerticalPadding: 12,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
        ),
      ),
    );
  }

  void _handleTap() {
    if (onTap != null) {
      AccessibilityUtils.buttonTapFeedback();
      onTap!();
    }
  }

  void _handleLongPress() {
    if (onLongPress != null) {
      AccessibilityUtils.importantActionFeedback();
      onLongPress!();
    }
  }
}

/// Accessible card with proper semantic labels
class AccessibleCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final bool enabled;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;

  const AccessibleCard({
    super.key,
    required this.child,
    this.onTap,
    this.semanticLabel,
    this.enabled = true,
    this.margin,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    Widget card = Card(
      margin: margin ?? const EdgeInsets.all(8),
      child: InkWell(
        onTap: enabled ? _handleTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );

    if (semanticLabel != null) {
      card = Semantics(
        label: semanticLabel,
        button: onTap != null,
        enabled: enabled,
        child: ExcludeSemantics(child: card),
      );
    }

    return card;
  }

  void _handleTap() {
    if (onTap != null) {
      AccessibilityUtils.buttonTapFeedback();
      onTap!();
    }
  }
}

/// Accessible expansion tile with proper semantic labels
class AccessibleExpansionTile extends StatefulWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget> children;
  final String? semanticLabel;
  final bool initiallyExpanded;

  const AccessibleExpansionTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    required this.children,
    this.semanticLabel,
    this.initiallyExpanded = false,
  });

  @override
  State<AccessibleExpansionTile> createState() =>
      _AccessibleExpansionTileState();
}

class _AccessibleExpansionTileState extends State<AccessibleExpansionTile> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final effectiveSemanticLabel = widget.semanticLabel ??
        '${widget.title}, expandable, ${_isExpanded ? 'expanded' : 'collapsed'}';

    return Semantics(
      label: effectiveSemanticLabel,
      button: true,
      expanded: _isExpanded,
      child: ExcludeSemantics(
        child: ExpansionTile(
          title: Text(
            widget.title,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          subtitle: widget.subtitle != null
              ? Text(
                  widget.subtitle!,
                  style: Theme.of(context).textTheme.bodyMedium,
                )
              : null,
          leading: widget.leading,
          initiallyExpanded: widget.initiallyExpanded,
          onExpansionChanged: (expanded) {
            setState(() {
              _isExpanded = expanded;
            });
            AccessibilityUtils.selectionFeedback();
          },
          children: widget.children,
        ),
      ),
    );
  }
}

/// Accessible dismissible with proper semantic labels and haptic feedback
class AccessibleDismissible extends StatelessWidget {
  final Key key;
  final Widget child;
  final void Function(DismissDirection)? onDismissed;
  final String semanticLabel;
  final DismissDirection direction;
  final Widget? background;
  final Widget? secondaryBackground;

  const AccessibleDismissible({
    required this.key,
    required this.child,
    required this.onDismissed,
    required this.semanticLabel,
    this.direction = DismissDirection.horizontal,
    this.background,
    this.secondaryBackground,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$semanticLabel, swipe to dismiss',
      customSemanticsActions: {
        const CustomSemanticsAction(label: 'Dismiss'): () {
          _handleDismiss(DismissDirection.endToStart);
        },
      },
      child: ExcludeSemantics(
        child: Dismissible(
          key: key,
          direction: direction,
          onDismissed: (direction) {
            AccessibilityUtils.importantActionFeedback();
            _handleDismiss(direction);
          },
          background: background,
          secondaryBackground: secondaryBackground,
          child: child,
        ),
      ),
    );
  }

  void _handleDismiss(DismissDirection direction) {
    if (onDismissed != null) {
      onDismissed!(direction);
    }
  }
}
