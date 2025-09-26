<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('caregiver_profiles', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('client_id')->nullable()->constrained('clients')->nullOnDelete();
            $table->string('preferred_contact_method', 20)->default('email');
            $table->string('timezone', 64)->default('UTC');
            $table->boolean('sms_opt_in')->default(true);
            $table->string('mfa_secret', 128)->nullable();
            $table->timestamp('last_login_at')->nullable();
            $table->json('preferences')->nullable();
            $table->timestamps();

            $table->unique('user_id');
            $table->index('preferred_contact_method');
        });

        Schema::create('booking_notifications', function (Blueprint $table) {
            $table->id();
            $table->foreignId('booking_id')->constrained('bookings')->cascadeOnDelete();
            $table->foreignId('caregiver_profile_id')->constrained('caregiver_profiles')->cascadeOnDelete();
            $table->enum('channel', ['email', 'sms'])->default('email');
            $table->enum('status', ['pending', 'sent', 'failed', 'skipped'])->default('pending');
            $table->json('meta')->nullable();
            $table->timestamp('scheduled_for')->nullable();
            $table->timestamps();

            $table->unique(['booking_id', 'caregiver_profile_id', 'channel'], 'booking_notify_unique');
            $table->index(['status', 'scheduled_for']);
            $table->index('channel');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('booking_notifications');
        Schema::dropIfExists('caregiver_profiles');
    }
};
