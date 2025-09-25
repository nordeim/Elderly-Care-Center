<?php

namespace App\Http\Controllers\Caregiver;

use App\Http\Controllers\Controller;
use App\Models\Booking;
use App\Models\CaregiverProfile;
use Illuminate\Contracts\Auth\Authenticatable;
use Illuminate\Contracts\Support\Renderable;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Arr;
use Illuminate\Support\Facades\Gate;
use Illuminate\Support\Facades\Redirect;
use Illuminate\Support\Collection;

class DashboardController extends Controller
{
    public function __construct()
    {
        $this->middleware(['auth']);
    }

    public function index(Request $request): Renderable
    {
        Gate::authorize('access-caregiver');

        $profile = $this->resolveProfile($request->user());

        $bookings = $this->loadBookings($profile);

        $now = now();
        $upcoming = $bookings->filter(function (Booking $booking) use ($now) {
            $start = optional($booking->slot)->start_at;

            return $start && $start->greaterThanOrEqualTo($now);
        })->sortBy(fn (Booking $booking) => optional($booking->slot)->start_at);

        $past = $bookings->filter(function (Booking $booking) use ($now) {
            $start = optional($booking->slot)->start_at;

            return $start && $start->lessThan($now);
        })->sortByDesc(fn (Booking $booking) => optional($booking->slot)->start_at);

        $profile->fill(['last_login_at' => $now])->save();

        return view('caregiver.dashboard', [
            'profile' => $profile,
            'upcomingBookings' => $upcoming,
            'pastBookings' => $past,
            'preferences' => $profile->preferences ?? [],
            'timezone' => $profile->timezone,
        ]);
    }

    public function updatePreferences(Request $request): RedirectResponse
    {
        Gate::authorize('access-caregiver');

        $profile = $this->resolveProfile($request->user());

        $data = $request->validate([
            'preferred_contact_method' => 'required|in:email,sms',
            'timezone' => 'required|string|max:64',
            'sms_opt_in' => 'sometimes|boolean',
            'reminder_window_hours' => 'nullable|integer|min:1|max:168',
        ]);

        $profile->preferred_contact_method = $data['preferred_contact_method'];
        $profile->timezone = $data['timezone'];
        $profile->sms_opt_in = Arr::get($data, 'sms_opt_in', false);
        $profile->preferences = array_merge($profile->preferences ?? [], [
            'reminder_window_hours' => Arr::get($data, 'reminder_window_hours', 24),
        ]);
        $profile->save();

        return Redirect::back()->with('status', __('Your preferences have been updated.'));
    }

    protected function resolveProfile(?Authenticatable $user): CaregiverProfile
    {
        $profile = optional($user)->caregiverProfile;

        if (! $profile) {
            abort(403, 'Caregiver profile not found.');
        }

        return $profile;
    }

    protected function loadBookings(CaregiverProfile $profile): Collection
    {
        if (! $profile->client_id) {
            return collect();
        }

        return Booking::query()
            ->with(['slot.service', 'slot.facility'])
            ->where('client_id', $profile->client_id)
            ->get();
    }
}
