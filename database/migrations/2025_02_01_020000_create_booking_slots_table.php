<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('booking_slots', function (Blueprint $table) {
            $table->id();
            $table->foreignId('service_id')->constrained('services')->cascadeOnDelete();
            $table->foreignId('facility_id')->constrained('facilities')->cascadeOnDelete();
            $table->timestamp('start_at');
            $table->timestamp('end_at');
            $table->integer('capacity')->default(1);
            $table->integer('available_count')->default(1);
            $table->integer('lock_version')->default(0);
            $table->timestamps();

            $table->unique(['service_id', 'facility_id', 'start_at', 'end_at'], 'booking_slots_unique_time');
            $table->index('start_at');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('booking_slots');
    }
};
