<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Facility extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'address',
        'phone',
    ];

    protected $casts = [
        'address' => 'array',
    ];

    public function services()
    {
        return $this->hasMany(Service::class);
    }

    public function bookingSlots()
    {
        return $this->hasMany(BookingSlot::class);
    }
}
