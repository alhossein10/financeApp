<?php

namespace App\Http\Controllers;

/**
 * @OA\Info(
 *     version="1.0.0",
 *     title="Finance Backend API",
 *     description="RESTful API backend for dual-version finance management application supporting Admin and User versions of Flutter mobile app",
 *     @OA\Contact(
 *         email="support@financeapp.com"
 *     ),
 *     @OA\License(
 *         name="MIT",
 *         url="https://opensource.org/licenses/MIT"
 *     )
 * )
 *
 * @OA\Server(
 *     url=L5_SWAGGER_CONST_HOST,
 *     description="API Server"
 * )
 *
 * @OA\SecurityScheme(
 *     securityScheme="sanctum",
 *     type="http",
 *     scheme="bearer",
 *     bearerFormat="JWT",
 *     description="Laravel Sanctum token authentication. Use the token received from login endpoint."
 * )
 *
 * @OA\Tag(
 *     name="Authentication",
 *     description="User authentication and authorization endpoints"
 * )
 *
 * @OA\Tag(
 *     name="Expenses",
 *     description="Expense management endpoints"
 * )
 *
 * @OA\Tag(
 *     name="Transfers",
 *     description="Transfer and currency exchange management endpoints"
 * )
 *
 * @OA\Tag(
 *     name="Incoming",
 *     description="Incoming funds management endpoints"
 * )
 *
 * @OA\Tag(
 *     name="Fund Box",
 *     description="Fund box balance management endpoints (Admin only)"
 * )
 *
 * @OA\Tag(
 *     name="Admin Dashboard",
 *     description="Admin dashboard and analytics endpoints"
 * )
 *
 * @OA\Tag(
 *     name="Files",
 *     description="File storage and management endpoints"
 * )
 *
 * @OA\Tag(
 *     name="Sync",
 *     description="Data synchronization endpoints"
 * )
 *
 * @OA\Tag(
 *     name="User Profile",
 *     description="User profile management endpoints"
 * )
 *
 * @OA\Tag(
 *     name="Export",
 *     description="Data export endpoints"
 * )
 *
 * @OA\Tag(
 *     name="Audit Logs",
 *     description="Audit logging endpoints (Admin only)"
 * )
 *
 * @OA\Tag(
 *     name="Admin Group Management",
 *     description="Admin group management endpoints for creating and managing user groups"
 * )
 *
 * @OA\Tag(
 *     name="User Group Management",
 *     description="User group membership endpoints for joining and viewing groups"
 * )
 */
abstract class Controller
{
    //
}
