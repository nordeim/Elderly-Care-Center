<?php

namespace App\Http\Controllers\Metrics;

use App\Http\Controllers\Controller;
use App\Support\Metrics\BookingMetrics;
use App\Support\Metrics\MediaMetrics;
use App\Support\Metrics\NotificationMetrics;
use Illuminate\Http\Response;

class BookingMetricsController extends Controller
{
    public function __construct(
        private readonly BookingMetrics $bookingMetrics,
        private readonly MediaMetrics $mediaMetrics,
        private readonly NotificationMetrics $notificationMetrics
    )
    {
    }

    public function __invoke(): Response
    {
        $bookingSnapshot = $this->bookingMetrics->snapshot();
        $mediaSnapshot = $this->mediaMetrics->snapshot();
        $notificationSnapshot = $this->notificationMetrics->snapshot();

        $lines = array_merge(
            $this->formatBookingMetrics($bookingSnapshot),
            $this->formatMediaMetrics($mediaSnapshot),
            $this->formatNotificationMetrics($notificationSnapshot)
        );

        return response(implode("\n", $lines) . "\n", 200)
            ->header('Content-Type', 'text/plain; version=0.0.4');
    }

    private function formatBookingMetrics(array $snapshot): array
    {
        $statuses = config('booking.statuses', []);

        $lines = [
            '# HELP elderly_bookings_created_total Total number of booking requests created.',
            '# TYPE elderly_bookings_created_total counter',
            sprintf('elderly_bookings_created_total %d', $snapshot['bookings_created_total'] ?? 0),
            '# HELP elderly_booking_status_total Total bookings currently recorded per status.',
            '# TYPE elderly_booking_status_total gauge',
        ];

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

        return $lines;
    }

    private function formatMediaMetrics(array $snapshot): array
    {
        $lines = [
            '# HELP elderly_media_ingest_total Total number of media items queued for ingestion.',
            '# TYPE elderly_media_ingest_total counter',
            sprintf('elderly_media_ingest_total %d', $snapshot['media_ingest_total'] ?? 0),

            '# HELP elderly_media_transcode_started_total Media transcode jobs started.',
            '# TYPE elderly_media_transcode_started_total counter',
            sprintf('elderly_media_transcode_started_total %d', $snapshot['media_transcode_started_total'] ?? 0),

            '# HELP elderly_media_transcode_success_total Media transcode jobs completed successfully.',
            '# TYPE elderly_media_transcode_success_total counter',
            sprintf('elderly_media_transcode_success_total %d', $snapshot['media_transcode_success_total'] ?? 0),

            '# HELP elderly_media_transcode_failure_total Media transcode jobs that failed.',
            '# TYPE elderly_media_transcode_failure_total counter',
            sprintf('elderly_media_transcode_failure_total %d', $snapshot['media_transcode_failure_total'] ?? 0),

            '# HELP elderly_media_virus_scan_failure_total Media items that failed virus scanning.',
            '# TYPE elderly_media_virus_scan_failure_total counter',
            sprintf('elderly_media_virus_scan_failure_total %d', $snapshot['media_virus_scan_failure_total'] ?? 0),

            '# HELP elderly_media_conversion_backlog Media items currently pending conversion.',
            '# TYPE elderly_media_conversion_backlog gauge',
            sprintf('elderly_media_conversion_backlog %d', $snapshot['media_conversion_backlog'] ?? 0),
        ];

        return $lines;
    }

    private function formatNotificationMetrics(array $snapshot): array
    {
        $lines = [
            '# HELP elderly_notifications_scheduled_total Notifications scheduled for delivery.',
            '# TYPE elderly_notifications_scheduled_total counter',
            sprintf('elderly_notifications_scheduled_total %d', $snapshot['notifications_scheduled_total'] ?? 0),

            '# HELP elderly_notifications_sent_total Notifications successfully delivered.',
            '# TYPE elderly_notifications_sent_total counter',
            sprintf('elderly_notifications_sent_total %d', $snapshot['notifications_sent_total'] ?? 0),

            '# HELP elderly_notifications_failed_total Notifications that failed delivery.',
            '# TYPE elderly_notifications_failed_total counter',
            sprintf('elderly_notifications_failed_total %d', $snapshot['notifications_failed_total'] ?? 0),

            '# HELP elderly_notifications_skipped_total Notifications skipped due to preferences or quiet hours.',
            '# TYPE elderly_notifications_skipped_total counter',
            sprintf('elderly_notifications_skipped_total %d', $snapshot['notifications_skipped_total'] ?? 0),
        ];

        foreach (['email', 'sms'] as $channel) {
            $lines[] = sprintf(
                'elderly_notifications_scheduled_total{channel="%s"} %d',
                $channel,
                $snapshot["notifications_scheduled_total:{$channel}"] ?? 0
            );
            $lines[] = sprintf(
                'elderly_notifications_sent_total{channel="%s"} %d',
                $channel,
                $snapshot["notifications_sent_total:{$channel}"] ?? 0
            );
            $lines[] = sprintf(
                'elderly_notifications_failed_total{channel="%s"} %d',
                $channel,
                $snapshot["notifications_failed_total:{$channel}"] ?? 0
            );
            $lines[] = sprintf(
                'elderly_notifications_skipped_total{channel="%s"} %d',
                $channel,
                $snapshot["notifications_skipped_total:{$channel}"] ?? 0
            );
        }

        return $lines;
    }
}
