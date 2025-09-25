<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('slot_reservations', function (Blueprint $table) {
            $table->id();
            $table->foreignId('slot_id')->constrained('booking_slots')->cascadeOnDelete();
            $table->foreignId('reserved_by_user_id')->nullable()->constrained('users');
            $table->foreignId('reserved_for_client_id')->nullable()->constrained('clients');
            $table->string('guest_email', 254)->nullable();
            $table->timestamp('expires_at');
            $table->timestamps();

            $table->unique(['slot_id', 'reserved_for_client_id']);
            $table->unique(['slot_id', 'guest_email']);
            $table->index('expires_at');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('slot_reservations');
    }
};
