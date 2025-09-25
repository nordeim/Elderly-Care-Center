<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Booking extends Model
{
    use HasFactory;

    protected $fillable = [
        'slot_id',
        'client_id',
        'guest_email',
        'status',
        'created_by',
        'created_via',
        'uuid',
        'metadata',
        'cancelled_at',
    ];

    protected $casts = [
        'metadata' => 'array',
        'cancelled_at' => 'datetime',
    ];

    public function slot()
    {
        return $this->belongsTo(BookingSlot::class, 'slot_id');
    }

    public function client()
    {
        return $this->belongsTo(Client::class);
    }

    public function creator()
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function statusHistory()
    {
        return $this->hasMany(BookingStatusHistory::class);
    }
}
