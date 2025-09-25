<?php

use Illuminate\Support\Facades\Route;

Route::middleware('api')->group(function () {
    Route::get('/health', fn () => ['status' => 'ok']);
});
