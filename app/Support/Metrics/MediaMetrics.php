<?php

namespace App\Support\Metrics;

use Illuminate\Contracts\Cache\Repository as CacheRepository;
use Illuminate\Support\Facades\Cache;

class MediaMetrics
{
    private CacheRepository $store;

    public function __construct(?CacheRepository $store = null)
    {
        $this->store = $store ?? Cache::store(config('metrics.store'));
    }

    public function recordIngestQueued(): void
    {
        $this->increment('media_ingest_total');
        $this->increment('media_conversion_backlog');
    }

    public function recordTranscodeStart(): void
    {
        $this->increment('media_transcode_started_total');
    }

    public function recordTranscodeSuccess(): void
    {
        $this->increment('media_transcode_success_total');
        $this->decrement('media_conversion_backlog');
    }

    public function recordTranscodeFailure(): void
    {
        $this->increment('media_transcode_failure_total');
        $this->decrement('media_conversion_backlog');
    }

    public function recordVirusScanFailure(): void
    {
        $this->increment('media_virus_scan_failure_total');
    }

    public function snapshot(): array
    {
        $keys = [
            'media_ingest_total',
            'media_transcode_started_total',
            'media_transcode_success_total',
            'media_transcode_failure_total',
            'media_virus_scan_failure_total',
            'media_conversion_backlog',
        ];

        $snapshot = [];
        foreach ($keys as $key) {
            $snapshot[$key] = $this->value($key);
        }

        return $snapshot;
    }

    private function increment(string $key, int $amount = 1): void
    {
        $this->store->increment($this->namespaced($key), $amount);
    }

    private function decrement(string $key, int $amount = 1): void
    {
        $namespaced = $this->namespaced($key);
        $current = (int) $this->store->get($namespaced, 0);
        $newValue = max(0, $current - $amount);
        $this->store->put($namespaced, $newValue);
    }

    private function value(string $key): int
    {
        return (int) $this->store->get($this->namespaced($key), 0);
    }

    private function namespaced(string $key): string
    {
        return sprintf('metrics:media:%s', $key);
    }
}
