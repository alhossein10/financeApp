<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/**
 * API Version Negotiation Middleware
 * 
 * Handles API version validation and returns appropriate responses
 * for unsupported API versions.
 */
class ApiVersionNegotiation
{
    /**
     * List of supported API versions
     */
    private const SUPPORTED_VERSIONS = ['v1'];
    
    /**
     * Current stable API version
     */
    private const CURRENT_VERSION = 'v1';
    
    /**
     * Deprecated versions with their end-of-life dates
     */
    private const DEPRECATED_VERSIONS = [
        // Example: 'v0' => '2025-12-31',
    ];

    /**
     * Handle an incoming request.
     *
     * @param  \Closure(\Illuminate\Http\Request): (\Symfony\Component\HttpFoundation\Response)  $next
     */
    public function handle(Request $request, Closure $next): Response
    {
        // Extract version from URL path (e.g., /api/v1/...)
        $version = $this->extractVersionFromPath($request->path());
        
        // If no version in path, this is the base API route
        if (!$version) {
            return $next($request);
        }
        
        // Check if version is supported
        if (!$this->isVersionSupported($version)) {
            return $this->unsupportedVersionResponse($version);
        }
        
        // Check if version is deprecated and add warning header
        if ($this->isVersionDeprecated($version)) {
            $response = $next($request);
            return $this->addDeprecationWarning($response, $version);
        }
        
        return $next($request);
    }
    
    /**
     * Extract API version from request path
     */
    private function extractVersionFromPath(string $path): ?string
    {
        // Match pattern: api/v{number}/...
        if (preg_match('#^api/(v\d+)(?:/|$)#', $path, $matches)) {
            return $matches[1];
        }
        
        return null;
    }
    
    /**
     * Check if the given version is supported
     */
    private function isVersionSupported(string $version): bool
    {
        return in_array($version, self::SUPPORTED_VERSIONS, true);
    }
    
    /**
     * Check if the given version is deprecated
     */
    private function isVersionDeprecated(string $version): bool
    {
        return array_key_exists($version, self::DEPRECATED_VERSIONS);
    }
    
    /**
     * Return response for unsupported API version
     */
    private function unsupportedVersionResponse(string $requestedVersion): Response
    {
        return response()->json([
            'success' => false,
            'message' => "API version '{$requestedVersion}' is not supported.",
            'error_code' => 'UNSUPPORTED_API_VERSION',
            'requested_version' => $requestedVersion,
            'current_version' => self::CURRENT_VERSION,
            'supported_versions' => self::SUPPORTED_VERSIONS,
            'documentation' => url('/api/documentation'),
            'endpoints' => $this->getVersionEndpoints(),
        ], 404);
    }
    
    /**
     * Add deprecation warning header to response
     */
    private function addDeprecationWarning(Response $response, string $version): Response
    {
        $eolDate = self::DEPRECATED_VERSIONS[$version];
        
        $response->headers->set(
            'X-API-Deprecation-Warning',
            "API version {$version} is deprecated and will be removed on {$eolDate}. Please migrate to {$this->getCurrentVersion()}."
        );
        
        $response->headers->set(
            'X-API-Deprecation-EOL',
            $eolDate
        );
        
        $response->headers->set(
            'X-API-Current-Version',
            self::CURRENT_VERSION
        );
        
        return $response;
    }
    
    /**
     * Get endpoints for all supported versions
     */
    private function getVersionEndpoints(): array
    {
        $endpoints = [];
        
        foreach (self::SUPPORTED_VERSIONS as $version) {
            $endpoints[$version] = url("/api/{$version}");
        }
        
        return $endpoints;
    }
    
    /**
     * Get current stable version
     */
    private function getCurrentVersion(): string
    {
        return self::CURRENT_VERSION;
    }
    
    /**
     * Get list of supported versions (for external use)
     */
    public static function getSupportedVersions(): array
    {
        return self::SUPPORTED_VERSIONS;
    }
    
    /**
     * Get list of deprecated versions (for external use)
     */
    public static function getDeprecatedVersions(): array
    {
        return self::DEPRECATED_VERSIONS;
    }
}
