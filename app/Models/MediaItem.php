<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class MediaItem extends Model
{
    use HasFactory;
    use SoftDeletes;

    public const STATUS_PENDING = 'pending';
    public const STATUS_PROCESSING = 'processing';
    public const STATUS_READY = 'ready';
    public const STATUS_FAILED = 'failed';

    protected $fillable = [
        'uuid',
        'owner_type',
        'owner_id',
        'title',
        'file_url',
        'mime_type',
        'size_bytes',
        'conversions',
        'captions_url',
        'attributes',
        'status',
        'error_message',
        'uploaded_by',
        'uploaded_at',
    ];

    protected $casts = [
        'conversions' => 'array',
        'attributes' => 'array',
        'uploaded_at' => 'datetime',
        'status' => 'string',
    ];

    public function owner()
    {
        return $this->morphTo();
    }

    public function associations()
    {
        return $this->hasMany(MediaAssociation::class);
    }

    public function uploader()
    {
        return $this->belongsTo(User::class, 'uploaded_by');
    }

    public function markStatus(string $status, ?string $errorMessage = null): void
    {
        $this->forceFill([
            'status' => $status,
            'error_message' => $errorMessage,
        ])->save();
    }
}
