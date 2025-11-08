<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class ValidateFileUpload
{
    /**
     * Allowed file MIME types
     */
    protected array $allowedMimeTypes = [
        'image/jpeg',
        'image/jpg',
        'image/png',
        'application/pdf',
    ];
    
    /**
     * Maximum file size in bytes (10MB)
     */
    protected int $maxFileSize = 10485760; // 10 * 1024 * 1024
    
    /**
     * Handle an incoming request.
     *
     * @param  \Closure(\Illuminate\Http\Request): (\Symfony\Component\HttpFoundation\Response)  $next
     */
    public function handle(Request $request, Closure $next): Response
    {
        // Check if request has files
        if (!$request->hasFile('file') && !$request->hasFile('invoice')) {
            return $next($request);
        }
        
        // Get the file from request
        $file = $request->file('file') ?? $request->file('invoice');
        
        if (!$file) {
            return $next($request);
        }
        
        // Validate file is uploaded successfully
        if (!$file->isValid()) {
            return response()->json([
                'success' => false,
                'message' => 'File upload failed.',
                'error_code' => 'FILE_UPLOAD_FAILED',
            ], 400);
        }
        
        // Validate file size
        if ($file->getSize() > $this->maxFileSize) {
            return response()->json([
                'success' => false,
                'message' => 'File size exceeds maximum allowed size of 10MB.',
                'error_code' => 'FILE_TOO_LARGE',
                'max_size_mb' => 10,
            ], 422);
        }
        
        // Validate MIME type
        $mimeType = $file->getMimeType();
        if (!in_array($mimeType, $this->allowedMimeTypes)) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid file type. Only JPEG, PNG, and PDF files are allowed.',
                'error_code' => 'INVALID_FILE_TYPE',
                'allowed_types' => ['jpeg', 'jpg', 'png', 'pdf'],
            ], 422);
        }
        
        // Additional security checks
        $extension = $file->getClientOriginalExtension();
        $allowedExtensions = ['jpg', 'jpeg', 'png', 'pdf'];
        
        if (!in_array(strtolower($extension), $allowedExtensions)) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid file extension.',
                'error_code' => 'INVALID_FILE_EXTENSION',
            ], 422);
        }
        
        // Check for double extensions (e.g., file.php.jpg)
        $filename = $file->getClientOriginalName();
        if (substr_count($filename, '.') > 1) {
            return response()->json([
                'success' => false,
                'message' => 'File name contains multiple extensions.',
                'error_code' => 'SUSPICIOUS_FILE_NAME',
            ], 422);
        }
        
        return $next($request);
    }
}
