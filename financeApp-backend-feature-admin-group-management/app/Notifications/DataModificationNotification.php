<?php

namespace App\Notifications;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

class DataModificationNotification extends Notification
{
    use Queueable;

    /**
     * The action performed (create, update, delete).
     *
     * @var string
     */
    protected string $action;

    /**
     * The resource type modified.
     *
     * @var string
     */
    protected string $resource;

    /**
     * Create a new notification instance.
     */
    public function __construct(string $action, string $resource)
    {
        $this->action = $action;
        $this->resource = $resource;
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
            ->subject('Data Modification Alert')
            ->markdown('emails.data-modification', [
                'user' => $notifiable,
                'action' => $this->action,
                'resource' => $this->resource,
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
            'action' => $this->action,
            'resource' => $this->resource,
        ];
    }
}
