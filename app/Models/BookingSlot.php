<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class BookingSlot extends Model
{
    use HasFactory;

    protected $fillable = [
        'service_id',
        'facility_id',
        'start_at',
        'end_at',
        'capacity',
        'available_count',
        'lock_version',
    ];

    protected $casts = [
        'start_at' => 'datetime',
        'end_at' => 'datetime',
    ];

    public function service()
    {
        return $this->belongsTo(Service::class);
    }

    public function facility()
    {
        return $this->belongsTo(Facility::class);
    }

    public function bookings()
    {
        return $this->hasMany(Booking::class, 'slot_id');
    }

    public function scopeUpcoming($query)
    {
        return $query->where('start_at', '>=', now())->orderBy('start_at');
    }
}
