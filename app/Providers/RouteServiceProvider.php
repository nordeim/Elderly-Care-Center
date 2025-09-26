<?php

namespace App\Providers;

use Illuminate\Foundation\Support\Providers\RouteServiceProvider as ServiceProvider;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\Facades\URL;
use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Http\Request;

class RouteServiceProvider extends ServiceProvider
{
    /**
     * Define your route model bindings, pattern filters, rate limiters, and HTTPS enforcement.
     */
    public function boot(): void
    {
        // Enforce HTTPS in production when APP_URL is https to avoid mixed content and insecure redirects.
        $appUrl = config('app.url');
        if (config('app.env') === 'production' && is_string($appUrl)) {
            $scheme = parse_url($appUrl, PHP_URL_SCHEME);
            if ($scheme === 'https') {
                URL::forceScheme('https');
            }
        }

        // Named rate limiters for clean use in routes (e.g., middleware('throttle:login')).
        $this->configureRateLimiting();

        // Route group wiring (unchanged)
        $this->routes(function () {
            Route::middleware('web')
                ->group(base_path('routes/web.php'));

            Route::prefix('api')
                ->middleware('api')
                ->group(base_path('routes/api.php'));
        });
    }

    /**
     * Configure application rate limiters.
     */
    protected function configureRateLimiting(): void
    {
        // Login limiter: 5 attempts per minute, scoped by IP + email to resist credential stuffing.
        RateLimiter::for('login', function (Request $request) {
            $key = sprintf('login:%s|%s', $request->ip(), mb_strtolower((string) $request->input('email', '')));
            return [
                Limit::perMinute(5)->by($key)->response(function () {
                    return response()->json([
                        'message' => 'Too many login attempts. Please try again in a minute.',
                    ], 429);
                }),
            ];
        });

        // Calendar export limiter: 30 requests per minute per user (or IP if guest).
        RateLimiter::for('calendar', function (Request $request) {
            $userKey = optional($request->user())->getAuthIdentifier();
            $key = $userKey ? "calendar:user:{$userKey}" : "calendar:ip:{$request->ip()}";
            return Limit::perMinute(30)->by($key);
        });

        // Baseline API limiter: 60 requests per minute per user or IP.
        RateLimiter::for('api', function (Request $request) {
            $userKey = optional($request->user())->getAuthIdentifier();
            return Limit::perMinute(60)->by($userKey ?: $request->ip());
        });
    }
}
