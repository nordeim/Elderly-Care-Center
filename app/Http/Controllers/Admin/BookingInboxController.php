<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\Admin\BookingStatusRequest;
use App\Models\Booking;
use App\Models\BookingStatusHistory;
use App\Support\Metrics\BookingMetrics;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\View\View;

class BookingInboxController extends Controller
{
    public function __construct(private readonly BookingMetrics $metrics)
    {
    }

    public function index(Request $request): View
    {
        $status = $request->query('status');

        $query = Booking::query()
            ->with(['client', 'slot.service.facility'])
            ->latest();

        if ($status) {
            $query->where('status', $status);
        }

        $bookings = $query->paginate(20)->withQueryString();

        $statusCounts = Booking::selectRaw('status, COUNT(*) as total')
            ->groupBy('status')
            ->pluck('total', 'status');

        return view('admin.bookings.index', [
            'bookings' => $bookings,
            'statusCounts' => $statusCounts,
            'currentStatus' => $status,
            'availableStatuses' => $this->availableStatuses(),
        ]);
    }

    public function updateStatus(BookingStatusRequest $request, Booking $booking): RedirectResponse
    {
        $fromStatus = $booking->status;
        $toStatus = $request->validated()['status'];

        if ($fromStatus === $toStatus) {
            return back()->with('status', 'Booking already in the selected status.');
        }

        $booking->update([
            'status' => $toStatus,
            'cancelled_at' => $toStatus === 'cancelled' ? now() : $booking->cancelled_at,
        ]);

        BookingStatusHistory::create([
            'booking_id' => $booking->id,
            'from_status' => $fromStatus,
            'to_status' => $toStatus,
            'changed_by' => $request->user()->id,
            'changed_at' => now(),
        ]);

        $this->metrics->recordStatusChange($fromStatus, $toStatus);

        return back()->with('status', 'Booking status updated.');
    }

    private function availableStatuses(): array
    {
        return [
            'pending',
            'confirmed',
            'attended',
            'cancelled',
            'no_show',
            'archived',
        ];
    }
}
