<?php

namespace App\Notifications;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

class SyncFailureNotification extends Notification
{
    use Queueable;

    /**
     * The number of retry attempts.
     *
     * @var int
     */
    protected int $retryCount;

    /**
     * Create a new notification instance.
     */
    public function __construct(int $retryCount)
    {
        $this->retryCount = $retryCount;
    }

    /**
     * Get the notification's delivery channels.
     *
     * @return array<int, string>
     */
    public function via(object $notifiable): array
    {
        return ['mail'];
    }

    /**
     * Get the mail representation of the notification.
     */
    public function toMail(object $notifiable): MailMessage
    {
        return (new MailMessage)
            ->subject('Sync Failure Alert')
            ->markdown('emails.sync-failure', [
                'user' => $notifiable,
                'retryCount' => $this->retryCount,
            ]);
    }

    /**
     * Get the array representation of the notification.
     *
     * @return array<string, mixed>
     */
    public function toArray(object $notifiable): array
    {
        return [
            'retry_count' => $this->retryCount,
        ];
    }
}
