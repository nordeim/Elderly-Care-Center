<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('clients', function (Blueprint $table) {
            $table->id();
            $table->string('first_name')->nullable();
            $table->string('last_name')->nullable();
            $table->date('dob')->nullable();
            $table->string('email', 254)->nullable()->index();
            $table->string('phone', 64)->nullable();
            $table->json('address')->nullable();
            $table->string('language_preference', 16)->default('en');
            $table->string('consent_version', 64)->nullable();
            $table->foreignId('consent_given_by')->nullable()->constrained('users');
            $table->timestamp('consent_revoked_at')->nullable();
            $table->enum('sensitivity', ['low', 'medium', 'high'])->default('medium');
            $table->timestamp('archived_at')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('clients');
    }
};
