import 'dart:io';
import 'endpoint_coverage_tracker.dart';

/// Script to run endpoint coverage analysis
/// 
/// This script analyzes the Flutter codebase and generates a comprehensive
/// coverage report showing which Postman API v3.1 endpoints are implemented.
/// 
/// Usage: dart run lib/core/utils/run_coverage_analysis.dart
Future<void> main() async {
  print('Starting Postman API v3.1 Endpoint Coverage Analysis...\n');
  
  final tracker = EndpointCoverageTracker();
  
  // Generate coverage report
  print('Analyzing codebase...');
  final report = await tracker.generateReport();
  
  // Print formatted report to console
  print(report.toFormattedString());
  
  // Get missing endpoints
  final missing = await tracker.getMissingEndpoints();
  
  if (missing.isNotEmpty) {
    print('\nMISSING ENDPOINTS');
    print('─' * 80);
    
    // Group by priority
    final highPriority = missing.where((e) => e.priority == 'HIGH').toList();
    final mediumPriority = missing.where((e) => e.priority == 'MEDIUM').toList();
    final lowPriority = missing.where((e) => e.priority == 'LOW').toList();
    
    if (highPriority.isNotEmpty) {
      print('\nHIGH PRIORITY (${highPriority.length}):');
      for (final endpoint in highPriority) {
        print('  • ${endpoint.category}: ${endpoint.endpoint}');
      }
    }
    
    if (mediumPriority.isNotEmpty) {
      print('\nMEDIUM PRIORITY (${mediumPriority.length}):');
      for (final endpoint in mediumPriority) {
        print('  • ${endpoint.category}: ${endpoint.endpoint}');
      }
    }
    
    if (lowPriority.isNotEmpty) {
      print('\nLOW PRIORITY (${lowPriority.length}):');
      for (final endpoint in lowPriority) {
        print('  • ${endpoint.category}: ${endpoint.endpoint}');
      }
    }
  } else {
    print('\n✓ ALL ENDPOINTS IMPLEMENTED!');
  }
  
  // Save report to file
  final reportFile = File('.kiro/specs/postman-api-v3.1-verification/COVERAGE_REPORT.md');
  await reportFile.parent.create(recursive: true);
  
  final markdown = _generateMarkdownReport(report, missing);
  await reportFile.writeAsString(markdown);
  
  print('\n✓ Coverage report saved to: ${reportFile.path}');
  
  // Exit with appropriate code
  if (report.isComplete) {
    print('\n✓ SUCCESS: 100% endpoint coverage achieved!');
    exit(0);
  } else {
    print('\n⚠ WARNING: ${report.totalMissing} endpoints still need implementation');
    exit(1);
  }
}

/// Generate markdown report
String _generateMarkdownReport(CoverageReport report, List<MissingEndpoint> missing) {
  final buffer = StringBuffer();
  
  buffer.writeln('# Postman API v3.1 Endpoint Coverage Report');
  buffer.writeln();
  buffer.writeln('**Generated:** ${report.generatedAt.toIso8601String()}');
  buffer.writeln();
  
  buffer.writeln('## Overall Coverage');
  buffer.writeln();
  buffer.writeln('| Metric | Value |');
  buffer.writeln('|--------|-------|');
  buffer.writeln('| Total Endpoints | ${report.totalEndpoints} |');
  buffer.writeln('| Implemented | ${report.totalImplemented} |');
  buffer.writeln('| Missing | ${report.totalMissing} |');
  buffer.writeln('| Coverage | ${report.overallCoverage.toStringAsFixed(1)}% |');
  buffer.writeln();
  
  buffer.writeln('## Category Breakdown');
  buffer.writeln();
  buffer.writeln('| Category | Implemented | Total | Coverage | Status |');
  buffer.writeln('|----------|-------------|-------|----------|--------|');
  
  for (final result in report.categoryCoverage.values) {
    final status = result.isComplete ? '✅ Complete' : '⚠️ Incomplete';
    buffer.writeln(
      '| ${result.category} | ${result.implementedEndpoints} | ${result.totalEndpoints} | '
      '${result.coveragePercentage.toStringAsFixed(1)}% | $status |',
    );
  }
  buffer.writeln();
  
  if (missing.isNotEmpty) {
    buffer.writeln('## Missing Endpoints');
    buffer.writeln();
    
    // Group by priority
    final highPriority = missing.where((e) => e.priority == 'HIGH').toList();
    final mediumPriority = missing.where((e) => e.priority == 'MEDIUM').toList();
    final lowPriority = missing.where((e) => e.priority == 'LOW').toList();
    
    if (highPriority.isNotEmpty) {
      buffer.writeln('### High Priority (${highPriority.length})');
      buffer.writeln();
      for (final endpoint in highPriority) {
        buffer.writeln('- **${endpoint.category}**: `${endpoint.endpoint}`');
      }
      buffer.writeln();
    }
    
    if (mediumPriority.isNotEmpty) {
      buffer.writeln('### Medium Priority (${mediumPriority.length})');
      buffer.writeln();
      for (final endpoint in mediumPriority) {
        buffer.writeln('- **${endpoint.category}**: `${endpoint.endpoint}`');
      }
      buffer.writeln();
    }
    
    if (lowPriority.isNotEmpty) {
      buffer.writeln('### Low Priority (${lowPriority.length})');
      buffer.writeln();
      for (final endpoint in lowPriority) {
        buffer.writeln('- **${endpoint.category}**: `${endpoint.endpoint}`');
      }
      buffer.writeln();
    }
  } else {
    buffer.writeln('## ✅ All Endpoints Implemented');
    buffer.writeln();
    buffer.writeln('Congratulations! All Postman API v3.1 endpoints have been successfully implemented.');
    buffer.writeln();
  }
  
  buffer.writeln('## Detailed Endpoint List');
  buffer.writeln();
  
  for (final result in report.categoryCoverage.values) {
    buffer.writeln('### ${result.category}');
    buffer.writeln();
    
    for (final endpoint in result.endpoints) {
      final implemented = EndpointCoverageTracker.endpointImplementations.containsKey(endpoint);
      final status = implemented ? '✅' : '❌';
      buffer.writeln('- $status `$endpoint`');
    }
    buffer.writeln();
  }
  
  buffer.writeln('---');
  buffer.writeln();
  buffer.writeln('*This report was automatically generated by the Endpoint Coverage Tracker.*');
  
  return buffer.toString();
}
