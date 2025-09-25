<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('media_items', function (Blueprint $table) {
            $table->id();
            $table->uuid('uuid')->unique();
            $table->string('owner_type')->nullable();
            $table->unsignedBigInteger('owner_id')->nullable();
            $table->string('title')->nullable();
            $table->string('file_url', 1024);
            $table->string('mime_type', 100);
            $table->unsignedBigInteger('size_bytes');
            $table->json('conversions')->nullable();
            $table->string('captions_url', 1024)->nullable();
            $table->json('attributes')->nullable();
            $table->foreignId('uploaded_by')->nullable()->constrained('users');
            $table->timestamp('uploaded_at')->useCurrent();
            $table->softDeletes();
            $table->timestamps();

            $table->index(['owner_type', 'owner_id']);
        });

        Schema::create('media_associations', function (Blueprint $table) {
            $table->id();
            $table->foreignId('media_id')->constrained('media_items')->cascadeOnDelete();
            $table->string('associable_type');
            $table->unsignedBigInteger('associable_id');
            $table->string('role', 50)->nullable();
            $table->unsignedInteger('position')->default(0);
            $table->timestamps();

            $table->unique(['media_id', 'associable_type', 'associable_id', 'role'], 'media_assoc_unique');
            $table->index(['associable_type', 'associable_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('media_associations');
        Schema::dropIfExists('media_items');
    }
};
