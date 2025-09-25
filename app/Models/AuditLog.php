<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class AuditLog extends Model
{
    use HasFactory;

    public $timestamps = false;

    protected $fillable = [
        'action',
        'actor_type',
        'actor_id',
        'target_type',
        'target_id',
        'meta',
        'ip_address',
        'created_at',
    ];

    protected $casts = [
        'meta' => 'array',
        'created_at' => 'datetime',
    ];

    public function actor()
    {
        return $this->morphTo();
    }

    public function target()
    {
        return $this->morphTo();
    }

    public static function record(
        string $action,
        Model $actor,
        ?Model $target = null,
        array $meta = [],
        ?string $ipAddress = null
    ): self {
        return self::create([
            'action' => $action,
            'actor_type' => $actor->getMorphClass(),
            'actor_id' => $actor->getKey(),
            'target_type' => $target?->getMorphClass(),
            'target_id' => $target?->getKey(),
            'meta' => $meta,
            'ip_address' => $ipAddress,
            'created_at' => now(),
        ]);
    }
}
