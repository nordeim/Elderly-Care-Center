<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class MediaAssociation extends Model
{
    use HasFactory;

    protected $fillable = [
        'media_id',
        'associable_type',
        'associable_id',
        'role',
        'position',
    ];

    public function media()
    {
        return $this->belongsTo(MediaItem::class);
    }

    public function associable()
    {
        return $this->morphTo();
    }
}
