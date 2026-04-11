# Performance Optimization Guide

This guide covers all performance optimization features implemented in the application.

## Table of Contents

1. [Image Compression and Caching](#image-compression-and-caching)
2. [List Pagination](#list-pagination)
3. [Efficient List Rendering](#efficient-list-rendering)
4. [Lazy Loading Images](#lazy-loading-images)
5. [Data Caching](#data-caching)
6. [API Request Optimization](#api-request-optimization)
7. [Performance Monitoring](#performance-monitoring)

---

## Image Compression and Caching

### Image Compression

Use `ImageCompression` utility to compress images before upload:

```dart
import 'package:finance_app/core/utils/image_compression.dart';

// Compress an image file
final compressedFile = await ImageCompression.compressImage(originalFile);

// Check if compression is needed
final needsCompression = await ImageCompression.needsCompression(
  file,
  maxSizeBytes: 2 * 1024 * 1024, // 2MB
);

// Get file size
final size = await ImageCompression.getFileSize(file);
```

**Features:**
- Automatic resizing to max 1920px width
- JPEG compression at 85% quality
- Typically reduces file size by 60-80%

### Image Caching

Use `CachedImage` widget for automatic image caching:

```dart
import 'package:finance_app/core/services/image_cache_manager.dart';

// Basic usage
CachedImage(
  imageUrl: 'https://example.com/image.jpg',
  width: 200,
  height: 200,
  fit: BoxFit.cover,
)

// With custom placeholder and error widget
CachedImage(
  imageUrl: imageUrl,
  width: 100,
  height: 100,
  placeholder: CircularProgressIndicator(),
  errorWidget: Icon(Icons.error),
  borderRadius: BorderRadius.circular(8),
)

// Circular avatar
CachedCircleAvatar(
  imageUrl: user.profileImageUrl,
  radius: 24,
  placeholder: Icon(Icons.person),
)
```

**Features:**
- Automatic disk and memory caching
- 7-day cache duration
- Maximum 200 cached images
- Automatic cache eviction (LRU)
- Fade-in animations

### Cache Management

```dart
// Preload images for better performance
await ImageCacheService.preloadImages(context, [
  'https://example.com/image1.jpg',
  'https://example.com/image2.jpg',
]);

// Clear all cached images
await ImageCacheService.clearCache();

// Remove specific image from cache
await ImageCacheService.removeFromCache(imageUrl);

// Get cache size
final sizeBytes = await ImageCacheService.getCacheSize();
final sizeFormatted = ImageCacheService.formatCacheSize(sizeBytes);
```

---

## List Pagination

### Using PaginationHelper

```dart
import 'package:finance_app/core/utils/pagination_helper.dart';

// Get pagination parameters for API request
final params = PaginationHelper.getPaginationParams(
  page: 1,
  perPage: 15, // Default: 15, Max: 100
);

// Check if there are more pages
final hasMore = PaginationHelper.hasMorePages(
  currentPage: currentPage,
  totalPages: totalPages,
);

// Calculate total pages
final totalPages = PaginationHelper.calculateTotalPages(
  totalItems: 150,
  perPage: 15,
); // Returns 10
```

### Using PaginatedResponse

```dart
// Parse API response
final response = PaginatedResponse<Expense>.fromJson(
  jsonResponse,
  (json) => ExpenseDto.fromJson(json).toEntity(),
);

// Access data
final expenses = response.data;
final hasMore = response.hasMore;
final nextPage = response.nextPage;

// Merge with existing data (for infinite scroll)
final merged = currentResponse.merge(newResponse);
```

**Configuration:**
- Default page size: 15 items
- Maximum page size: 100 items
- Automatic page validation

---

## Efficient List Rendering

### Use ListView.builder Instead of ListView

❌ **Bad - Inefficient:**
```dart
ListView(
  children: items.map((item) => ItemWidget(item)).toList(),
)
```

✅ **Good - Efficient:**
```dart
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    return ItemWidget(items[index]);
  },
)
```

### Use OptimizedListView

```dart
import 'package:finance_app/core/widgets/optimized_list_view.dart';

OptimizedListView<Expense>(
  items: expenses,
  itemBuilder: (context, expense, index) {
    return ExpenseCard(expense: expense);
  },
  onLoadMore: () async {
    // Load next page
    await loadNextPage();
  },
  hasMore: hasMorePages,
  isLoading: isLoading,
  emptyWidget: Center(
    child: Text('No expenses found'),
  ),
  padding: EdgeInsets.all(16),
)
```

**Features:**
- Automatic pagination
- Loads more when scrolling near bottom (200px threshold)
- Built-in loading indicator
- Custom empty state
- Efficient rendering with ListView.builder

### Use OptimizedGridView

```dart
OptimizedGridView<Product>(
  items: products,
  itemBuilder: (context, product, index) {
    return ProductCard(product: product);
  },
  crossAxisCount: 2,
  mainAxisSpacing: 8,
  crossAxisSpacing: 8,
  childAspectRatio: 0.75,
  onLoadMore: loadNextPage,
  hasMore: hasMorePages,
)
```

### Use RepaintBoundary for Complex Widgets

```dart
// Wrap complex widgets to prevent unnecessary repaints
RepaintBoundary(
  child: ComplexExpenseCard(expense: expense),
)

// Or use OptimizedListTile
OptimizedListTile(
  leading: CachedCircleAvatar(imageUrl: user.imageUrl),
  title: Text(user.name),
  subtitle: Text(user.email),
  trailing: Icon(Icons.chevron_right),
  onTap: () => navigateToDetails(user),
)
```

---

## Lazy Loading Images

### In Lists

```dart
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    return Card(
      child: Row(
        children: [
          // Image loads only when visible
          CachedImage(
            imageUrl: items[index].imageUrl,
            width: 80,
            height: 80,
            fit: BoxFit.cover,
          ),
          Expanded(
            child: ListTile(
              title: Text(items[index].title),
              subtitle: Text(items[index].description),
            ),
          ),
        ],
      ),
    );
  },
)
```

### Preloading for Better UX

```dart
@override
void initState() {
  super.initState();
  
  // Preload images after initial render
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final imageUrls = items.map((item) => item.imageUrl).toList();
    ImageCacheService.preloadImages(context, imageUrls);
  });
}
```

---

## Data Caching

### Using CacheService (Persistent)

```dart
import 'package:finance_app/core/services/cache_service.dart';

final cacheService = CacheServiceImpl();

// Initialize
await cacheService.initialize();

// Store data with TTL
await cacheService.set(
  'user_profile',
  userProfile,
  ttl: Duration(hours: 1),
);

// Retrieve data
final cachedProfile = await cacheService.get<UserProfile>('user_profile');

// Delete specific entry
await cacheService.delete('user_profile');

// Clear all cache
await cacheService.clear();
```

**Features:**
- Persistent storage using Hive
- TTL (Time To Live) support
- LRU eviction policy
- Maximum 1000 entries
- Automatic cleanup of expired entries

### Using MemoryCache (In-Memory)

```dart
import 'package:finance_app/core/services/memory_cache.dart';

final cache = MemoryCache<String, User>(
  maxSize: 100,
  defaultTTL: Duration(minutes: 5),
);

// Store
cache.put('user_123', user);

// Retrieve
final user = cache.get('user_123');

// Check existence
if (cache.containsKey('user_123')) {
  // ...
}

// Remove
cache.remove('user_123');

// Clear all
cache.clear();

// Cleanup expired entries
cache.cleanupExpired();
```

**Use Cases:**
- Hot data that's accessed frequently
- Temporary session data
- API response caching
- User preferences

---

## API Request Optimization

### Request Debouncing

Prevents excessive API calls during rapid user input:

```dart
import 'package:finance_app/core/services/api_request_optimizer.dart';

final optimizer = ApiRequestOptimizer();

// Debounce search requests
final results = await optimizer.debounce<List<User>>(
  key: 'user_search',
  operation: () => api.searchUsers(query),
  duration: Duration(milliseconds: 500),
);
```

**Use Cases:**
- Search input
- Filter changes
- Auto-save functionality

### Request Batching

Combines multiple operations into a single API call:

```dart
// Add operations to batch queue
optimizer.addToBatch(
  resourceType: 'expenses',
  operationType: 'create',
  data: expenseData,
  onComplete: (result) {
    print('Expense created: $result');
  },
  onError: (error) {
    print('Error: $error');
  },
);

// Batch is automatically processed when:
// - 50 operations are queued
// - 2 seconds have passed since first operation

// Or manually trigger processing
optimizer.processBatchNow('expenses');
```

**Use Cases:**
- Bulk operations
- Offline sync
- Analytics events

### Cleanup

```dart
// Cancel all pending debounce timers
optimizer.cancelAllDebounce();

// Cancel all batch operations
optimizer.cancelAllBatches();

// Dispose completely
optimizer.dispose();
```

---

## Performance Monitoring

### Enable Monitoring

```dart
import 'package:finance_app/core/services/performance_monitor.dart';

final monitor = PerformanceMonitor();

// Start monitoring
monitor.startMonitoring();

// Stop monitoring
monitor.stopMonitoring();
```

### Track Operations

```dart
// Track operation timing
final result = await monitor.trackOperation(
  'load_expenses',
  () => expenseRepository.getExpenses(),
);

// Track API calls
monitor.trackApiCall('/api/v1/expenses');
```

### Get Metrics

```dart
// Get current metrics
final metrics = monitor.getMetrics();

print('Average frame time: ${metrics.averageFrameTime?.inMilliseconds}ms');
print('Frame rate: ${metrics.frameRate?.toStringAsFixed(1)} FPS');
print('Slow frames: ${metrics.slowFramePercentage?.toStringAsFixed(1)}%');
print('Total API calls: ${metrics.totalApiCalls}');

// Get specific operation timing
final timing = monitor.getOperationTiming('load_expenses');
print('Load expenses took: ${timing?.inMilliseconds}ms');

// Get API call count
final count = monitor.getApiCallCount('/api/v1/expenses');
print('Expenses API called $count times');
```

### Performance Reports

Automatic reports are generated every 30 seconds in debug mode:

```
=== Performance Report ===
Average frame time: 12ms
Frame rate: 83.3 FPS
Slow frames: 5.2%
Operation timings:
  load_expenses: 245ms
  load_transfers: 189ms
API call counts:
  /api/v1/expenses: 12 calls
  /api/v1/transfers: 8 calls
========================
```

---

## Best Practices

### 1. Always Use ListView.builder for Dynamic Lists

```dart
// ✅ Good
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) => ItemWidget(items[index]),
)

// ❌ Bad
ListView(
  children: items.map((item) => ItemWidget(item)).toList(),
)
```

### 2. Implement Pagination for Large Lists

```dart
// Load data in pages
Future<void> loadExpenses({int page = 1}) async {
  final response = await api.getExpenses(
    page: page,
    perPage: 15,
  );
  
  if (page == 1) {
    expenses = response.data;
  } else {
    expenses.addAll(response.data);
  }
  
  hasMore = response.hasMore;
  currentPage = page;
}
```

### 3. Cache Frequently Accessed Data

```dart
// Check cache first
var user = await cacheService.get<User>('current_user');

if (user == null) {
  // Fetch from API
  user = await api.getCurrentUser();
  
  // Store in cache
  await cacheService.set(
    'current_user',
    user,
    ttl: Duration(hours: 1),
  );
}
```

### 4. Compress Images Before Upload

```dart
Future<void> uploadProfileImage(File imageFile) async {
  // Compress first
  final compressed = await ImageCompression.compressImage(imageFile);
  
  // Then upload
  await api.uploadImage(compressed);
}
```

### 5. Use Debouncing for Search

```dart
final optimizer = ApiRequestOptimizer();

void onSearchChanged(String query) {
  optimizer.debounce(
    key: 'search',
    operation: () => searchUsers(query),
    duration: Duration(milliseconds: 300),
  );
}
```

### 6. Monitor Performance in Development

```dart
void main() {
  if (kDebugMode) {
    PerformanceMonitor().startMonitoring();
  }
  
  runApp(MyApp());
}
```

---

## Performance Targets

Based on Requirement 32, the app should meet these targets:

- ✅ **Home page load**: < 2 seconds on 4G
- ✅ **Frame rendering**: < 16ms (60 FPS)
- ✅ **List scrolling**: Smooth at 60 FPS
- ✅ **Image loading**: Lazy loaded with caching
- ✅ **Pagination**: 15 items per page, max 100
- ✅ **Image compression**: Before upload
- ✅ **API optimization**: Debouncing and batching
- ✅ **Animations**: 60 FPS maintained

---

## Troubleshooting

### Slow List Scrolling

1. Ensure using `ListView.builder` instead of `ListView`
2. Wrap complex widgets in `RepaintBoundary`
3. Reduce widget tree depth
4. Use `const` constructors where possible

### High Memory Usage

1. Clear image cache periodically
2. Implement pagination for large lists
3. Use `MemoryCache` with appropriate `maxSize`
4. Dispose controllers and streams properly

### Slow API Responses

1. Implement caching for frequently accessed data
2. Use debouncing for search/filter operations
3. Batch multiple operations when possible
4. Implement offline support with queue

### Janky Animations

1. Check frame timings with `PerformanceMonitor`
2. Reduce widget rebuilds
3. Use `RepaintBoundary` for static content
4. Optimize image sizes and formats

---

## Additional Resources

- [Flutter Performance Best Practices](https://flutter.dev/docs/perf/best-practices)
- [ListView.builder Documentation](https://api.flutter.dev/flutter/widgets/ListView/ListView.builder.html)
- [Image Caching in Flutter](https://pub.dev/packages/cached_network_image)
- [Performance Profiling](https://flutter.dev/docs/perf/rendering-performance)
