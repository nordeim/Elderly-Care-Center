<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class SlotReservation extends Model
{
    use HasFactory;

    protected $fillable = [
        'slot_id',
        'reserved_by_user_id',
        'reserved_for_client_id',
        'guest_email',
        'expires_at',
    ];

    protected $casts = [
        'expires_at' => 'datetime',
    ];

    public function slot()
    {
        return $this->belongsTo(BookingSlot::class, 'slot_id');
    }

    public function reservedBy()
    {
        return $this->belongsTo(User::class, 'reserved_by_user_id');
    }

    public function reservedFor()
    {
        return $this->belongsTo(Client::class, 'reserved_for_client_id');
    }
}
