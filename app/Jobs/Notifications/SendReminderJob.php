<?php

namespace App\Jobs\Notifications;

use App\Jobs\Notifications\SendReminderJob;
use App\Models\Booking;
use App\Models\BookingNotification;
use App\Notifications\BookingReminderNotification;
use App\Support\Metrics\NotificationMetrics;
use Carbon\Carbon;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Arr;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Notification;
use Throwable;

class SendReminderJob implements ShouldQueue
{
    use Dispatchable;
    use InteractsWithQueue;
    use Queueable;
    use SerializesModels;

    public int $tries;

    protected array $backoffSchedule;

    public function __construct(public readonly int $bookingNotificationId)
    {
        $this->tries = (int) config('notifications.reminders.max_attempts', 3);
        $this->backoffSchedule = array_map('intval', explode(',', (string) config('notifications.reminders.retry_backoff_seconds', '60,300,900')));
        $this->onQueue(config('notifications.queues.notifications', 'notifications'));
    }

    public function backoff(): array
    {
        return $this->backoffSchedule;
    }

    public function handle(NotificationMetrics $metrics): void
    {
        $log = BookingNotification::with(['booking.slot.service', 'booking.slot.facility', 'caregiverProfile.user'])
            ->find($this->bookingNotificationId);

        if (! $log) {
            Log::warning('Booking notification log missing.', ['id' => $this->bookingNotificationId]);
            return;
        }

        if ($log->status !== BookingNotification::STATUS_PENDING) {
            return;
        }

        $profile = $log->caregiverProfile;
        $booking = $log->booking;

        if (! $profile || ! $booking) {
            $log->markFailed('missing_profile_or_booking');
            $metrics->recordFailed($log->channel);

            return;
        }

        $user = $profile->user;
        $timezone = $profile->timezone ?? config('app.timezone', 'UTC');
        $channel = $log->channel;

        if ($this->isInQuietHours($timezone)) {
            $log->markSkipped('quiet_hours');
            $metrics->recordSkipped($channel);

            return;
        }

        if ($channel === 'sms' && (! $profile->sms_opt_in || empty($user?->phone))) {
            $log->markSkipped('sms_opt_out');
            $metrics->recordSkipped($channel);

            return;
        }

        if ($channel === 'email' && empty($user?->email)) {
            $log->markSkipped('missing_email');
            $metrics->recordSkipped($channel);

            return;
        }

        $reminderWindow = (int) data_get($profile->preferences, 'reminder_window_hours', config('notifications.reminders.default_window_hours', 24));

        if (config('notifications.feature_flags.simulate_delivery', false)) {
            $log->markSent(['simulated' => true]);
            $metrics->recordSent($channel);

            return;
        }

        try {
            Notification::send(
                $user,
                new BookingReminderNotification($booking, $channel, $timezone, $reminderWindow, $log)
            );

            $log->markSent();
            $metrics->recordSent($channel);
        } catch (Throwable $exception) {
            $log->markFailed('exception', ['message' => $exception->getMessage()]);
            $metrics->recordFailed($channel);

            Log::error('Failed to send booking reminder.', [
                'booking_notification_id' => $log->id,
                'channel' => $channel,
                'exception' => $exception,
            ]);

            throw $exception;
        }
    }

    protected function isInQuietHours(string $timezone): bool
    {
        $quietStart = config('notifications.reminders.quiet_hours.start', '21:00');
        $quietEnd = config('notifications.reminders.quiet_hours.end', '08:00');

        $now = Carbon::now($timezone);
        $start = Carbon::createFromFormat('H:i', $quietStart, $timezone);
        $end = Carbon::createFromFormat('H:i', $quietEnd, $timezone);

        if ($start->equalTo($end)) {
            return false;
        }

        if ($start->lessThan($end)) {
            return $now->betweenIncluded($start, $end);
        }

        return $now->greaterThanOrEqualTo($start) || $now->lessThanOrEqualTo($end);
    }
}
