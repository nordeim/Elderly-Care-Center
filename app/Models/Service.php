<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Service extends Model
{
    use HasFactory;

    protected $fillable = [
        'facility_id',
        'name',
        'description',
        'duration_minutes',
    ];

    public function facility()
    {
        return $this->belongsTo(Facility::class);
    }

    public function bookingSlots()
    {
        return $this->hasMany(BookingSlot::class);
    }
}
