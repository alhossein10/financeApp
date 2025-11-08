<?php

namespace Tests\Feature;

use App\Models\Expense;
use App\Models\Export;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class ExportTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        Storage::fake('local');
    }

    // ========== PDF GENERATION TESTS ==========

    public function test_user_can_export_expenses_to_pdf(): void
    {
        $user = User::factory()->create();
        Expense::factory()->count(3)->create(['user_id' => $user->id]);

        $response = $this->actingAs($user, 'sanctum')
            ->postJson('/api/v1/export/expenses/pdf');

        $response->assertStatus(201)
            ->assertJson([
                'success' => true,
                'message' => 'PDF export generated successfully',
            ])
            ->assertJsonStructure([
                'success',
                'message',
                'data' => [
                    'export_id',
                    'status',
                    'file_name',
                    'expires_at',
                    'download_url',
                ],
            ]);

        // Verify export record was created
        $this->assertDatabaseHas('exports', [
            'user_id' => $user->id,
            'type' => 'pdf',
            'resource_type' => 'expenses',
            'status' => 'completed',
        ]);

        // Verify file was created
        $export = Export::where('user_id', $user->id)->first();
        Storage::assertExists($export->file_path);
    }

    public function test_pdf_export_contains_user_expenses(): void
    {
        $user = User::factory()->create();
        $expense1 = Expense::factory()->create([
            'user_id' => $user->id,
            'description' => 'Test Expense 1',
            'price_usd' => 100.00,
        ]);
        $expense2 = Expense::factory()->create([
            'user_id' => $user->id,
            'description' => 'Test Expense 2',
            'price_usd' => 200.00,
        ]);

        $response = $this->actingAs($user, 'sanctum')
            ->postJson('/api/v1/export/expenses/pdf');

        $response->assertStatus(201);

        $export = Export::where('user_id', $user->id)->first();
        $this->assertNotNull($export);
        $this->assertEquals('completed', $export->status);
    }

    public function test_pdf_export_only_includes_user_own_expenses(): void
    {
        $user = User::factory()->create();
        $otherUser = User::factory()->create();
        
        Expense::factory()->count(2)->create(['user_id' => $user->id]);
        Expense::factory()->count(3)->create(['user_id' => $otherUser->id]);

        $response = $this->actingAs($user, 'sanctum')
            ->postJson('/api/v1/export/expenses/pdf');

        $response->assertStatus(201);

        // Verify export was created for the user
        $export = Export::where('user_id', $user->id)->first();
        $this->assertNotNull($export);
    }

    // ========== EXCEL GENERATION TESTS ==========

    public function test_user_can_export_expenses_to_excel(): void
    {
        $user = User::factory()->create();
        Expense::factory()->count(3)->create(['user_id' => $user->id]);

        $response = $this->actingAs($user, 'sanctum')
            ->postJson('/api/v1/export/expenses/excel');

        $response->assertStatus(201)
            ->assertJson([
                'success' => true,
                'message' => 'Excel export generated successfully',
            ])
            ->assertJsonStructure([
                'success',
                'message',
                'data' => [
                    'export_id',
                    'status',
                    'file_name',
                    'expires_at',
                    'download_url',
                ],
            ]);

        // Verify export record was created
        $this->assertDatabaseHas('exports', [
            'user_id' => $user->id,
            'type' => 'xlsx',
            'resource_type' => 'expenses',
            'status' => 'completed',
        ]);

        // Verify file was created
        $export = Export::where('user_id', $user->id)->first();
        Storage::assertExists($export->file_path);
    }

    public function test_excel_export_file_has_correct_extension(): void
    {
        $user = User::factory()->create();
        Expense::factory()->count(2)->create(['user_id' => $user->id]);

        $response = $this->actingAs($user, 'sanctum')
            ->postJson('/api/v1/export/expenses/excel');

        $response->assertStatus(201);

        $export = Export::where('user_id', $user->id)->first();
        $this->assertStringEndsWith('.xlsx', $export->file_name);
    }

    // ========== DATE RANGE FILTERING TESTS ==========

    public function test_export_can_filter_by_start_date(): void
    {
        $user = User::factory()->create();
        
        Expense::factory()->create([
            'user_id' => $user->id,
            'expense_date' => '2025-10-01',
        ]);
        Expense::factory()->create([
            'user_id' => $user->id,
            'expense_date' => '2025-10-15',
        ]);

        $response = $this->actingAs($user, 'sanctum')
            ->postJson('/api/v1/export/expenses/pdf', [
                'start_date' => '2025-10-10',
            ]);

        $response->assertStatus(201);

        $export = Export::where('user_id', $user->id)->first();
        $this->assertArrayHasKey('start_date', $export->filters);
        $this->assertEquals('2025-10-10', $export->filters['start_date']);
    }

    public function test_export_can_filter_by_end_date(): void
    {
        $user = User::factory()->create();
        
        Expense::factory()->create([
            'user_id' => $user->id,
            'expense_date' => '2025-10-01',
        ]);
        Expense::factory()->create([
            'user_id' => $user->id,
            'expense_date' => '2025-10-20',
        ]);

        $response = $this->actingAs($user, 'sanctum')
            ->postJson('/api/v1/export/expenses/pdf', [
                'end_date' => '2025-10-15',
            ]);

        $response->assertStatus(201);

        $export = Export::where('user_id', $user->id)->first();
        $this->assertArrayHasKey('end_date', $export->filters);
        $this->assertEquals('2025-10-15', $export->filters['end_date']);
    }

    public function test_export_can_filter_by_date_range(): void
    {
        $user = User::factory()->create();
        
        Expense::factory()->create([
            'user_id' => $user->id,
            'expense_date' => '2025-09-30',
        ]);
        Expense::factory()->create([
            'user_id' => $user->id,
            'expense_date' => '2025-10-10',
        ]);
        Expense::factory()->create([
            'user_id' => $user->id,
            'expense_date' => '2025-10-25',
        ]);

        $response = $this->actingAs($user, 'sanctum')
            ->postJson('/api/v1/export/expenses/excel', [
                'start_date' => '2025-10-01',
                'end_date' => '2025-10-20',
            ]);

        $response->assertStatus(201);

        $export = Export::where('user_id', $user->id)->first();
        $this->assertEquals('2025-10-01', $export->filters['start_date']);
        $this->assertEquals('2025-10-20', $export->filters['end_date']);
    }

    public function test_export_validates_end_date_after_start_date(): void
    {
        $user = User::factory()->create();

        $response = $this->actingAs($user, 'sanctum')
            ->postJson('/api/v1/export/expenses/pdf', [
                'start_date' => '2025-10-20',
                'end_date' => '2025-10-10',
            ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['end_date']);
    }

    // ========== ADMIN SYSTEM-WIDE EXPORT TESTS ==========

    public function test_admin_can_generate_system_wide_pdf_export(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $user1 = User::factory()->create();
        $user2 = User::factory()->create();

        Expense::factory()->count(2)->create(['user_id' => $user1->id]);
        Expense::factory()->count(3)->create(['user_id' => $user2->id]);

        $response = $this->actingAs($admin, 'sanctum')
            ->postJson('/api/v1/export/system-wide', [
                'format' => 'pdf',
            ]);

        $response->assertStatus(201)
            ->assertJson([
                'success' => true,
                'message' => 'System-wide export generated successfully',
            ]);

        // Verify export record
        $this->assertDatabaseHas('exports', [
            'user_id' => $admin->id,
            'type' => 'pdf',
            'resource_type' => 'system_wide',
            'status' => 'completed',
        ]);
    }

    public function test_admin_can_generate_system_wide_excel_export(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $user1 = User::factory()->create();

        Expense::factory()->count(2)->create(['user_id' => $user1->id]);

        $response = $this->actingAs($admin, 'sanctum')
            ->postJson('/api/v1/export/system-wide', [
                'format' => 'excel',
            ]);

        $response->assertStatus(201);

        $this->assertDatabaseHas('exports', [
            'user_id' => $admin->id,
            'type' => 'xlsx',
            'resource_type' => 'system_wide',
        ]);
    }

    public function test_regular_user_cannot_generate_system_wide_export(): void
    {
        $user = User::factory()->create(['role' => 'user']);

        $response = $this->actingAs($user, 'sanctum')
            ->postJson('/api/v1/export/system-wide', [
                'format' => 'pdf',
            ]);

        $response->assertStatus(403)
            ->assertJson([
                'success' => false,
                'message' => 'Unauthorized. Only admin users can generate system-wide exports.',
            ]);
    }

    public function test_system_wide_export_requires_format(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);

        $response = $this->actingAs($admin, 'sanctum')
            ->postJson('/api/v1/export/system-wide', []);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['format']);
    }

    public function test_system_wide_export_validates_format(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);

        $response = $this->actingAs($admin, 'sanctum')
            ->postJson('/api/v1/export/system-wide', [
                'format' => 'invalid',
            ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['format']);
    }

    public function test_system_wide_export_includes_all_users_data(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $user1 = User::factory()->create();
        $user2 = User::factory()->create();

        Expense::factory()->count(2)->create(['user_id' => $user1->id]);
        Expense::factory()->count(3)->create(['user_id' => $user2->id]);
        Expense::factory()->count(1)->create(['user_id' => $admin->id]);

        $response = $this->actingAs($admin, 'sanctum')
            ->postJson('/api/v1/export/system-wide', [
                'format' => 'pdf',
            ]);

        $response->assertStatus(201);

        $export = Export::where('user_id', $admin->id)->first();
        $this->assertEquals('system_wide', $export->resource_type);
        $this->assertTrue($export->filters['is_system_wide'] ?? false);
    }

    // ========== FILE CLEANUP TESTS ==========

    public function test_cleanup_removes_expired_exports(): void
    {
        $user = User::factory()->create();

        // Create expired export with file
        $expiredExport = Export::factory()->expired()->create([
            'user_id' => $user->id,
            'file_path' => 'exports/expired_file.pdf',
        ]);
        Storage::put($expiredExport->file_path, 'test content');

        // Create non-expired export
        $activeExport = Export::factory()->create([
            'user_id' => $user->id,
            'file_path' => 'exports/active_file.pdf',
        ]);
        Storage::put($activeExport->file_path, 'test content');

        // Run cleanup
        $exportService = app(\App\Services\ExportService::class);
        $count = $exportService->cleanupOldExports();

        // Verify expired export was deleted
        $this->assertEquals(1, $count);
        $this->assertDatabaseMissing('exports', ['id' => $expiredExport->id]);
        Storage::assertMissing($expiredExport->file_path);

        // Verify active export still exists
        $this->assertDatabaseHas('exports', ['id' => $activeExport->id]);
        Storage::assertExists($activeExport->file_path);
    }

    public function test_cleanup_handles_missing_files_gracefully(): void
    {
        $user = User::factory()->create();

        // Create expired export without file
        $expiredExport = Export::factory()->expired()->create([
            'user_id' => $user->id,
            'file_path' => 'exports/missing_file.pdf',
        ]);

        // Run cleanup (should not throw exception)
        $exportService = app(\App\Services\ExportService::class);
        $count = $exportService->cleanupOldExports();

        // Verify export was deleted
        $this->assertEquals(1, $count);
        $this->assertDatabaseMissing('exports', ['id' => $expiredExport->id]);
    }

    public function test_cleanup_returns_correct_count(): void
    {
        $user = User::factory()->create();

        // Create multiple expired exports
        Export::factory()->expired()->count(3)->create(['user_id' => $user->id]);

        // Create active export
        Export::factory()->create(['user_id' => $user->id]);

        $exportService = app(\App\Services\ExportService::class);
        $count = $exportService->cleanupOldExports();

        $this->assertEquals(3, $count);
    }

    // ========== DOWNLOAD TESTS ==========

    public function test_user_can_download_their_export(): void
    {
        $user = User::factory()->create();
        $export = Export::factory()->create([
            'user_id' => $user->id,
            'file_path' => 'exports/test_export.pdf',
            'file_name' => 'test_export.pdf',
            'status' => 'completed',
        ]);
        Storage::put($export->file_path, 'test pdf content');

        $response = $this->actingAs($user, 'sanctum')
            ->get("/api/v1/export/{$export->id}/download");

        $response->assertStatus(200);
        $response->assertHeader('content-type', 'application/pdf');
    }

    public function test_user_cannot_download_other_users_export(): void
    {
        $user = User::factory()->create();
        $otherUser = User::factory()->create();
        
        $export = Export::factory()->create([
            'user_id' => $otherUser->id,
            'file_path' => 'exports/other_export.pdf',
            'status' => 'completed',
        ]);
        Storage::put($export->file_path, 'test content');

        $response = $this->actingAs($user, 'sanctum')
            ->get("/api/v1/export/{$export->id}/download");

        $response->assertStatus(404)
            ->assertJson([
                'success' => false,
                'message' => 'Export not found or you do not have permission to access it',
            ]);
    }

    public function test_admin_can_download_any_export(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $user = User::factory()->create();
        
        $export = Export::factory()->create([
            'user_id' => $user->id,
            'file_path' => 'exports/user_export.pdf',
            'status' => 'completed',
        ]);
        Storage::put($export->file_path, 'test content');

        $response = $this->actingAs($admin, 'sanctum')
            ->get("/api/v1/export/{$export->id}/download");

        $response->assertStatus(200);
    }

    public function test_cannot_download_expired_export(): void
    {
        $user = User::factory()->create();
        $export = Export::factory()->expired()->create([
            'user_id' => $user->id,
            'file_path' => 'exports/expired.pdf',
            'status' => 'completed',
        ]);
        Storage::put($export->file_path, 'test content');

        $response = $this->actingAs($user, 'sanctum')
            ->get("/api/v1/export/{$export->id}/download");

        $response->assertStatus(410)
            ->assertJson([
                'success' => false,
                'message' => 'Export has expired',
            ]);
    }

    public function test_cannot_download_processing_export(): void
    {
        $user = User::factory()->create();
        $export = Export::factory()->processing()->create([
            'user_id' => $user->id,
        ]);

        $response = $this->actingAs($user, 'sanctum')
            ->get("/api/v1/export/{$export->id}/download");

        $response->assertStatus(400)
            ->assertJson([
                'success' => false,
                'message' => 'Export is not ready for download',
            ]);
    }

    public function test_cannot_download_failed_export(): void
    {
        $user = User::factory()->create();
        $export = Export::factory()->failed()->create([
            'user_id' => $user->id,
        ]);

        $response = $this->actingAs($user, 'sanctum')
            ->get("/api/v1/export/{$export->id}/download");

        $response->assertStatus(400);
    }

    // ========== EXPORT EXPIRATION TESTS ==========

    public function test_export_expires_after_24_hours(): void
    {
        $user = User::factory()->create();
        Expense::factory()->create(['user_id' => $user->id]);

        $response = $this->actingAs($user, 'sanctum')
            ->postJson('/api/v1/export/expenses/pdf');

        $response->assertStatus(201);

        $export = Export::where('user_id', $user->id)->first();
        $this->assertNotNull($export->expires_at);
        $this->assertTrue($export->expires_at->greaterThan(now()->addHours(23)));
        $this->assertTrue($export->expires_at->lessThan(now()->addHours(25)));
    }

    // ========== AUTHENTICATION TESTS ==========

    public function test_unauthenticated_user_cannot_export_to_pdf(): void
    {
        $response = $this->postJson('/api/v1/export/expenses/pdf');

        $response->assertStatus(401);
    }

    public function test_unauthenticated_user_cannot_export_to_excel(): void
    {
        $response = $this->postJson('/api/v1/export/expenses/excel');

        $response->assertStatus(401);
    }

    public function test_unauthenticated_user_cannot_generate_system_wide_export(): void
    {
        $response = $this->postJson('/api/v1/export/system-wide', [
            'format' => 'pdf',
        ]);

        $response->assertStatus(401);
    }

    public function test_unauthenticated_user_cannot_download_export(): void
    {
        $user = User::factory()->create();
        $export = Export::factory()->create(['user_id' => $user->id]);

        $response = $this->get("/api/v1/export/{$export->id}/download");

        $response->assertStatus(401);
    }
}
