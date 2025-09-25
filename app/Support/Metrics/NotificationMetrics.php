<?php

namespace App\Support\Metrics;

use Illuminate\Contracts\Cache\Repository as CacheRepository;
use Illuminate\Support\Facades\Cache;

class NotificationMetrics
{
    private CacheRepository $store;

    public function __construct(?CacheRepository $store = null)
    {
        $this->store = $store ?? Cache::store(config('metrics.store'));
    }

    public function recordScheduled(string $channel): void
    {
        $this->increment('notifications_scheduled_total');
        $this->increment("notifications_scheduled_total:{$channel}");
    }

    public function recordSent(string $channel): void
    {
        $this->increment('notifications_sent_total');
        $this->increment("notifications_sent_total:{$channel}");
    }

    public function recordFailed(string $channel): void
    {
        $this->increment('notifications_failed_total');
        $this->increment("notifications_failed_total:{$channel}");
    }

    public function recordSkipped(string $channel): void
    {
        $this->increment('notifications_skipped_total');
        $this->increment("notifications_skipped_total:{$channel}");
    }

    public function snapshot(): array
    {
        $keys = [
            'notifications_scheduled_total',
            'notifications_sent_total',
            'notifications_failed_total',
            'notifications_skipped_total',
        ];

        $channels = ['email', 'sms'];
        foreach ($channels as $channel) {
            $keys[] = "notifications_scheduled_total:{$channel}";
            $keys[] = "notifications_sent_total:{$channel}";
            $keys[] = "notifications_failed_total:{$channel}";
            $keys[] = "notifications_skipped_total:{$channel}";
        }

        $snapshot = [];
        foreach ($keys as $key) {
            $snapshot[$key] = (int) $this->store->get($this->namespaced($key), 0);
        }

        return $snapshot;
    }

    private function increment(string $key, int $amount = 1): void
    {
        $this->store->increment($this->namespaced($key), $amount);
    }

    public function value(string $key): int
    {
        return (int) $this->store->get($this->namespaced($key), 0);
    }

    private function namespaced(string $key): string
    {
        return sprintf('metrics:notifications:%s', $key);
    }
}
