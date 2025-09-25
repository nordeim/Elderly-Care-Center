<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('booking_status_history', function (Blueprint $table) {
            $table->id();
            $table->foreignId('booking_id')->constrained('bookings')->cascadeOnDelete();
            $table->enum('from_status', ['pending', 'confirmed', 'attended', 'cancelled', 'no_show', 'archived'])->nullable();
            $table->enum('to_status', ['pending', 'confirmed', 'attended', 'cancelled', 'no_show', 'archived']);
            $table->foreignId('changed_by')->nullable()->constrained('users');
            $table->timestamp('changed_at')->useCurrent();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('booking_status_history');
    }
};
