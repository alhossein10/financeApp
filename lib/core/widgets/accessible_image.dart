import 'package:flutter/material.dart';
import '../utils/accessibility_utils.dart';

/// Accessible image widget with proper alternative text and loading states
/// 
/// Requirements: 34.1, 34.2, 34.5
class AccessibleImage extends StatelessWidget {
  final String imageUrl;
  final String altText;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const AccessibleImage({
    super.key,
    required this.imageUrl,
    required this.altText,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AccessibilityUtils.imageSemanticLabel(description: altText),
      image: true,
      child: ExcludeSemantics(
        child: Image.network(
          imageUrl,
          width: width,
          height: height,
          fit: fit,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              return child;
            }
            return _buildLoadingPlaceholder(context, loadingProgress);
          },
          errorBuilder: (context, error, stackTrace) {
            return _buildErrorWidget(context);
          },
        ),
      ),
    );
  }

  Widget _buildLoadingPlaceholder(
    BuildContext context,
    ImageChunkEvent loadingProgress,
  ) {
    if (placeholder != null) {
      return Semantics(
        label: AccessibilityUtils.imageSemanticLabel(
          description: altText,
          isLoading: true,
        ),
        child: placeholder!,
      );
    }

    return Semantics(
      label: AccessibilityUtils.imageSemanticLabel(
        description: altText,
        isLoading: true,
      ),
      child: Container(
        width: width,
        height: height,
        color: Colors.grey.shade200,
        child: Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context) {
    if (errorWidget != null) {
      return Semantics(
        label: AccessibilityUtils.imageSemanticLabel(
          description: altText,
          hasError: true,
        ),
        child: errorWidget!,
      );
    }

    return Semantics(
      label: AccessibilityUtils.imageSemanticLabel(
        description: altText,
        hasError: true,
      ),
      child: Container(
        width: width,
        height: height,
        color: Colors.grey.shade200,
        child: const Center(
          child: Icon(
            Icons.broken_image,
            size: 48,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }
}

/// Accessible asset image
class AccessibleAssetImage extends StatelessWidget {
  final String assetPath;
  final String altText;
  final double? width;
  final double? height;
  final BoxFit fit;

  const AccessibleAssetImage({
    super.key,
    required this.assetPath,
    required this.altText,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AccessibilityUtils.imageSemanticLabel(description: altText),
      image: true,
      child: ExcludeSemantics(
        child: Image.asset(
          assetPath,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            return Semantics(
              label: AccessibilityUtils.imageSemanticLabel(
                description: altText,
                hasError: true,
              ),
              child: Container(
                width: width,
                height: height,
                color: Colors.grey.shade200,
                child: const Center(
                  child: Icon(
                    Icons.broken_image,
                    size: 48,
                    color: Colors.grey,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Accessible file image
class AccessibleFileImage extends StatelessWidget {
  final String filePath;
  final String altText;
  final double? width;
  final double? height;
  final BoxFit fit;

  const AccessibleFileImage({
    super.key,
    required this.filePath,
    required this.altText,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AccessibilityUtils.imageSemanticLabel(description: altText),
      image: true,
      child: ExcludeSemantics(
        child: Image.file(
          java.io.File(filePath),
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            return Semantics(
              label: AccessibilityUtils.imageSemanticLabel(
                description: altText,
                hasError: true,
              ),
              child: Container(
                width: width,
                height: height,
                color: Colors.grey.shade200,
                child: const Center(
                  child: Icon(
                    Icons.broken_image,
                    size: 48,
                    color: Colors.grey,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Import dart:io for File
import 'dart:io' as java.io;

/// Accessible circular avatar with proper alternative text
class AccessibleAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double radius;
  final Color? backgroundColor;

  const AccessibleAvatar({
    super.key,
    this.imageUrl,
    required this.name,
    this.radius = 20,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final semanticLabel = imageUrl != null
        ? 'Profile picture of $name'
        : 'Profile picture placeholder for $name';

    return Semantics(
      label: semanticLabel,
      image: true,
      child: ExcludeSemantics(
        child: CircleAvatar(
          radius: radius,
          backgroundColor: backgroundColor ?? Theme.of(context).primaryColor,
          backgroundImage: imageUrl != null ? NetworkImage(imageUrl!) : null,
          child: imageUrl == null
              ? Text(
                  _getInitials(name),
                  style: TextStyle(
                    fontSize: radius * 0.6,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                )
              : null,
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }
}
