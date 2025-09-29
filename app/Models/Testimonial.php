<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use App\Models\MediaItem;

class Testimonial extends Model
{
    use HasFactory;

    protected $fillable = [
        'client_id',
        'content',
        'status',
    ];

    public function client()
    {
        return $this->belongsTo(Client::class);
    }

    public function media()
    {
        return $this->morphToMany(MediaItem::class, 'associable', 'media_associations', 'associable_id', 'media_id')
            ->withPivot(['role', 'position'])
            ->orderBy('media_associations.position');
    }

    public function featuredMedia()
    {
        $collection = $this->relationLoaded('media') ? $this->media : $this->media()->get();

        return $collection->first(function (MediaItem $media) {
            return optional($media->pivot)->role === 'primary';
        });
    }
}
