<?php

namespace App\Http\Controllers\Schemas;

/**
 * @OA\Schema(
 *     schema="User",
 *     type="object",
 *     title="User",
 *     description="User model",
 *     @OA\Property(property="id", type="integer", example=1),
 *     @OA\Property(property="name", type="string", example="John Doe"),
 *     @OA\Property(property="email", type="string", format="email", example="john@example.com"),
 *     @OA\Property(property="role", type="string", enum={"admin", "user"}, example="user"),
 *     @OA\Property(property="organization_name", type="string", example="Acme Corporation", nullable=true),
 *     @OA\Property(property="department_name", type="string", example="Finance", nullable=true),
 *     @OA\Property(property="admin_group_id", type="integer", example=1, nullable=true),
 *     @OA\Property(property="created_at", type="string", format="date-time"),
 *     @OA\Property(property="updated_at", type="string", format="date-time")
 * )
 *
 * @OA\Schema(
 *     schema="AdminGroup",
 *     type="object",
 *     title="AdminGroup",
 *     description="Admin group model for managing user groups",
 *     @OA\Property(property="id", type="integer", example=1),
 *     @OA\Property(property="admin_user_id", type="integer", example=1),
 *     @OA\Property(property="group_code", type="string", example="123456", minLength=4, maxLength=6, description="Unique 4-6 digit numeric code for group invitation"),
 *     @OA\Property(property="group_name", type="string", example="Acme Corp - John Doe", nullable=true),
 *     @OA\Property(property="is_active", type="boolean", example=true),
 *     @OA\Property(property="created_at", type="string", format="date-time"),
 *     @OA\Property(property="updated_at", type="string", format="date-time"),
 *     @OA\Property(property="admin", ref="#/components/schemas/User", description="Admin user who owns this group"),
 *     @OA\Property(property="members", type="array", @OA\Items(ref="#/components/schemas/User"), description="Users who are members of this group")
 * )
 *
 * @OA\Schema(
 *     schema="Expense",
 *     type="object",
 *     title="Expense",
 *     description="Expense model",
 *     @OA\Property(property="id", type="integer", example=1),
 *     @OA\Property(property="user_id", type="integer", example=1),
 *     @OA\Property(property="description", type="string", example="Office supplies"),
 *     @OA\Property(property="price_usd", type="number", format="float", example=50.00),
 *     @OA\Property(property="price_syp", type="number", format="float", example=125000.00, nullable=true),
 *     @OA\Property(property="price_try", type="number", format="float", example=1500.00, nullable=true),
 *     @OA\Property(property="has_invoice", type="boolean", example=true),
 *     @OA\Property(property="invoice_path", type="string", example="invoices/abc123.jpg", nullable=true),
 *     @OA\Property(property="expense_date", type="string", format="date", example="2025-10-22"),
 *     @OA\Property(property="sync_status", type="string", enum={"pending", "syncing", "synced", "failed"}, example="synced"),
 *     @OA\Property(property="synced_at", type="string", format="date-time", nullable=true),
 *     @OA\Property(property="created_at", type="string", format="date-time"),
 *     @OA\Property(property="updated_at", type="string", format="date-time"),
 *     @OA\Property(property="user", ref="#/components/schemas/User")
 * )
 *
 * @OA\Schema(
 *     schema="Transfer",
 *     type="object",
 *     title="Transfer",
 *     description="Transfer model",
 *     @OA\Property(property="id", type="integer", example=1),
 *     @OA\Property(property="user_id", type="integer", example=1),
 *     @OA\Property(property="recipient_name", type="string", example="Jane Smith"),
 *     @OA\Property(property="amount_usd", type="number", format="float", example=100.00),
 *     @OA\Property(property="transfer_date", type="string", format="date", example="2025-10-22"),
 *     @OA\Property(property="notes", type="string", example="Monthly payment", nullable=true),
 *     @OA\Property(property="sync_status", type="string", enum={"pending", "syncing", "synced", "failed"}, example="synced"),
 *     @OA\Property(property="created_at", type="string", format="date-time"),
 *     @OA\Property(property="updated_at", type="string", format="date-time"),
 *     @OA\Property(property="exchange", ref="#/components/schemas/Exchange"),
 *     @OA\Property(property="user", ref="#/components/schemas/User")
 * )
 *
 * @OA\Schema(
 *     schema="Exchange",
 *     type="object",
 *     title="Exchange",
 *     description="Currency exchange model",
 *     @OA\Property(property="id", type="integer", example=1),
 *     @OA\Property(property="transfer_id", type="integer", example=1),
 *     @OA\Property(property="converted_amount_syp", type="number", format="float", example=250000.00, nullable=true),
 *     @OA\Property(property="converted_amount_try", type="number", format="float", example=3000.00, nullable=true),
 *     @OA\Property(property="exchange_rate_usd_to_syp", type="number", format="float", example=2500.00, nullable=true),
 *     @OA\Property(property="exchange_rate_usd_to_try", type="number", format="float", example=30.00, nullable=true),
 *     @OA\Property(property="exchange_date", type="string", format="date", example="2025-10-22"),
 *     @OA\Property(property="created_at", type="string", format="date-time"),
 *     @OA\Property(property="updated_at", type="string", format="date-time")
 * )
 *
 * @OA\Schema(
 *     schema="Incoming",
 *     type="object",
 *     title="Incoming",
 *     description="Incoming funds model",
 *     @OA\Property(property="id", type="integer", example=1),
 *     @OA\Property(property="user_id", type="integer", example=1),
 *     @OA\Property(property="description", type="string", example="Client payment"),
 *     @OA\Property(property="amount_usd", type="number", format="float", example=500.00),
 *     @OA\Property(property="incoming_date", type="string", format="date", example="2025-10-22"),
 *     @OA\Property(property="sync_status", type="string", enum={"pending", "syncing", "synced", "failed"}, example="synced"),
 *     @OA\Property(property="created_at", type="string", format="date-time"),
 *     @OA\Property(property="updated_at", type="string", format="date-time"),
 *     @OA\Property(property="user", ref="#/components/schemas/User")
 * )
 *
 * @OA\Schema(
 *     schema="FundBox",
 *     type="object",
 *     title="FundBox",
 *     description="Fund box balance model",
 *     @OA\Property(property="id", type="integer", example=1),
 *     @OA\Property(property="balance_usd", type="number", format="float", example=10000.00),
 *     @OA\Property(property="last_calculated_at", type="string", format="date-time", nullable=true),
 *     @OA\Property(property="created_at", type="string", format="date-time"),
 *     @OA\Property(property="updated_at", type="string", format="date-time")
 * )
 *
 * @OA\Schema(
 *     schema="AuditLog",
 *     type="object",
 *     title="AuditLog",
 *     description="Audit log model",
 *     @OA\Property(property="id", type="integer", example=1),
 *     @OA\Property(property="user_id", type="integer", example=1, nullable=true),
 *     @OA\Property(property="action", type="string", example="create"),
 *     @OA\Property(property="resource_type", type="string", example="Expense"),
 *     @OA\Property(property="resource_id", type="integer", example=1, nullable=true),
 *     @OA\Property(property="ip_address", type="string", example="192.168.1.1", nullable=true),
 *     @OA\Property(property="user_agent", type="string", example="Mozilla/5.0...", nullable=true),
 *     @OA\Property(property="metadata", type="object", nullable=true),
 *     @OA\Property(property="created_at", type="string", format="date-time"),
 *     @OA\Property(property="user", ref="#/components/schemas/User")
 * )
 *
 * @OA\Schema(
 *     schema="PaginationMeta",
 *     type="object",
 *     title="Pagination Meta",
 *     description="Pagination metadata",
 *     @OA\Property(property="current_page", type="integer", example=1),
 *     @OA\Property(property="last_page", type="integer", example=5),
 *     @OA\Property(property="per_page", type="integer", example=15),
 *     @OA\Property(property="total", type="integer", example=75)
 * )
 *
 * @OA\Schema(
 *     schema="ErrorResponse",
 *     type="object",
 *     title="Error Response",
 *     description="Standard error response",
 *     @OA\Property(property="success", type="boolean", example=false),
 *     @OA\Property(property="message", type="string", example="An error occurred"),
 *     @OA\Property(property="errors", type="object", nullable=true)
 * )
 *
 * @OA\Schema(
 *     schema="SuccessResponse",
 *     type="object",
 *     title="Success Response",
 *     description="Standard success response",
 *     @OA\Property(property="success", type="boolean", example=true),
 *     @OA\Property(property="message", type="string", example="Operation successful"),
 *     @OA\Property(property="data", type="object", nullable=true)
 * )
 */
class OpenApiSchemas
{
    // This class only contains OpenAPI schema annotations
}
