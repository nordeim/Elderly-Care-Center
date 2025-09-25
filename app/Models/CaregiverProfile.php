<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class CaregiverProfile extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'client_id',
        'preferred_contact_method',
        'timezone',
        'sms_opt_in',
        'mfa_secret',
        'last_login_at',
        'preferences',
    ];

    protected $casts = [
        'sms_opt_in' => 'boolean',
        'last_login_at' => 'datetime',
        'preferences' => 'array',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function client()
    {
        return $this->belongsTo(Client::class);
    }

}
