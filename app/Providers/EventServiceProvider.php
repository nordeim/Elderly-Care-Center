<?php

namespace App\Providers;

use Illuminate\Foundation\Support\Providers\EventServiceProvider as ServiceProvider;

class EventServiceProvider extends ServiceProvider
{
    protected $listen = [
        // Register event listeners in future phases
    ];

    public function boot(): void
    {
        parent::boot();
    }
}
