<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('payments', function (Blueprint $table) {
            $table->id();
            $table->foreignId('booking_id')->constrained('bookings')->cascadeOnUpdate()->restrictOnDelete();
            $table->string('stripe_payment_intent_id')->unique();
            $table->enum('status', ['pending', 'requires_action', 'succeeded', 'cancelled', 'refunded'])->default('pending');
            $table->unsignedBigInteger('amount_cents');
            $table->string('currency', 3)->default('usd');
            $table->string('receipt_url')->nullable();
            $table->json('metadata')->nullable();
            $table->timestamps();

            $table->index(['booking_id', 'status']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('payments');
    }
};
