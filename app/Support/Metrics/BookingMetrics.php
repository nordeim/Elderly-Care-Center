<?php

namespace App\Support\Metrics;

use Illuminate\Contracts\Cache\Repository as CacheRepository;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Config;

class BookingMetrics
{
    private CacheRepository $store;

    public function __construct(?CacheRepository $store = null)
    {
        $this->store = $store ?? Cache::store(config('metrics.store'));
    }

    public function recordBookingCreated(string $status = 'pending'): void
    {
        $this->increment("booking_status_total:{$status}");
        $this->increment('bookings_created_total');
    }

    public function recordStatusChange(string $from, string $to): void
    {
        $this->increment("booking_status_transition_total:{$from}:{$to}");
    }

    public function recordSweeperRun(string $result): void
    {
        $this->increment("reservation_sweeper_total:{$result}");
    }

    public function snapshot(): array
    {
        $statuses = Config::get('booking.statuses', []);
        $snapshot = [
            'bookings_created_total' => $this->value('bookings_created_total'),
        ];

        foreach ($statuses as $status) {
            $snapshot["booking_status_total:{$status}"] = $this->value("booking_status_total:{$status}");
        }

        foreach ($statuses as $from) {
            foreach ($statuses as $to) {
                if ($from === $to) {
                    continue;
                }

                $snapshot["booking_status_transition_total:{$from}:{$to}"] = $this->value("booking_status_transition_total:{$from}:{$to}");
            }
        }

        foreach (['success', 'failure'] as $result) {
            $snapshot["reservation_sweeper_total:{$result}"] = $this->value("reservation_sweeper_total:{$result}");
        }

        return $snapshot;
    }

    private function increment(string $key): void
    {
        $this->store->increment($this->namespaced($key));
    }

    private function value(string $key): int
    {
        return (int) $this->store->get($this->namespaced($key), 0);
    }

    private function namespaced(string $key): string
    {
        return sprintf('metrics:booking:%s', $key);
    }
}
