<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class BookingNotification extends Model
{
    use HasFactory;

    public const STATUS_PENDING = 'pending';
    public const STATUS_SENT = 'sent';
    public const STATUS_FAILED = 'failed';
    public const STATUS_SKIPPED = 'skipped';

    protected $fillable = [
        'booking_id',
        'caregiver_profile_id',
        'channel',
        'status',
        'meta',
        'scheduled_for',
    ];

    protected $casts = [
        'meta' => 'array',
        'scheduled_for' => 'datetime',
    ];

    public function booking()
    {
        return $this->belongsTo(Booking::class);
    }

    public function caregiverProfile()
    {
        return $this->belongsTo(CaregiverProfile::class);
    }

    public function scopePending($query)
    {
        return $query->where('status', self::STATUS_PENDING);
    }

    public function scopeDueSoon($query, int $minutes = 60)
    {
        return $query->where('scheduled_for', '<=', now()->addMinutes($minutes));
    }

    public function markSent(array $meta = []): void
    {
        $this->fill([
            'status' => self::STATUS_SENT,
            'meta' => array_merge($this->meta ?? [], $meta),
        ])->save();
    }

    public function markFailed(string $reason, array $meta = []): void
    {
        $this->fill([
            'status' => self::STATUS_FAILED,
            'meta' => array_merge($this->meta ?? [], ['reason' => $reason], $meta),
        ])->save();
    }

    public function markSkipped(string $reason, array $meta = []): void
    {
        $this->fill([
            'status' => self::STATUS_SKIPPED,
            'meta' => array_merge($this->meta ?? [], ['reason' => $reason], $meta),
        ])->save();
    }
}
