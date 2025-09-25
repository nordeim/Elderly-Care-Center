<?php

namespace App\Notifications;

use App\Models\Booking;
use App\Models\BookingNotification;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Messages\VonageMessage;
use Illuminate\Notifications\Notification;

class BookingReminderNotification extends Notification implements ShouldQueue
{
    use Queueable;

    protected string $viaChannel;
    protected string $channelKey;

    public function __construct(
        Booking $booking,
        string $channelKey,
        string $timezone,
        ?int $reminderWindowHours = null,
        ?BookingNotification $log = null
    ) {
        $this->booking = $booking;
        $this->channelKey = $channelKey;
        $this->timezone = $timezone;
        $this->reminderWindowHours = $reminderWindowHours;
        $this->log = $log;
        $this->viaChannel = $channelKey === 'sms'
            ? config('notifications.channels.sms.driver', 'vonage')
            : config('notifications.channels.email.driver', 'mail');

        $this->onQueue('notifications');
    }

    public function via(object $notifiable): array
    {
        return [$this->viaChannel];
    }

    public function toMail(object $notifiable): MailMessage
    {
        $slot = $this->booking->slot;
        $service = optional($slot)->service;
        $facility = optional($slot)->facility;

        return (new MailMessage())
            ->subject(__('Reminder: Upcoming Visit on :date', [
                'date' => optional($slot)->start_at?->timezone($this->timezone)->format('M d, Y h:i A'),
            ]))
            ->markdown('emails.reminder', [
                'booking' => $this->booking,
                'slot' => $slot,
                'service' => $service,
                'facility' => $facility,
                'timezone' => $this->timezone,
                'reminderWindowHours' => $this->reminderWindowHours,
            ]);
    }

    public function toVonage(object $notifiable): VonageMessage
    {
        $slot = $this->booking->slot;
        $start = optional($slot)->start_at?->timezone($this->timezone)->format('M d, Y h:i A');
        $service = optional($slot)->service?->name ?? __('Your visit');

        $message = __('Reminder: :service on :date. Reply HELP for assistance.', [
            'service' => $service,
            'date' => $start,
        ]);

        return (new VonageMessage())
            ->content($message)
            ->unicode();
    }

    public function toArray(object $notifiable): array
    {
        return [
            'booking_id' => $this->booking->id,
            'timezone' => $this->timezone,
            'reminder_window_hours' => $this->reminderWindowHours,
            'channel' => $this->channelKey,
            'notification_log_id' => $this->log?->id,
        ];
    }
}
