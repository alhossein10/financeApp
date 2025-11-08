<?php

namespace Tests\Feature;

use App\Models\User;
use App\Notifications\WelcomeNotification;
use App\Notifications\DataModificationNotification;
use App\Notifications\SyncFailureNotification;
use App\Notifications\ResetPasswordNotification;
use App\Services\NotificationService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Notification;
use Tests\TestCase;

class NotificationTest extends TestCase
{
    use RefreshDatabase;

    protected NotificationService $notificationService;

    protected function setUp(): void
    {
        parent::setUp();
        $this->notificationService = app(NotificationService::class);
    }

    /**
     * Test welcome email is sent on user registration.
     * Requirement 14.1: Welcome email with account verification link
     */
    public function test_welcome_email_sent_on_registration(): void
    {
        Notification::fake();

        $user = User::factory()->create();

        $this->notificationService->sendWelcomeEmail($user);

        Notification::assertSentTo($user, WelcomeNotification::class);
    }

    /**
     * Test welcome email contains correct content.
     * Requirement 14.1: Welcome email with account verification link
     */
    public function test_welcome_email_contains_correct_content(): void
    {
        $user = User::factory()->create([
            'name' => 'John Doe',
            'email' => 'john@example.com',
        ]);

        $notification = new WelcomeNotification();
        $mailMessage = $notification->toMail($user);

        $this->assertEquals('Welcome to Finance Management System', $mailMessage->subject);
        $this->assertEquals('emails.welcome', $mailMessage->markdown);
    }

    /**
     * Test password reset email is sent with token.
     * Requirement 14.2: Password reset email with secure token
     */
    public function test_password_reset_email_sent_with_token(): void
    {
        Notification::fake();

        $user = User::factory()->create();
        $token = 'test-reset-token-123';

        $user->sendPasswordResetNotification($token);

        Notification::assertSentTo($user, ResetPasswordNotification::class, function ($notification) use ($token) {
            $mailMessage = $notification->toMail($user = User::factory()->make());
            return str_contains($mailMessage->actionUrl, $token);
        });
    }

    /**
     * Test password reset email contains correct recipient.
     * Requirement 14.2: Password reset email with secure token
     */
    public function test_password_reset_email_sent_to_correct_recipient(): void
    {
        Notification::fake();

        $user = User::factory()->create(['email' => 'user@example.com']);
        $token = 'reset-token';

        $user->sendPasswordResetNotification($token);

        Notification::assertSentTo($user, ResetPasswordNotification::class);
    }

    /**
     * Test data modification alert is sent when admin modifies user data.
     * Requirement 14.3: Notification when admin creates/modifies data
     */
    public function test_data_modification_alert_sent_to_user(): void
    {
        Notification::fake();

        $user = User::factory()->create();

        $this->notificationService->sendDataModificationAlert($user, 'update', 'Expense');

        Notification::assertSentTo($user, DataModificationNotification::class);
    }

    /**
     * Test data modification alert contains correct action and resource.
     * Requirement 14.3: Notification when admin creates/modifies data
     */
    public function test_data_modification_alert_contains_correct_details(): void
    {
        $user = User::factory()->create();
        $action = 'create';
        $resource = 'Transfer';

        $notification = new DataModificationNotification($action, $resource);
        $mailMessage = $notification->toMail($user);

        $this->assertEquals('Data Modification Alert', $mailMessage->subject);
        $this->assertEquals('emails.data-modification', $mailMessage->markdown);
        
        $array = $notification->toArray($user);
        $this->assertEquals($action, $array['action']);
        $this->assertEquals($resource, $array['resource']);
    }

    /**
     * Test sync failure alert is sent after multiple failures.
     * Requirement 14.4: Alert when sync fails repeatedly (more than 3 times)
     */
    public function test_sync_failure_alert_sent_after_multiple_failures(): void
    {
        Notification::fake();

        $user = User::factory()->create();
        $retryCount = 4;

        $this->notificationService->sendSyncFailureAlert($user, $retryCount);

        Notification::assertSentTo($user, SyncFailureNotification::class);
    }

    /**
     * Test sync failure alert contains retry count.
     * Requirement 14.4: Alert when sync fails repeatedly
     */
    public function test_sync_failure_alert_contains_retry_count(): void
    {
        $user = User::factory()->create();
        $retryCount = 5;

        $notification = new SyncFailureNotification($retryCount);
        $mailMessage = $notification->toMail($user);

        $this->assertEquals('Sync Failure Alert', $mailMessage->subject);
        $this->assertEquals('emails.sync-failure', $mailMessage->markdown);
        
        $array = $notification->toArray($user);
        $this->assertEquals($retryCount, $array['retry_count']);
    }

    /**
     * Test multiple notifications can be sent to same user.
     */
    public function test_multiple_notifications_sent_to_same_user(): void
    {
        Notification::fake();

        $user = User::factory()->create();

        $this->notificationService->sendWelcomeEmail($user);
        $this->notificationService->sendDataModificationAlert($user, 'delete', 'Incoming');
        $this->notificationService->sendSyncFailureAlert($user, 3);

        Notification::assertSentTo($user, WelcomeNotification::class);
        Notification::assertSentTo($user, DataModificationNotification::class);
        Notification::assertSentTo($user, SyncFailureNotification::class);
        Notification::assertCount(3);
    }

    /**
     * Test notification is sent to correct user among multiple users.
     */
    public function test_notification_sent_to_correct_user(): void
    {
        Notification::fake();

        $user1 = User::factory()->create();
        $user2 = User::factory()->create();

        $this->notificationService->sendWelcomeEmail($user1);

        Notification::assertSentTo($user1, WelcomeNotification::class);
        Notification::assertNotSentTo($user2, WelcomeNotification::class);
    }
}
