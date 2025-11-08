<?php

namespace App\Services;

use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use InvalidArgumentException;

class FileStorageService
{
    /**
     * Allowed file types for upload
     */
    private const ALLOWED_TYPES = ['image/jpeg', 'image/jpg', 'image/png', 'application/pdf'];
    
    /**
     * Maximum file size in bytes (10MB)
     */
    private const MAX_FILE_SIZE = 10 * 1024 * 1024;
    
    /**
     * Maximum image width for compression
     */
    private const MAX_IMAGE_WIDTH = 1920;
    
    /**
     * Storage disk to use
     */
    private string $disk;
    
    public function __construct()
    {
        $this->disk = config('filesystems.invoices', 'local');
    }
    
    /**
     * Upload a file with validation
     *
     * @param UploadedFile $file
     * @param string $directory
     * @return string File path
     * @throws InvalidArgumentException
     */
    public function uploadFile(UploadedFile $file, string $directory = 'invoices'): string
    {
        // Validate file
        $this->validateFile($file);
        
        // Compress image if it's an image file
        if ($this->isImage($file)) {
            $file = $this->compressImage($file);
        }
        
        // Generate unique filename
        $filename = $this->generateUniqueFilename($file);
        
        // Store file
        $path = $file->storeAs($directory, $filename, $this->disk);
        
        if (!$path) {
            throw new \RuntimeException('Failed to store file');
        }
        
        return $path;
    }
    
    /**
     * Compress image to maximum width using GD library
     *
     * @param UploadedFile $file
     * @param int $maxWidth
     * @return UploadedFile
     */
    public function compressImage(UploadedFile $file, int $maxWidth = self::MAX_IMAGE_WIDTH): UploadedFile
    {
        if (!$this->isImage($file)) {
            return $file;
        }
        
        // Get image info
        $imageInfo = getimagesize($file->getRealPath());
        if (!$imageInfo) {
            return $file;
        }
        
        [$width, $height] = $imageInfo;
        
        // Only resize if image is wider than max width
        if ($width <= $maxWidth) {
            return $file;
        }
        
        // Calculate new dimensions
        $newWidth = $maxWidth;
        $newHeight = (int) ($height * ($maxWidth / $width));
        
        // Create image resource based on type
        $sourceImage = match ($file->getMimeType()) {
            'image/jpeg', 'image/jpg' => imagecreatefromjpeg($file->getRealPath()),
            'image/png' => imagecreatefrompng($file->getRealPath()),
            default => null,
        };
        
        if (!$sourceImage) {
            return $file;
        }
        
        // Create new image
        $newImage = imagecreatetruecolor($newWidth, $newHeight);
        
        // Preserve transparency for PNG
        if ($file->getMimeType() === 'image/png') {
            imagealphablending($newImage, false);
            imagesavealpha($newImage, true);
        }
        
        // Resize
        imagecopyresampled($newImage, $sourceImage, 0, 0, 0, 0, $newWidth, $newHeight, $width, $height);
        
        // Save to temp file
        $tempPath = sys_get_temp_dir() . '/' . Str::random(40) . '.' . $file->getClientOriginalExtension();
        
        match ($file->getMimeType()) {
            'image/jpeg', 'image/jpg' => imagejpeg($newImage, $tempPath, 85),
            'image/png' => imagepng($newImage, $tempPath, 8),
            default => null,
        };
        
        // Free memory
        imagedestroy($sourceImage);
        imagedestroy($newImage);
        
        // Create new UploadedFile instance
        return new UploadedFile(
            $tempPath,
            $file->getClientOriginalName(),
            $file->getMimeType(),
            null,
            true
        );
    }
    
    /**
     * Delete a file
     *
     * @param string $path
     * @return bool
     */
    public function deleteFile(string $path): bool
    {
        if (!$path) {
            return false;
        }
        
        return Storage::disk($this->disk)->delete($path);
    }
    
    /**
     * Get file URL for secure access
     *
     * @param string $path
     * @return string
     */
    public function getFileUrl(string $path): string
    {
        if (!$path) {
            throw new InvalidArgumentException('File path cannot be empty');
        }
        
        // For local disk, generate a temporary URL via controller
        // For S3, generate a temporary signed URL
        if ($this->disk === 's3') {
            return Storage::disk($this->disk)->temporaryUrl($path, now()->addMinutes(30));
        }
        
        // For local storage, return a route that will serve the file
        return route('files.download', ['path' => encrypt($path)]);
    }
    
    /**
     * Validate uploaded file
     *
     * @param UploadedFile $file
     * @return bool
     * @throws InvalidArgumentException
     */
    public function validateFile(UploadedFile $file): bool
    {
        // Check if file is valid
        if (!$file->isValid()) {
            throw new InvalidArgumentException('Invalid file upload');
        }
        
        // Check file size
        if ($file->getSize() > self::MAX_FILE_SIZE) {
            throw new InvalidArgumentException('File size exceeds maximum allowed size of 10MB');
        }
        
        // Check file type
        if (!in_array($file->getMimeType(), self::ALLOWED_TYPES)) {
            throw new InvalidArgumentException('File type not allowed. Allowed types: JPEG, PNG, PDF');
        }
        
        return true;
    }
    
    /**
     * Check if file is an image
     *
     * @param UploadedFile $file
     * @return bool
     */
    private function isImage(UploadedFile $file): bool
    {
        return in_array($file->getMimeType(), ['image/jpeg', 'image/jpg', 'image/png']);
    }
    
    /**
     * Generate unique filename
     *
     * @param UploadedFile $file
     * @return string
     */
    private function generateUniqueFilename(UploadedFile $file): string
    {
        $extension = $file->getClientOriginalExtension();
        return Str::random(40) . '.' . $extension;
    }
    
    /**
     * Check if file exists
     *
     * @param string $path
     * @return bool
     */
    public function fileExists(string $path): bool
    {
        return Storage::disk($this->disk)->exists($path);
    }
    
    /**
     * Get file contents
     *
     * @param string $path
     * @return string
     */
    public function getFileContents(string $path): string
    {
        if (!$this->fileExists($path)) {
            throw new InvalidArgumentException('File not found');
        }
        
        return Storage::disk($this->disk)->get($path);
    }
    
    /**
     * Get file mime type
     *
     * @param string $path
     * @return string
     */
    public function getFileMimeType(string $path): string
    {
        if (!$this->fileExists($path)) {
            throw new InvalidArgumentException('File not found');
        }
        
        return Storage::disk($this->disk)->mimeType($path);
    }
}
