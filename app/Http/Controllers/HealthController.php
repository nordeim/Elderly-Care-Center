<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Redis;

class HealthController extends Controller
{
    public function check(): JsonResponse
    {
        // Basic dependency probes with bounded timeouts
        $dbOk = false; $redisOk = false;
        try { DB::select('SELECT 1'); $dbOk = true; } catch (\Throwable $e) {}
        try { $redisOk = Redis::connection()->ping() === 'PONG'; } catch (\Throwable $e) {}

        $status = ($dbOk && $redisOk) ? 200 : 503;

        return response()->json([
            'status' => $status === 200 ? 'ok' : 'degraded',
            'checks' => [
                'db' => $dbOk ? 'ok' : 'fail',
                'redis' => $redisOk ? 'ok' : 'fail',
                'time' => now()->toIso8601String(),
            ],
        ], $status);
    }
}
