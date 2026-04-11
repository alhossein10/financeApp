import 'package:flutter/material.dart';
import '../utils/responsive_utils.dart';
import 'responsive_layout.dart';

/// Responsive scaffold that adapts navigation based on screen size
/// 
/// Requirements: 31.3, 31.4, 31.6, 31.8
class ResponsiveScaffold extends StatelessWidget {
  final String? title;
  final Widget body;
  final List<NavigationDestination>? navigationDestinations;
  final int? currentNavigationIndex;
  final ValueChanged<int>? onNavigationIndexChanged;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? drawer;
  final bool extendBodyBehindAppBar;

  const ResponsiveScaffold({
    super.key,
    this.title,
    required this.body,
    this.navigationDestinations,
    this.currentNavigationIndex,
    this.onNavigationIndexChanged,
    this.actions,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.drawer,
    this.extendBodyBehindAppBar = false,
  });

  @override
  Widget build(BuildContext context) {
    final shouldUseSideNav = ResponsiveUtils.shouldUseSideNavigation(context);
    final hasNavigation = navigationDestinations != null && 
                          navigationDestinations!.isNotEmpty;

    if (shouldUseSideNav && hasNavigation) {
      return _buildWithSideNavigation(context);
    }

    return _buildWithBottomNavigation(context);
  }

  Widget _buildWithBottomNavigation(BuildContext context) {
    final hasNavigation = navigationDestinations != null && 
                          navigationDestinations!.isNotEmpty;

    return Scaffold(
      appBar: title != null
          ? AppBar(
              title: Text(title!),
              actions: actions,
              toolbarHeight: ResponsiveUtils.getResponsiveAppBarHeight(context),
            )
          : null,
      body: ResponsiveLayout(
        child: body,
      ),
      bottomNavigationBar: hasNavigation
          ? NavigationBar(
              selectedIndex: currentNavigationIndex ?? 0,
              onDestinationSelected: onNavigationIndexChanged,
              destinations: navigationDestinations!,
              height: ResponsiveUtils.getResponsiveBottomNavHeight(context),
            )
          : null,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      drawer: drawer,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
    );
  }

  Widget _buildWithSideNavigation(BuildContext context) {
    return Scaffold(
      appBar: title != null
          ? AppBar(
              title: Text(title!),
              actions: actions,
              toolbarHeight: ResponsiveUtils.getResponsiveAppBarHeight(context),
            )
          : null,
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: currentNavigationIndex ?? 0,
            onDestinationSelected: onNavigationIndexChanged,
            labelType: NavigationRailLabelType.all,
            destinations: navigationDestinations!
                .map((dest) => NavigationRailDestination(
                      icon: dest.icon,
                      selectedIcon: dest.selectedIcon ?? dest.icon,
                      label: Text(dest.label),
                    ))
                .toList(),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: ResponsiveLayout(
              child: body,
            ),
          ),
        ],
      ),
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
    );
  }
}

/// Responsive app bar
class ResponsiveAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;

  const ResponsiveAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      actions: actions,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      toolbarHeight: ResponsiveUtils.getResponsiveAppBarHeight(context),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// Responsive bottom sheet
class ResponsiveBottomSheet extends StatelessWidget {
  final Widget child;
  final String? title;
  final bool isDismissible;
  final bool enableDrag;

  const ResponsiveBottomSheet({
    super.key,
    required this.child,
    this.title,
    this.isDismissible = true,
    this.enableDrag = true,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    bool isDismissible = true,
    bool enableDrag = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      isScrollControlled: true,
      builder: (context) => ResponsiveBottomSheet(
        title: title,
        isDismissible: isDismissible,
        enableDrag: enableDrag,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = ResponsiveUtils.getScreenSize(context);
    final maxHeight = MediaQuery.of(context).size.height * 0.9;
    final padding = ResponsiveUtils.getResponsivePadding(context);

    return Container(
      constraints: BoxConstraints(
        maxHeight: maxHeight,
        maxWidth: screenSize == ScreenSize.tablet ? 600 : double.infinity,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(16),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (enableDrag)
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          if (title != null)
            Padding(
              padding: padding,
              child: Text(
                title!,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          Flexible(
            child: SingleChildScrollView(
              padding: padding,
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

/// Responsive container with max width constraint
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final Decoration? decoration;
  final bool centerContent;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.decoration,
    this.centerContent = false,
  });

  @override
  Widget build(BuildContext context) {
    final maxWidth = ResponsiveUtils.getResponsiveMaxContentWidth(context);
    final effectivePadding = padding ?? ResponsiveUtils.getResponsivePadding(context);

    Widget content = Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      padding: effectivePadding,
      margin: margin,
      color: color,
      decoration: decoration,
      child: child,
    );

    if (centerContent) {
      content = Center(child: content);
    }

    return content;
  }
}
