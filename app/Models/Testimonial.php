<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Testimonial extends Model
{
    use HasFactory;

    protected $fillable = [
        'client_id',
        'content',
        'status',
    ];

    public function client()
    {
        return $this->belongsTo(Client::class);
    }
}
