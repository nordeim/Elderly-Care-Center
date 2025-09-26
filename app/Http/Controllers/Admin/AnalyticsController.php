<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Booking;
use App\Models\BookingNotification;
use App\Models\MediaItem;
use App\Models\Payment;
use Carbon\CarbonImmutable;
use Illuminate\Contracts\View\View;
use Illuminate\Http\Request;
use Illuminate\Support\Arr;
use Illuminate\Support\Facades\Gate;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;

class AnalyticsController extends Controller
{
    public function __invoke(Request $request): View
    {
        Gate::authorize('access-admin');

        [$start, $end] = $this->resolveRange($request);

        $bookingsByStatus = $this->bookingsByStatus($start, $end);
        $funnel = $this->bookingFunnel($bookingsByStatus);
        $trend = $this->bookingTrend($start, $end);
        $paymentStats = $this->paymentStats($start, $end);
        $mediaStats = $this->mediaStats($start, $end);
        $notificationStats = $this->notificationStats($start, $end);

        return view('admin.analytics', [
            'filters' => [
                'start' => $start->toDateString(),
                'end' => $end->toDateString(),
            ],
            'bookingsByStatus' => $bookingsByStatus,
            'funnel' => $funnel,
            'trend' => $trend,
            'paymentStats' => $paymentStats,
            'mediaStats' => $mediaStats,
            'notificationStats' => $notificationStats,
        ]);
    }

    protected function resolveRange(Request $request): array
    {
        $end = CarbonImmutable::parse($request->query('end', now()->toDateString()))->endOfDay();
        $start = CarbonImmutable::parse($request->query('start', $end->subDays(29)->toDateString()))->startOfDay();

        if ($start->greaterThan($end)) {
            [$start, $end] = [$end->subDays(29)->startOfDay(), $end];
        }

        return [$start, $end];
    }

    protected function bookingsByStatus(CarbonImmutable $start, CarbonImmutable $end): array
    {
        return Booking::query()
            ->selectRaw('status, COUNT(*) as aggregate')
            ->whereBetween('created_at', [$start, $end])
            ->groupBy('status')
            ->pluck('aggregate', 'status')
            ->toArray();
    }

    protected function bookingFunnel(array $bookingsByStatus): array
    {
        $requested = array_sum($bookingsByStatus);
        $confirmed = $bookingsByStatus['confirmed'] ?? 0;
        $attended = $bookingsByStatus['attended'] ?? 0;
        $cancelled = $bookingsByStatus['cancelled'] ?? 0;

        return [
            'requested' => $requested,
            'confirmed' => $confirmed,
            'attended' => $attended,
            'cancelled' => $cancelled,
            'conversion_rate' => $requested > 0 ? round(($confirmed / $requested) * 100, 1) : 0,
            'attendance_rate' => $confirmed > 0 ? round(($attended / $confirmed) * 100, 1) : 0,
        ];
    }

    protected function bookingTrend(CarbonImmutable $start, CarbonImmutable $end): array
    {
        return Booking::query()
            ->selectRaw('DATE(created_at) as date, COUNT(*) as aggregate')
            ->whereBetween('created_at', [$start, $end])
            ->groupBy('date')
            ->orderBy('date')
            ->get()
            ->map(fn ($row) => [
                'date' => $row->date,
                'count' => (int) $row->aggregate,
            ])
            ->toArray();
    }

    protected function paymentStats(CarbonImmutable $start, CarbonImmutable $end): array
    {
        $payments = Payment::query()->whereBetween('created_at', [$start, $end]);
        $total = (clone $payments)->count();
        $succeeded = (clone $payments)->where('status', Payment::STATUS_SUCCEEDED)->count();
        $failed = (clone $payments)->whereIn('status', [Payment::STATUS_CANCELLED, Payment::STATUS_REQUIRES_ACTION])->count();
        $refunded = (clone $payments)->where('status', Payment::STATUS_REFUNDED)->count();
        $amount = (clone $payments)->where('status', Payment::STATUS_SUCCEEDED)->sum('amount_cents');

        return [
            'total' => $total,
            'succeeded' => $succeeded,
            'failed' => $failed,
            'refunded' => $refunded,
            'success_rate' => $total > 0 ? round(($succeeded / $total) * 100, 1) : 0,
            'revenue' => $amount / 100,
        ];
    }

    protected function mediaStats(CarbonImmutable $start, CarbonImmutable $end): array
    {
        if (! class_exists(MediaItem::class)) {
            return ['uploads' => 0, 'virtualTours' => 0];
        }

        $uploads = MediaItem::query()
            ->whereBetween('created_at', [$start, $end])
            ->count();

        $virtualTours = MediaItem::query()
            ->whereBetween('created_at', [$start, $end])
            ->where('category', 'virtual_tour')
            ->count();

        return [
            'uploads' => $uploads,
            'virtualTours' => $virtualTours,
        ];
    }

    protected function notificationStats(CarbonImmutable $start, CarbonImmutable $end): array
    {
        if (! class_exists(BookingNotification::class)) {
            return ['sent' => 0, 'failed' => 0, 'skipped' => 0];
        }

        return [
            'sent' => BookingNotification::query()
                ->whereBetween('created_at', [$start, $end])
                ->where('status', BookingNotification::STATUS_SENT)
                ->count(),
            'failed' => BookingNotification::query()
                ->whereBetween('created_at', [$start, $end])
                ->where('status', BookingNotification::STATUS_FAILED)
                ->count(),
            'skipped' => BookingNotification::query()
                ->whereBetween('created_at', [$start, $end])
                ->where('status', BookingNotification::STATUS_SKIPPED)
                ->count(),
        ];
    }
}
