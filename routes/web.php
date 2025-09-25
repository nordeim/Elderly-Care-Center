<?php

use App\Http\Controllers\Admin\BookingInboxController;
use App\Http\Controllers\Admin\ServiceController;
use App\Http\Controllers\Admin\StaffController as AdminStaffController;
use App\Http\Controllers\Auth\LoginController;
use App\Http\Controllers\Site\BookingController;
use App\Http\Controllers\Site\HomeController;
use App\Http\Controllers\Site\ServicesController;
use App\Http\Controllers\Site\StaffController as SiteStaffController;
use App\Http\Controllers\Site\TestimonialsController;
use App\Http\Controllers\Metrics\BookingMetricsController;
use Illuminate\Support\Facades\Route;

Route::middleware('web')->group(function () {
    Route::get('/login', [LoginController::class, 'show'])->name('login');
    Route::post('/login', [LoginController::class, 'authenticate']);
    Route::post('/logout', function () {
        auth()->logout();
        request()->session()->invalidate();
        request()->session()->regenerateToken();

        return redirect('/login');
    })->name('logout');

    Route::get('/', HomeController::class)->name('home');
    Route::get('/services', ServicesController::class)->name('services.index');
    Route::get('/staff', SiteStaffController::class)->name('staff.index');
    Route::get('/testimonials', TestimonialsController::class)->name('testimonials.index');
    Route::get('/book', [BookingController::class, 'create'])->name('booking.create');
    Route::post('/book', [BookingController::class, 'store'])->name('booking.store');

    Route::middleware(['auth', 'can:access-admin'])->prefix('admin')->as('admin.')->group(function () {
        Route::get('/', [BookingInboxController::class, 'index'])->name('dashboard');
        Route::post('/bookings/{booking}/status', [BookingInboxController::class, 'updateStatus'])->name('bookings.status');

        Route::resource('bookings', BookingInboxController::class)->only(['index']);
        Route::resource('services', ServiceController::class);
        Route::resource('staff', AdminStaffController::class)->except(['show']);
    });
});
