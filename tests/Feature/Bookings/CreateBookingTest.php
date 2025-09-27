<?php

namespace Tests\Feature\Bookings;

use Tests\TestCase;
use App\Models\Facility;
use App\Models\Service;
use App\Models\BookingSlot;
use Illuminate\Support\Carbon;

class CreateBookingTest extends TestCase
{
    public function test_create_booking_happy_path(): void
    {
        // Arrange: create minimal facility, service and an upcoming booking slot
        $facility = Facility::create([
            'name' => 'Test Facility',
            'address' => ['line1' => '1 Test Street'],
            'phone' => '555-0000',
        ]);

        $service = Service::create([
            'facility_id' => $facility->id,
            'name' => 'Day Care Test Service',
            'description' => 'Test service',
            'duration_minutes' => 60,
        ]);

        $start = Carbon::now()->addDays(1)->startOfHour();
        $end = (clone $start)->addHours(2);

        $slot = BookingSlot::create([
            'service_id' => $service->id,
            'facility_id' => $facility->id,
            'start_at' => $start,
            'end_at' => $end,
            'capacity' => 4,
            'available_count' => 4,
        ]);

        // Act: submit booking request as guest
        $response = $this->post(route('booking.store'), [
            'slot_id' => $slot->id,
            'email' => 'guest@example.com',
        ]);

        // Assert: redirected back to booking.create and DB contains booking
        $response->assertRedirect(route('booking.create'));

        $this->assertDatabaseHas('bookings', [
            'guest_email' => 'guest@example.com',
            'slot_id' => $slot->id,
        ]);
    }
}
