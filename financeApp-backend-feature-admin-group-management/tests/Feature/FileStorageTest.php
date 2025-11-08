<?php

namespace Tests\Feature;

use App\Models\Expense;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class FileStorageTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        Storage::fake('local');
    }

    // ========== FILE UPLOAD VALIDATION TESTS ==========

    public function test_user_can_upload_valid_jpeg_file(): void
    {
        $user = User::factory()->create();
        $file = UploadedFile::fake()->image('invoice.jpg', 800, 600)->size(1024);

        $response = $this->actingAs($user, 'sanctum')
            ->postJson('/api/v1/files/upload', [
                'file' => $file,
                'directory' => 'test-uploads',
            ]);

        $response->assertStatus(201)
            ->assertJson([
                'success' => true,
                'message' => 'File uploaded successfully',
            ])
            ->assertJsonStructure([
                'data' => ['path', 'url'],
            ]);

        $path = $response->json('data.path');
        Storage::disk('local')->assertExists($path);
    }

    public function test_user_can_upload_valid_png_file(): void
    {
        $user = User::factory()->create();
        $file = UploadedFile::fake()->image('invoice.png', 800, 600)->size(1024);

        $response = $this->actingAs($user, 'sanctum')
            ->postJson('/api/v1/files/upload', [
                'file' => $file,
            ]);

        $response->assertStatus(201);

        $path = $response->json('data.path');
        Storage::disk('local')->assertExists($path);
    }

    public function test_user_can_upload_valid_pdf_file(): void
    {
        $user = User::factory()->create();
        $file = UploadedFile::fake()->create('invoice.pdf', 1024, 'application/pdf');

        $response = $this->actingAs($user, 'sanctum')
            ->postJson('/api/v1/files/upload', [
                'file' => $file,
            ]);

        $response->assertStatus(201);

        $path = $response->json('data.path');
        Storage::disk('local')->assertExists($path);
    }

    public function test_upload_rejects_file_exceeding_size_limit(): void
    {
        $user = User::factory()->create();
        $file = UploadedFile::fake()->image('large.jpg')->size(11000); // 11MB

        $response = $this->actingAs($user, 'sanctum')
            ->postJson('/api/v1/files/upload', [
                'file' => $file,
            ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['file']);
    }

    public function test_upload_rejects_invalid_file_type(): void
    {
        $user = User::factory()->create();
        $file = UploadedFile::fake()->create('document.txt', 100, 'text/plain');

        $response = $this->actingAs($user, 'sanctum')
            ->postJson('/api/v1/files/upload', [
                'file' => $file,
            ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['file']);
    }

    public function test_upload_requires_file_parameter(): void
    {
        $user = User::factory()->create();

        $response = $this->actingAs($user, 'sanctum')
            ->postJson('/api/v1/files/upload', []);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['file']);
    }

    public function test_unauthenticated_user_cannot_upload_file(): void
    {
        $file = UploadedFile::fake()->image('invoice.jpg');

        $response = $this->postJson('/api/v1/files/upload', [
            'file' => $file,
        ]);

        $response->assertStatus(401);
    }

    // ========== IMAGE COMPRESSION TESTS ==========

    public function test_large_image_is_compressed_to_max_width(): void
    {
        $user = User::factory()->create();
        $expense = Expense::factory()->create(['user_id' => $user->id]);
        
        // Create a large image (2500x2000)
        $file = UploadedFile::fake()->image('large-invoice.jpg', 2500, 2000)->size(3000);

        $response = $this->actingAs($user, 'sanctum')
            ->postJson("/api/v1/expenses/{$expense->id}/invoice", [
                'invoice' => $file,
            ]);

        $response->assertStatus(200);

        $expense->refresh();
        $this->assertTrue($expense->has_invoice);
        $this->assertNotNull($expense->invoice_path);
        
        Storage::disk('local')->assertExists($expense->invoice_path);
    }

    public function test_small_image_is_not_compressed(): void
    {
        $user = User::factory()->create();
        $expense = Expense::factory()->create(['user_id' => $user->id]);
        
        // Create a small image (800x600)
        $file = UploadedFile::fake()->image('small-invoice.jpg', 800, 600)->size(500);

        $response = $this->actingAs($user, 'sanctum')
            ->postJson("/api/v1/expenses/{$expense->id}/invoice", [
                'invoice' => $file,
            ]);

        $response->assertStatus(200);

        $expense->refresh();
        Storage::disk('local')->assertExists($expense->invoice_path);
    }

    public function test_pdf_files_are_not_compressed(): void
    {
        $user = User::factory()->create();
        $expense = Expense::factory()->create(['user_id' => $user->id]);
        
        $file = UploadedFile::fake()->create('invoice.pdf', 2000, 'application/pdf');

        $response = $this->actingAs($user, 'sanctum')
            ->postJson("/api/v1/expenses/{$expense->id}/invoice", [
                'invoice' => $file,
            ]);

        $response->assertStatus(200);

        $expense->refresh();
        Storage::disk('local')->assertExists($expense->invoice_path);
    }

    // ========== FILE DOWNLOAD AUTHORIZATION TESTS ==========

    public function test_user_can_download_their_own_expense_invoice(): void
    {
        $user = User::factory()->create();
        $expense = Expense::factory()->create([
            'user_id' => $user->id,
            'has_invoice' => true,
            'invoice_path' => 'invoices/test-invoice.jpg',
        ]);

        Storage::put('invoices/test-invoice.jpg', 'fake invoice content');

        $response = $this->actingAs($user, 'sanctum')
            ->getJson("/api/v1/expenses/{$expense->id}/invoice");

        $response->assertStatus(200);
        $response->assertHeader('Content-Type', 'image/jpeg');
    }

    public function test_user_cannot_download_other_users_expense_invoice(): void
    {
        $user = User::factory()->create();
        $otherUser = User::factory()->create();
        $expense = Expense::factory()->create([
            'user_id' => $otherUser->id,
            'has_invoice' => true,
            'invoice_path' => 'invoices/other-invoice.jpg',
        ]);

        Storage::put('invoices/other-invoice.jpg', 'fake invoice content');

        $response = $this->actingAs($user, 'sanctum')
            ->getJson("/api/v1/expenses/{$expense->id}/invoice");

        $response->assertStatus(403)
            ->assertJson([
                'success' => false,
                'message' => 'Unauthorized to download invoice for this expense',
            ]);
    }

    public function test_admin_can_download_any_expense_invoice(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $user = User::factory()->create();
        $expense = Expense::factory()->create([
            'user_id' => $user->id,
            'has_invoice' => true,
            'invoice_path' => 'invoices/user-invoice.jpg',
        ]);

        Storage::put('invoices/user-invoice.jpg', 'fake invoice content');

        $response = $this->actingAs($admin, 'sanctum')
            ->getJson("/api/v1/expenses/{$expense->id}/invoice");

        $response->assertStatus(200);
    }

    public function test_download_returns_404_when_expense_has_no_invoice(): void
    {
        $user = User::factory()->create();
        $expense = Expense::factory()->create([
            'user_id' => $user->id,
            'has_invoice' => false,
            'invoice_path' => null,
        ]);

        $response = $this->actingAs($user, 'sanctum')
            ->getJson("/api/v1/expenses/{$expense->id}/invoice");

        $response->assertStatus(404)
            ->assertJson([
                'success' => false,
                'message' => 'No invoice found for this expense',
            ]);
    }

    public function test_download_returns_404_when_invoice_file_missing(): void
    {
        $user = User::factory()->create();
        $expense = Expense::factory()->create([
            'user_id' => $user->id,
            'has_invoice' => true,
            'invoice_path' => 'invoices/missing-invoice.jpg',
        ]);

        // Don't create the file in storage

        $response = $this->actingAs($user, 'sanctum')
            ->getJson("/api/v1/expenses/{$expense->id}/invoice");

        $response->assertStatus(404)
            ->assertJson([
                'success' => false,
                'message' => 'Invoice file not found',
            ]);
    }

    public function test_unauthenticated_user_cannot_download_invoice(): void
    {
        $user = User::factory()->create();
        $expense = Expense::factory()->create([
            'user_id' => $user->id,
            'has_invoice' => true,
            'invoice_path' => 'invoices/test-invoice.jpg',
        ]);

        Storage::put('invoices/test-invoice.jpg', 'fake invoice content');

        $response = $this->getJson("/api/v1/expenses/{$expense->id}/invoice");

        $response->assertStatus(401);
    }

    // ========== FILE DELETION TESTS ==========

    public function test_user_can_delete_their_own_expense_invoice(): void
    {
        $user = User::factory()->create();
        $expense = Expense::factory()->create([
            'user_id' => $user->id,
            'has_invoice' => true,
            'invoice_path' => 'invoices/test-invoice.jpg',
        ]);

        Storage::put('invoices/test-invoice.jpg', 'fake invoice content');
        Storage::assertExists('invoices/test-invoice.jpg');

        $response = $this->actingAs($user, 'sanctum')
            ->deleteJson("/api/v1/expenses/{$expense->id}/invoice");

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Invoice deleted successfully',
            ]);

        Storage::assertMissing('invoices/test-invoice.jpg');

        $expense->refresh();
        $this->assertFalse($expense->has_invoice);
        $this->assertNull($expense->invoice_path);
    }

    public function test_user_cannot_delete_other_users_expense_invoice(): void
    {
        $user = User::factory()->create();
        $otherUser = User::factory()->create();
        $expense = Expense::factory()->create([
            'user_id' => $otherUser->id,
            'has_invoice' => true,
            'invoice_path' => 'invoices/other-invoice.jpg',
        ]);

        Storage::put('invoices/other-invoice.jpg', 'fake invoice content');

        $response = $this->actingAs($user, 'sanctum')
            ->deleteJson("/api/v1/expenses/{$expense->id}/invoice");

        $response->assertStatus(403)
            ->assertJson([
                'success' => false,
                'message' => 'Unauthorized to delete invoice for this expense',
            ]);

        Storage::assertExists('invoices/other-invoice.jpg');
    }

    public function test_admin_can_delete_any_expense_invoice(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $user = User::factory()->create();
        $expense = Expense::factory()->create([
            'user_id' => $user->id,
            'has_invoice' => true,
            'invoice_path' => 'invoices/user-invoice.jpg',
        ]);

        Storage::put('invoices/user-invoice.jpg', 'fake invoice content');

        $response = $this->actingAs($admin, 'sanctum')
            ->deleteJson("/api/v1/expenses/{$expense->id}/invoice");

        $response->assertStatus(200);
        Storage::assertMissing('invoices/user-invoice.jpg');
    }

    public function test_delete_returns_404_when_expense_has_no_invoice(): void
    {
        $user = User::factory()->create();
        $expense = Expense::factory()->create([
            'user_id' => $user->id,
            'has_invoice' => false,
            'invoice_path' => null,
        ]);

        $response = $this->actingAs($user, 'sanctum')
            ->deleteJson("/api/v1/expenses/{$expense->id}/invoice");

        $response->assertStatus(404)
            ->assertJson([
                'success' => false,
                'message' => 'No invoice found for this expense',
            ]);
    }

    public function test_unauthenticated_user_cannot_delete_invoice(): void
    {
        $user = User::factory()->create();
        $expense = Expense::factory()->create([
            'user_id' => $user->id,
            'has_invoice' => true,
            'invoice_path' => 'invoices/test-invoice.jpg',
        ]);

        Storage::put('invoices/test-invoice.jpg', 'fake invoice content');

        $response = $this->deleteJson("/api/v1/expenses/{$expense->id}/invoice");

        $response->assertStatus(401);
    }

    // ========== INVOICE UPLOAD TESTS ==========

    public function test_user_can_upload_invoice_to_their_expense(): void
    {
        $user = User::factory()->create();
        $expense = Expense::factory()->create([
            'user_id' => $user->id,
            'has_invoice' => false,
        ]);

        $file = UploadedFile::fake()->image('invoice.jpg', 800, 600)->size(1024);

        $response = $this->actingAs($user, 'sanctum')
            ->postJson("/api/v1/expenses/{$expense->id}/invoice", [
                'invoice' => $file,
            ]);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Invoice uploaded successfully',
            ]);

        $expense->refresh();
        $this->assertTrue($expense->has_invoice);
        $this->assertNotNull($expense->invoice_path);
        Storage::disk('local')->assertExists($expense->invoice_path);
    }

    public function test_user_cannot_upload_invoice_to_other_users_expense(): void
    {
        $user = User::factory()->create();
        $otherUser = User::factory()->create();
        $expense = Expense::factory()->create(['user_id' => $otherUser->id]);

        $file = UploadedFile::fake()->image('invoice.jpg');

        $response = $this->actingAs($user, 'sanctum')
            ->postJson("/api/v1/expenses/{$expense->id}/invoice", [
                'invoice' => $file,
            ]);

        $response->assertStatus(403)
            ->assertJson([
                'success' => false,
                'message' => 'Unauthorized to upload invoice for this expense',
            ]);
    }

    public function test_admin_can_upload_invoice_to_any_expense(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $user = User::factory()->create();
        $expense = Expense::factory()->create(['user_id' => $user->id]);

        $file = UploadedFile::fake()->image('invoice.jpg');

        $response = $this->actingAs($admin, 'sanctum')
            ->postJson("/api/v1/expenses/{$expense->id}/invoice", [
                'invoice' => $file,
            ]);

        $response->assertStatus(200);

        $expense->refresh();
        $this->assertTrue($expense->has_invoice);
    }

    public function test_uploading_new_invoice_replaces_existing_invoice(): void
    {
        $user = User::factory()->create();
        $expense = Expense::factory()->create([
            'user_id' => $user->id,
            'has_invoice' => true,
            'invoice_path' => 'invoices/old-invoice.jpg',
        ]);

        Storage::put('invoices/old-invoice.jpg', 'old content');
        Storage::assertExists('invoices/old-invoice.jpg');

        $newFile = UploadedFile::fake()->image('new-invoice.jpg');

        $response = $this->actingAs($user, 'sanctum')
            ->postJson("/api/v1/expenses/{$expense->id}/invoice", [
                'invoice' => $newFile,
            ]);

        $response->assertStatus(200);

        // Old file should be deleted
        Storage::assertMissing('invoices/old-invoice.jpg');

        $expense->refresh();
        $this->assertTrue($expense->has_invoice);
        $this->assertNotEquals('invoices/old-invoice.jpg', $expense->invoice_path);
        Storage::disk('local')->assertExists($expense->invoice_path);
    }

    public function test_invoice_upload_validates_file_type(): void
    {
        $user = User::factory()->create();
        $expense = Expense::factory()->create(['user_id' => $user->id]);

        $file = UploadedFile::fake()->create('document.txt', 100, 'text/plain');

        $response = $this->actingAs($user, 'sanctum')
            ->postJson("/api/v1/expenses/{$expense->id}/invoice", [
                'invoice' => $file,
            ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['invoice']);
    }

    public function test_invoice_upload_validates_file_size(): void
    {
        $user = User::factory()->create();
        $expense = Expense::factory()->create(['user_id' => $user->id]);

        $file = UploadedFile::fake()->image('large.jpg')->size(11000); // 11MB

        $response = $this->actingAs($user, 'sanctum')
            ->postJson("/api/v1/expenses/{$expense->id}/invoice", [
                'invoice' => $file,
            ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['invoice']);
    }

    public function test_invoice_upload_requires_file(): void
    {
        $user = User::factory()->create();
        $expense = Expense::factory()->create(['user_id' => $user->id]);

        $response = $this->actingAs($user, 'sanctum')
            ->postJson("/api/v1/expenses/{$expense->id}/invoice", []);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['invoice']);
    }
}
