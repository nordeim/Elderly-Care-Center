<?php

namespace App\Http\Controllers\Metrics;

use App\Http\Controllers\Controller;
use App\Support\Metrics\BookingMetrics;
use Illuminate\Http\Response;

class BookingMetricsController extends Controller
{
    public function __construct(private readonly BookingMetrics $metrics)
    {
    }

    public function __invoke(): Response
    {
        $snapshot = $this->metrics->snapshot();
        $statuses = config('booking.statuses', []);

        $lines = [
            '# HELP elderly_bookings_created_total Total number of booking requests created.',
            '# TYPE elderly_bookings_created_total counter',
            sprintf('elderly_bookings_created_total %d', $snapshot['bookings_created_total'] ?? 0),
        ];

        $lines[] = '# HELP elderly_booking_status_total Total bookings currently recorded per status.';
        $lines[] = '# TYPE elderly_booking_status_total gauge';
        foreach ($statuses as $status) {
            $value = $snapshot["booking_status_total:{$status}"] ?? 0;
            $lines[] = sprintf('elderly_booking_status_total{status="%s"} %d', $status, $value);
        }

        $lines[] = '# HELP elderly_booking_status_transition_total Total booking status transitions.';
        $lines[] = '# TYPE elderly_booking_status_transition_total counter';
        foreach ($statuses as $from) {
            foreach ($statuses as $to) {
                if ($from === $to) {
                    continue;
                }

                $value = $snapshot["booking_status_transition_total:{$from}:{$to}"] ?? 0;
                $lines[] = sprintf(
                    'elderly_booking_status_transition_total{from="%s",to="%s"} %d',
                    $from,
                    $to,
                    $value
                );
            }
        }

        $lines[] = '# HELP elderly_reservation_sweeper_total Reservation sweeper job executions.';
        $lines[] = '# TYPE elderly_reservation_sweeper_total counter';
        foreach (['success', 'failure'] as $result) {
            $value = $snapshot["reservation_sweeper_total:{$result}"] ?? 0;
            $lines[] = sprintf('elderly_reservation_sweeper_total{result="%s"} %d', $result, $value);
        }

        $body = implode("\n", $lines) . "\n";

        return response($body, 200)
            ->header('Content-Type', 'text/plain; version=0.0.4');
    }
}
