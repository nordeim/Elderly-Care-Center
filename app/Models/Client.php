<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Client extends Model
{
    use HasFactory;

    protected $fillable = [
        'first_name',
        'last_name',
        'dob',
        'email',
        'phone',
        'address',
        'language_preference',
        'consent_version',
        'consent_given_by',
        'consent_revoked_at',
        'sensitivity',
        'archived_at',
    ];

    protected $casts = [
        'dob' => 'date',
        'address' => 'array',
        'consent_revoked_at' => 'datetime',
        'archived_at' => 'datetime',
    ];

    public function bookings()
    {
        return $this->hasMany(Booking::class);
    }
}
