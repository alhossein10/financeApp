<?php

namespace App\Http\Controllers;

use App\Services\FileStorageService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\StreamedResponse;

class FileController extends Controller
{
    /**
     * Create a new FileController instance.
     *
     * @param FileStorageService $fileStorageService
     */
    public function __construct(
        protected FileStorageService $fileStorageService
    ) {}

    /**
     * Upload a file
     *
     * @OA\Post(
     *     path="/api/v1/files/upload",
     *     tags={"Files"},
     *     summary="Upload a file",
     *     description="Uploads a file with validation (type, size limits). Images are compressed to max 1920px width.",
     *     security={{"sanctum":{}}},
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\MediaType(
     *             mediaType="multipart/form-data",
     *             @OA\Schema(
     *                 required={"file"},
     *                 @OA\Property(property="file", type="string", format="binary", description="File to upload (JPEG, PNG, PDF, max 10MB)"),
     *                 @OA\Property(property="directory", type="string", example="invoices", description="Optional directory name")
     *             )
     *         )
     *     ),
     *     @OA\Response(
     *         response=201,
     *         description="File uploaded successfully",
     *         @OA\JsonContent(
     *             @OA\Property(property="success", type="boolean", example=true),
     *             @OA\Property(property="message", type="string", example="File uploaded successfully"),
     *             @OA\Property(property="data", type="object",
     *                 @OA\Property(property="path", type="string", example="files/abc123.jpg"),
     *                 @OA\Property(property="url", type="string", example="http://localhost:8000/storage/files/abc123.jpg")
     *             )
     *         )
     *     ),
     *     @OA\Response(response=401, description="Unauthenticated"),
     *     @OA\Response(response=422, description="Validation error")
     * )
     *
     * @param Request $request
     * @return JsonResponse
     */
    public function upload(Request $request): JsonResponse
    {
        // Validate the uploaded file
        $request->validate([
            'file' => 'required|file|mimes:jpeg,jpg,png,pdf|max:10240', // 10MB max
            'directory' => 'nullable|string',
        ]);

        try {
            $directory = $request->input('directory', 'files');
            $path = $this->fileStorageService->uploadFile($request->file('file'), $directory);

            return response()->json([
                'success' => true,
                'message' => 'File uploaded successfully',
                'data' => [
                    'path' => $path,
                    'url' => $this->fileStorageService->getFileUrl($path),
                ],
            ], 201);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to upload file: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Download a file by encrypted path
     *
     * @OA\Get(
     *     path="/api/v1/files/download",
     *     tags={"Files"},
     *     summary="Download file",
     *     description="Downloads a file using an encrypted path parameter for secure access",
     *     security={{"sanctum":{}}},
     *     @OA\Parameter(
     *         name="path",
     *         in="query",
     *         required=true,
     *         description="Encrypted file path",
     *         @OA\Schema(type="string")
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="File download",
     *         @OA\MediaType(
     *             mediaType="application/octet-stream",
     *             @OA\Schema(type="string", format="binary")
     *         )
     *     ),
     *     @OA\Response(response=401, description="Unauthenticated"),
     *     @OA\Response(response=404, description="File not found"),
     *     @OA\Response(response=500, description="Failed to download file")
     * )
     *
     * @param Request $request
     * @return StreamedResponse|JsonResponse
     */
    public function download(Request $request): StreamedResponse|JsonResponse
    {
        try {
            // Decrypt the path
            $path = decrypt($request->query('path'));

            // Check if file exists
            if (!$this->fileStorageService->fileExists($path)) {
                return response()->json([
                    'success' => false,
                    'message' => 'File not found',
                ], 404);
            }

            $fileContents = $this->fileStorageService->getFileContents($path);
            $mimeType = $this->fileStorageService->getFileMimeType($path);
            $filename = basename($path);

            return response()->streamDownload(function () use ($fileContents) {
                echo $fileContents;
            }, $filename, [
                'Content-Type' => $mimeType,
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to download file: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Delete a file by encrypted path
     *
     * @OA\Delete(
     *     path="/api/v1/files",
     *     tags={"Files"},
     *     summary="Delete file",
     *     description="Deletes a file using an encrypted path parameter",
     *     security={{"sanctum":{}}},
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\JsonContent(
     *             required={"path"},
     *             @OA\Property(property="path", type="string", description="Encrypted file path")
     *         )
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="File deleted successfully",
     *         @OA\JsonContent(
     *             @OA\Property(property="success", type="boolean", example=true),
     *             @OA\Property(property="message", type="string", example="File deleted successfully")
     *         )
     *     ),
     *     @OA\Response(response=401, description="Unauthenticated"),
     *     @OA\Response(response=404, description="File not found"),
     *     @OA\Response(response=500, description="Failed to delete file")
     * )
     *
     * @param Request $request
     * @return JsonResponse
     */
    public function delete(Request $request): JsonResponse
    {
        $request->validate([
            'path' => 'required|string',
        ]);

        try {
            // Decrypt the path
            $path = decrypt($request->input('path'));

            // Check if file exists
            if (!$this->fileStorageService->fileExists($path)) {
                return response()->json([
                    'success' => false,
                    'message' => 'File not found',
                ], 404);
            }

            $this->fileStorageService->deleteFile($path);

            return response()->json([
                'success' => true,
                'message' => 'File deleted successfully',
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to delete file: ' . $e->getMessage(),
            ], 500);
        }
    }
}
