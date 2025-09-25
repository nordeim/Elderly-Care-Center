<?php

namespace App\Http\Controllers\Site;

use App\Actions\Bookings\CreateBookingAction;
use App\Http\Controllers\Controller;
use App\Http\Requests\BookingRequest;
use App\Models\BookingSlot;
use Illuminate\Http\RedirectResponse;
use Illuminate\View\View;
use RuntimeException;

class BookingController extends Controller
{
    public function __construct(private readonly CreateBookingAction $createBooking)
    {
    }

    public function create(): View
    {
        $slots = BookingSlot::with(['service.facility'])
            ->upcoming()
            ->limit(20)
            ->get();

        return view('pages.book', compact('slots'));
    }

    public function store(BookingRequest $request): RedirectResponse
    {
        try {
            $booking = $this->createBooking->execute($request->validated());
        } catch (RuntimeException $exception) {
            return redirect()->back()
                ->withErrors(['slot_id' => $exception->getMessage()])
                ->withInput();
        }

        return redirect()->route('booking.create')
            ->with('status', 'Booking request submitted successfully. Reference ID: '.$booking->uuid);
    }
}
