<?php

namespace Tests\Unit\Metrics;

use App\Support\Metrics\BookingMetrics;
use Illuminate\Cache\ArrayStore;
use Illuminate\Cache\Repository;
use PHPUnit\Framework\TestCase;

class BookingMetricsTest extends TestCase
{
    public function test_records_booking_creation_and_snapshot(): void
    {
        $store = new Repository(new ArrayStore());
        $metrics = new BookingMetrics($store);

        $metrics->recordBookingCreated('pending');
        $metrics->recordBookingCreated('confirmed');
        $metrics->recordStatusChange('pending', 'confirmed');
        $metrics->recordSweeperRun('success');

        $snapshot = $metrics->snapshot();

        $this->assertSame(2, $snapshot['bookings_created_total']);
        $this->assertSame(1, $snapshot['booking_status_total:pending']);
        $this->assertSame(1, $snapshot['booking_status_total:confirmed']);
        $this->assertSame(1, $snapshot['booking_status_transition_total:pending:confirmed']);
        $this->assertSame(1, $snapshot['reservation_sweeper_total:success']);
    }
}
