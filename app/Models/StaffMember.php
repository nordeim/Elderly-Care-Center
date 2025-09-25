<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class StaffMember extends Model
{
    use HasFactory;

    protected $fillable = [
        'full_name',
        'role',
        'bio',
        'photo_url',
        'certifications',
    ];

    protected $casts = [
        'certifications' => 'array',
    ];
}
