<?php

namespace Tests\Unit\Metrics;

use App\Support\Metrics\BookingMetrics;
use Illuminate\Contracts\Cache\Repository as CacheRepository;
use PHPUnit\Framework\TestCase;

class BookingMetricsTest extends TestCase
{
    public function test_records_booking_creation_and_snapshot(): void
    {
        $store = new InMemoryStore();
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

class InMemoryStore implements CacheRepository
{
    private array $store = [];

    public function has($key)
    {
        return array_key_exists($key, $this->store);
    }

    public function get($key, $default = null)
    {
        return $this->store[$key] ?? $default;
    }

    public function many(array $keys)
    {
        $results = [];
        foreach ($keys as $key) {
            $results[$key] = $this->get($key);
        }

        return $results;
    }

    public function pull($key, $default = null)
    {
        $value = $this->get($key, $default);
        unset($this->store[$key]);

        return $value;
    }

    public function put($key, $value, $ttl = null)
    {
        $this->store[$key] = $value;

        return true;
    }

    public function putMany(array $values, $ttl = null)
    {
        foreach ($values as $key => $value) {
            $this->put($key, $value, $ttl);
        }

        return true;
    }

    public function add($key, $value, $ttl = null)
    {
        if ($this->has($key)) {
            return false;
        }

        $this->put($key, $value, $ttl);

        return true;
    }

    public function increment($key, $value = 1)
    {
        $this->store[$key] = ($this->store[$key] ?? 0) + $value;

        return $this->store[$key];
    }

    public function decrement($key, $value = 1)
    {
        $this->store[$key] = ($this->store[$key] ?? 0) - $value;

        return $this->store[$key];
    }

    public function forever($key, $value)
    {
        $this->store[$key] = $value;

        return true;
    }

    public function forget($key)
    {
        unset($this->store[$key]);

        return true;
    }

    public function flush()
    {
        $this->store = [];

        return true;
    }

    public function getStore()
    {
        return $this;
    }

    public function getMultiple($keys, $default = null)
    {
        return $this->many(is_array($keys) ? $keys : iterator_to_array($keys));
    }

    public function set($key, $value, $ttl = null)
    {
        return $this->put($key, $value, $ttl);
    }

    public function setMultiple($values, $ttl = null)
    {
        return $this->putMany(is_array($values) ? $values : iterator_to_array($values), $ttl);
    }

    public function delete($key)
    {
        return $this->forget($key);
    }

    public function deleteMultiple($keys)
    {
        foreach (is_array($keys) ? $keys : iterator_to_array($keys) as $key) {
            $this->forget($key);
        }

        return true;
    }

    public function foreverMany(array $values)
    {
        return $this->putMany($values);
    }

    public function missing($key)
    {
        return ! $this->has($key);
    }

    public function remember($key, $ttl, $callback)
    {
        if ($this->has($key)) {
            return $this->get($key);
        }

        $value = $callback();
        $this->put($key, $value, $ttl);

        return $value;
    }

    public function rememberForever($key, $callback)
    {
        if ($this->has($key)) {
            return $this->get($key);
        }

        $value = $callback();
        $this->forever($key, $value);

        return $value;
    }

    public function sear($key, $callback)
    {
        return $this->rememberForever($key, $callback);
    }
}
