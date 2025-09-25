<?php

namespace App\Http\Controllers\Calendar;

use App\Http\Controllers\Controller;
use App\Models\AuditLog;
use App\Models\CaregiverProfile;
use App\Services\Calendar\ICalGenerator;
use Illuminate\Contracts\Auth\Authenticatable;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;
use Illuminate\Support\Facades\Response as ResponseFactory;
use Illuminate\Support\Facades\URL;

class BookingExportController extends Controller
{
    public function __invoke(Request $request, ICalGenerator $generator)
    {
        Gate::authorize('access-caregiver');

        $profile = $this->resolveProfile($request->user());
        $bookings = $profile->client
            ? $profile->client->bookings()->with(['slot.service', 'slot.facility'])->get()
            : collect();

        if ($request->boolean('download')) {
            $ics = $generator->generate($profile, $bookings);

            AuditLog::record(
                'calendar_export.download',
                $request->user(),
                $profile->client,
                ['booking_count' => $bookings->count()],
                $request->ip()
            );

            return ResponseFactory::make($ics, 200, [
                'Content-Type' => 'text/calendar; charset=utf-8',
                'Content-Disposition' => 'attachment; filename="elderly-daycare-bookings.ics"',
            ]);
        }

        AuditLog::record(
            'calendar_export.view',
            $request->user(),
            $profile->client,
            ['booking_count' => $bookings->count()],
            $request->ip()
        );

        return view('calendar.booking-export', [
            'profile' => $profile,
            'bookings' => $bookings,
            'downloadUrl' => URL::route('caregiver.calendar.export', ['download' => 1]),
        ]);
    }

    protected function resolveProfile(?Authenticatable $user): CaregiverProfile
    {
        $profile = optional($user)->caregiverProfile;

        if (! $profile) {
            abort(403, 'Caregiver profile not found.');
        }

        return $profile;
    }
}
