<?php

namespace Tests\Feature\Admin;

use App\Models\Booking;
use App\Models\BookingNotification;
use App\Models\BookingSlot;
use App\Models\CaregiverProfile;
use App\Models\Client;
use App\Models\Facility;
use App\Models\MediaItem;
use App\Models\Payment;
use App\Models\Service;
use App\Models\User;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;
use Tests\TestCase;

class AnalyticsDashboardTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        config(['metrics.store' => 'array']);
    }

    public function test_admin_can_view_analytics_dashboard(): void
    {
        $admin = User::create([
            'full_name' => 'Admin User',
            'email' => 'admin@example.com',
            'password_hash' => Hash::make('secret123'),
            'role' => 'admin',
            'is_active' => true,
        ]);

        $this->seedAnalyticsData();

        $response = $this->actingAs($admin)->get(route('admin.analytics'));

        $response->assertOk();
        $response->assertViewIs('admin.analytics');
        $response->assertViewHas('bookingsByStatus', function ($data) {
            return ($data['confirmed'] ?? 0) === 3;
        });
        $response->assertViewHas('paymentStats', function ($stats) {
            return $stats['succeeded'] === 2 && $stats['failed'] === 1;
        });
    }

    public function test_non_admin_cannot_view_dashboard(): void
    {
        $user = User::create([
            'full_name' => 'Caregiver',
            'email' => 'caregiver@example.com',
            'password_hash' => Hash::make('secret123'),
            'role' => 'caregiver',
            'is_active' => true,
        ]);

        $response = $this->actingAs($user)->get(route('admin.analytics'));

        $response->assertForbidden();
    }

    protected function seedAnalyticsData(): void
    {
        $facility = Facility::create([
            'name' => 'Downtown Center',
            'address' => ['street' => '123 Market St', 'city' => 'SF'],
            'phone' => '+1-415-555-0100',
        ]);

        $service = Service::create([
            'facility_id' => $facility->id,
            'name' => 'Day Program',
            'description' => 'Full-day engagement.',
            'duration_minutes' => 180,
        ]);

        $client = Client::create([
            'first_name' => 'Avery',
            'last_name' => 'Williams',
            'email' => 'avery@example.com',
            'phone' => '+1-415-555-0100',
            'language_preference' => 'en',
        ]);

        $bookingSpecs = [
            ['status' => 'pending', 'offsetDays' => 5],
            ['status' => 'confirmed', 'offsetDays' => 4],
            ['status' => 'confirmed', 'offsetDays' => 3],
            ['status' => 'confirmed', 'offsetDays' => 2],
        ];

        $confirmedBookings = [];

        foreach ($bookingSpecs as $spec) {
            $startAt = Carbon::now()->subDays($spec['offsetDays'])->setTime(10, 0);
            $endAt = (clone $startAt)->addHours(3);

            $slot = BookingSlot::create([
                'service_id' => $service->id,
                'facility_id' => $facility->id,
                'start_at' => $startAt,
                'end_at' => $endAt,
                'capacity' => 5,
                'available_count' => 4,
                'lock_version' => 1,
            ]);

            $booking = Booking::create([
                'slot_id' => $slot->id,
                'client_id' => $client->id,
                'status' => $spec['status'],
                'uuid' => (string) Str::uuid(),
                'created_at' => $startAt->copy(),
                'updated_at' => $startAt->copy(),
            ]);

            if ($spec['status'] === 'confirmed') {
                $confirmedBookings[] = $booking;
            }
        }

        if (count($confirmedBookings) >= 3) {
            Payment::create([
                'booking_id' => $confirmedBookings[0]->id,
                'stripe_payment_intent_id' => 'pi_1',
                'status' => Payment::STATUS_SUCCEEDED,
                'amount_cents' => 5000,
                'currency' => 'usd',
                'created_at' => now()->subDays(2),
            ]);

            Payment::create([
                'booking_id' => $confirmedBookings[1]->id,
                'stripe_payment_intent_id' => 'pi_2',
                'status' => Payment::STATUS_SUCCEEDED,
                'amount_cents' => 5000,
                'currency' => 'usd',
                'created_at' => now()->subDay(),
            ]);

            Payment::create([
                'booking_id' => $confirmedBookings[2]->id,
                'stripe_payment_intent_id' => 'pi_3',
                'status' => Payment::STATUS_CANCELLED,
                'amount_cents' => 5000,
                'currency' => 'usd',
                'created_at' => now()->subDay(),
            ]);

            BookingNotification::create([
                'booking_id' => $confirmedBookings[0]->id,
                'caregiver_profile_id' => CaregiverProfile::factory()->create()->id,
                'channel' => 'email',
                'status' => BookingNotification::STATUS_SENT,
                'scheduled_for' => now()->subHours(2),
            ]);

            BookingNotification::create([
                'booking_id' => $confirmedBookings[1]->id,
                'caregiver_profile_id' => CaregiverProfile::factory()->create()->id,
                'channel' => 'email',
                'status' => BookingNotification::STATUS_FAILED,
                'scheduled_for' => now()->subHours(1),
            ]);
        }

        if (class_exists(MediaItem::class)) {
            MediaItem::create([
                'title' => 'Lobby Tour',
                'file_path' => 'media/lobby.mp4',
                'mime_type' => 'video/mp4',
                'category' => 'virtual_tour',
            ]);
        }
    }
}
