<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Payment extends Model
{
    use HasFactory;

    protected $fillable = [
        'booking_id',
        'stripe_payment_intent_id',
        'status',
        'amount_cents',
        'currency',
        'receipt_url',
        'metadata',
    ];

    protected $casts = [
        'amount_cents' => 'integer',
        'metadata' => 'array',
    ];

    public const STATUS_PENDING = 'pending';
    public const STATUS_REQUIRES_ACTION = 'requires_action';
    public const STATUS_SUCCEEDED = 'succeeded';
    public const STATUS_CANCELLED = 'cancelled';
    public const STATUS_REFUNDED = 'refunded';

    public function booking()
    {
        return $this->belongsTo(Booking::class);
    }

    public function scopeStatus($query, string $status)
    {
        return $query->where('status', $status);
    }

    public function amount(): string
    {
        return number_format($this->amount_cents / 100, 2);
    }
}
