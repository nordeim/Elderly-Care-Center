<?php

namespace App\Actions\Bookings;

use App\Models\Booking;
use App\Models\BookingSlot;
use App\Models\BookingStatusHistory;
use App\Models\Client;
use Illuminate\Database\DatabaseManager;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use RuntimeException;

class CreateBookingAction
{
    public function __construct(private readonly DatabaseManager $db)
    {
    }

    public function execute(array $payload): Booking
    {
        return $this->db->transaction(function () use ($payload) {
            $client = $this->resolveClient($payload);

            if ($this->db->getDriverName() === 'mysql') {
                $bookingId = DB::statement('CALL sp_create_booking(?, ?, ?, ?, @booking_id)', [
                    $payload['slot_id'],
                    $client?->id,
                    $client ? null : $payload['email'],
                    auth()->id(),
                ]);

                $id = DB::selectOne('SELECT @booking_id as id');

                if (! $id || ! $id->id) {
                    throw new RuntimeException('Slot is no longer available.');
                }

                $booking = Booking::findOrFail($id->id);
                $booking->metadata = [
                    'notes' => $payload['notes'] ?? null,
                    'caregiver_name' => $payload['caregiver_name'] ?? null,
                ];
                $booking->save();

                return $booking;
            }

            /** @var BookingSlot $slot */
            $slot = BookingSlot::query()->lockForUpdate()->findOrFail($payload['slot_id']);

            if ($slot->available_count <= 0) {
                throw new RuntimeException('Selected slot is no longer available.');
            }

            $booking = Booking::create([
                'slot_id' => $slot->id,
                'client_id' => $client?->id,
                'guest_email' => $client ? null : $payload['email'],
                'status' => 'pending',
                'created_via' => 'web',
                'uuid' => (string) Str::uuid(),
                'metadata' => [
                    'notes' => $payload['notes'] ?? null,
                    'caregiver_name' => $payload['caregiver_name'] ?? null,
                ],
            ]);

            BookingStatusHistory::create([
                'booking_id' => $booking->id,
                'from_status' => null,
                'to_status' => 'pending',
                'changed_by' => null,
            ]);

            $slot->decrement('available_count');

            return $booking;
        });
    }

    private function resolveClient(array $payload): ?Client
    {
        if (empty($payload['client'])) {
            return null;
        }

        return Client::updateOrCreate(
            ['email' => $payload['client']['email'] ?? null],
            [
                'first_name' => $payload['client']['first_name'] ?? null,
                'last_name' => $payload['client']['last_name'] ?? null,
                'phone' => $payload['client']['phone'] ?? null,
                'language_preference' => $payload['client']['language_preference'] ?? 'en',
                'consent_version' => $payload['client']['consent_version'] ?? null,
            ]
        );
    }
}
