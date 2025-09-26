<?php

use Illuminate\Support\Facades\Artisan;

test('config contract passes with valid env', function () {
    putenv('APP_URL=http://localhost:8000');
    putenv('DB_PORT=3306');
    putenv('REDIS_PORT=6379');

    $exitCode = Artisan::call('contract:config');
    expect($exitCode)->toBe(0);
});
