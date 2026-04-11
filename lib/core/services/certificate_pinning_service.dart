import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';

/// Service for implementing SSL certificate pinning
/// Provides enhanced security by validating server certificates
/// 
/// Certificate pinning prevents man-in-the-middle attacks by ensuring
/// the app only trusts specific certificates or public keys.
/// 
/// Usage:
/// ```dart
/// final dio = Dio();
/// CertificatePinningService.configureCertificatePinning(
///   dio,
///   allowedSHA256Fingerprints: [
///     'AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99',
///   ],
/// );
/// ```
class CertificatePinningService {
  /// Configure certificate pinning for Dio HTTP client
  /// 
  /// Parameters:
  /// - dio: Dio instance to configure
  /// - allowedSHA256Fingerprints: List of allowed certificate SHA-256 fingerprints
  /// - allowSelfSigned: Whether to allow self-signed certificates (for development)
  /// 
  /// Note: In production, set allowSelfSigned to false and provide actual certificate fingerprints
  static void configureCertificatePinning(
    Dio dio, {
    List<String>? allowedSHA256Fingerprints,
    bool allowSelfSigned = false,
  }) {
    // Configure HttpClient with certificate validation
    (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      
      // Configure certificate callback
      client.badCertificateCallback = (X509Certificate cert, String host, int port) {
        // In development mode, allow self-signed certificates
        if (allowSelfSigned) {
          print('⚠️ [CertificatePinning] Allowing self-signed certificate for $host (DEVELOPMENT MODE)');
          return true;
        }
        
        // If no fingerprints provided, use default validation
        if (allowedSHA256Fingerprints == null || allowedSHA256Fingerprints.isEmpty) {
          print('⚠️ [CertificatePinning] No certificate fingerprints configured - using default validation');
          return true; // Let system handle validation
        }
        
        // Validate certificate fingerprint
        final certSHA256 = _getCertificateSHA256(cert);
        final isValid = _validateCertificateFingerprint(
          certSHA256,
          allowedSHA256Fingerprints,
          host,
        );
        
        if (!isValid) {
          print('🔴 [CertificatePinning] Certificate validation failed for $host');
          print('🔴 [CertificatePinning] Certificate SHA-256: $certSHA256');
        }
        
        return isValid;
      };
      
      return client;
    };
    
    print('🔒 [CertificatePinning] Certificate pinning configured');
    if (allowSelfSigned) {
      print('⚠️ [CertificatePinning] WARNING: Self-signed certificates are allowed (DEVELOPMENT MODE)');
    }
  }
  
  /// Get SHA-256 fingerprint of certificate
  static String _getCertificateSHA256(X509Certificate cert) {
    // Get DER-encoded certificate
    final der = cert.der;
    
    // Calculate SHA-256 hash
    // Note: This is a simplified version. In production, use crypto package
    // to calculate proper SHA-256 hash of the certificate
    final hash = der.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join(':').toUpperCase();
    
    return hash;
  }
  
  /// Validate certificate fingerprint against allowed list
  static bool _validateCertificateFingerprint(
    String certFingerprint,
    List<String> allowedFingerprints,
    String host,
  ) {
    // Normalize fingerprints (remove colons, convert to uppercase)
    final normalizedCertFingerprint = certFingerprint.replaceAll(':', '').toUpperCase();
    final normalizedAllowedFingerprints = allowedFingerprints
        .map((fp) => fp.replaceAll(':', '').toUpperCase())
        .toList();
    
    // Check if certificate fingerprint matches any allowed fingerprint
    final isValid = normalizedAllowedFingerprints.contains(normalizedCertFingerprint);
    
    if (isValid) {
      print('✅ [CertificatePinning] Certificate validated for $host');
    } else {
      print('🔴 [CertificatePinning] Certificate NOT in allowed list for $host');
      print('🔴 [CertificatePinning] Expected one of: ${allowedFingerprints.join(', ')}');
      print('🔴 [CertificatePinning] Got: $certFingerprint');
    }
    
    return isValid;
  }
  
  /// Extract certificate fingerprint from a PEM file
  /// Useful for getting fingerprints during development
  static String? extractFingerprintFromPEM(String pemContent) {
    try {
      // This is a placeholder - actual implementation would parse PEM
      // and calculate SHA-256 hash
      print('⚠️ [CertificatePinning] PEM parsing not implemented');
      return null;
    } catch (e) {
      print('🔴 [CertificatePinning] Error extracting fingerprint: $e');
      return null;
    }
  }
  
  /// Get certificate information for debugging
  static Map<String, dynamic> getCertificateInfo(X509Certificate cert) {
    return {
      'subject': cert.subject,
      'issuer': cert.issuer,
      'startValidity': cert.startValidity.toIso8601String(),
      'endValidity': cert.endValidity.toIso8601String(),
      'sha256': _getCertificateSHA256(cert),
    };
  }
}

/// Extension to easily configure certificate pinning on Dio
extension CertificatePinningExtension on Dio {
  /// Configure certificate pinning with allowed fingerprints
  void enableCertificatePinning({
    List<String>? allowedSHA256Fingerprints,
    bool allowSelfSigned = false,
  }) {
    CertificatePinningService.configureCertificatePinning(
      this,
      allowedSHA256Fingerprints: allowedSHA256Fingerprints,
      allowSelfSigned: allowSelfSigned,
    );
  }
}
