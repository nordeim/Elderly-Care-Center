<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('bookings', function (Blueprint $table) {
            $table->id();
            $table->foreignId('slot_id')->constrained('booking_slots')->cascadeOnDelete();
            $table->foreignId('client_id')->nullable()->constrained('clients')->nullOnDelete();
            $table->string('guest_email', 254)->nullable();
            $table->enum('status', ['pending', 'confirmed', 'attended', 'cancelled', 'no_show', 'archived'])->default('pending');
            $table->foreignId('created_by')->nullable()->constrained('users');
            $table->enum('created_via', ['web', 'admin', 'phone', 'api'])->default('web');
            $table->uuid('uuid')->default(DB::raw('(UUID())'));
            $table->json('metadata')->nullable();
            $table->timestamp('cancelled_at')->nullable();
            $table->timestamps();

            $table->unique(['slot_id', 'client_id']);
            $table->unique(['slot_id', 'guest_email']);
            $table->index(['status', 'created_at']);
            $table->index('slot_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('bookings');
    }
};
