<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class MediaItem extends Model
{
    use HasFactory;
    use SoftDeletes;

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
        'uploaded_by',
        'uploaded_at',
    ];

    protected $casts = [
        'conversions' => 'array',
        'attributes' => 'array',
        'uploaded_at' => 'datetime',
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
}
