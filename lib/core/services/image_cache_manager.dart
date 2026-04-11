import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Custom cache manager for images with optimized settings
class CustomImageCacheManager extends CacheManager {
  static const key = 'customImageCache';
  
  static CustomImageCacheManager? _instance;
  
  factory CustomImageCacheManager() {
    _instance ??= CustomImageCacheManager._();
    return _instance!;
  }
  
  CustomImageCacheManager._() : super(
    Config(
      key,
      stalePeriod: const Duration(days: 7), // Cache for 7 days
      maxNrOfCacheObjects: 200, // Maximum 200 images
      repo: JsonCacheInfoRepository(databaseName: key),
      fileService: HttpFileService(),
    ),
  );
}

/// Service for managing image caching and lazy loading
class ImageCacheService {
  static final CustomImageCacheManager _cacheManager = CustomImageCacheManager();
  
  /// Preload images for better performance
  static Future<void> preloadImages(
    BuildContext context,
    List<String> imageUrls,
  ) async {
    for (final url in imageUrls) {
      try {
        await precacheImage(
          CachedNetworkImageProvider(
            url,
            cacheManager: _cacheManager,
          ),
          context,
        );
      } catch (e) {
        debugPrint('Failed to preload image: $url - $e');
      }
    }
  }
  
  /// Clear image cache
  static Future<void> clearCache() async {
    await _cacheManager.emptyCache();
  }
  
  /// Get cached image file
  static Future<File?> getCachedImageFile(String url) async {
    try {
      final fileInfo = await _cacheManager.getFileFromCache(url);
      return fileInfo?.file;
    } catch (e) {
      debugPrint('Failed to get cached image: $url - $e');
      return null;
    }
  }
  
  /// Remove specific image from cache
  static Future<void> removeFromCache(String url) async {
    await _cacheManager.removeFile(url);
  }
  
  /// Get cache size in bytes
  /// Note: This is an approximation as direct cache directory access is limited
  static Future<int> getCacheSize() async {
    // The flutter_cache_manager doesn't expose a direct way to get total cache size
    // Return 0 as we cannot reliably calculate the cache size without filesystem access
    // The cache is automatically managed by the CacheManager with maxNrOfCacheObjects
    return 0;
  }
  
  /// Format cache size for display
  static String formatCacheSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}

/// Widget for optimized image loading with caching
class CachedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;

  const CachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    Widget imageWidget = CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      cacheManager: CustomImageCacheManager(),
      placeholder: (context, url) => placeholder ?? 
        Container(
          width: width,
          height: height,
          color: Colors.grey[200],
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      errorWidget: (context, url, error) => errorWidget ??
        Container(
          width: width,
          height: height,
          color: Colors.grey[300],
          child: const Icon(Icons.error_outline, color: Colors.grey),
        ),
      fadeInDuration: const Duration(milliseconds: 300),
      fadeOutDuration: const Duration(milliseconds: 100),
      memCacheWidth: width?.toInt(),
      memCacheHeight: height?.toInt(),
    );

    if (borderRadius != null) {
      imageWidget = ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }
}

/// Circular avatar with cached image
class CachedCircleAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final Widget? placeholder;
  final Color? backgroundColor;

  const CachedCircleAvatar({
    super.key,
    this.imageUrl,
    this.radius = 20,
    this.placeholder,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor ?? Colors.grey[300],
        child: placeholder ?? Icon(Icons.person, size: radius),
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl!,
      cacheManager: CustomImageCacheManager(),
      imageBuilder: (context, imageProvider) => CircleAvatar(
        radius: radius,
        backgroundImage: imageProvider,
        backgroundColor: backgroundColor,
      ),
      placeholder: (context, url) => CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor ?? Colors.grey[200],
        child: const CircularProgressIndicator(strokeWidth: 2),
      ),
      errorWidget: (context, url, error) => CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor ?? Colors.grey[300],
        child: placeholder ?? Icon(Icons.person, size: radius),
      ),
      fadeInDuration: const Duration(milliseconds: 300),
      memCacheWidth: (radius * 2).toInt(),
      memCacheHeight: (radius * 2).toInt(),
    );
  }
}
