<?php

namespace Tests\Feature\Notifications;

use App\Jobs\Notifications\SendReminderJob;
use App\Models\Booking;
use App\Models\BookingNotification;
use App\Models\BookingSlot;
use App\Models\CaregiverProfile;
use App\Models\Client;
use App\Models\Facility;
use App\Models\Service;
use App\Models\User;
use App\Notifications\BookingReminderNotification;
use App\Support\Metrics\NotificationMetrics;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Notification;
use Illuminate\Support\Str;
use Tests\TestCase;

class ReminderTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        config([
            'metrics.store' => 'array',
            'notifications.reminders.quiet_hours.start' => '00:00',
            'notifications.reminders.quiet_hours.end' => '00:00',
        ]);

        Notification::fake();
    }

    protected function tearDown(): void
    {
        app(NotificationMetrics::class)->snapshot();

        parent::tearDown();
    }

    public function test_send_reminder_marks_notification_sent(): void
    {
        [$user, $profile, $booking] = $this->createCaregiverBooking();

        $log = BookingNotification::create([
            'booking_id' => $booking->id,
            'caregiver_profile_id' => $profile->id,
            'channel' => 'email',
            'status' => BookingNotification::STATUS_PENDING,
            'scheduled_for' => now()->addHours(2),
        ]);

        $job = new SendReminderJob($log->id);
        $job->handle(app(NotificationMetrics::class));

        $log->refresh();

        $this->assertSame(BookingNotification::STATUS_SENT, $log->status);
        Notification::assertSentTo(
            $user,
            BookingReminderNotification::class,
            fn (BookingReminderNotification $notification) => true
        );
    }

    private function createCaregiverBooking(): array
    {
        $user = User::create([
            'full_name' => 'Jordan Lee',
            'email' => 'caregiver@example.com',
            'password_hash' => Hash::make('secret123'),
            'role' => 'caregiver',
            'is_active' => true,
        ]);

        $client = Client::create([
            'first_name' => 'Avery',
            'last_name' => 'Williams',
            'email' => 'avery@example.com',
            'phone' => '+1-415-555-0100',
            'language_preference' => 'en',
        ]);

        $profile = CaregiverProfile::create([
            'user_id' => $user->id,
            'client_id' => $client->id,
            'preferred_contact_method' => 'email',
            'timezone' => 'UTC',
            'sms_opt_in' => true,
            'preferences' => ['reminder_window_hours' => 24],
        ]);

        $facility = Facility::create([
            'name' => 'Downtown Center',
            'address' => ['street' => '123 Market St', 'city' => 'San Francisco'],
            'phone' => '+1-415-555-0100',
        ]);

        $service = Service::create([
            'facility_id' => $facility->id,
            'name' => 'Day Program',
            'description' => 'Day-long engagement program.',
            'duration_minutes' => 180,
        ]);

        $start = Carbon::now()->addDays(1)->setTime(10, 0);
        $end = (clone $start)->addHours(3);

        $slot = BookingSlot::create([
            'service_id' => $service->id,
            'facility_id' => $facility->id,
            'start_at' => $start,
            'end_at' => $end,
            'capacity' => 5,
            'available_count' => 5,
            'lock_version' => 1,
        ]);

        $booking = Booking::create([
            'slot_id' => $slot->id,
            'client_id' => $client->id,
            'status' => 'confirmed',
            'uuid' => (string) Str::uuid(),
        ]);

        return [$user, $profile, $booking];
    }
}
