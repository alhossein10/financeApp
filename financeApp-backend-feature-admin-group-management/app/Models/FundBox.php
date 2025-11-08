<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class FundBox extends Model
{
    protected $fillable = [
        'user_id',
        'balance_usd',
        'last_calculated_at',
    ];

    protected $casts = [
        'balance_usd' => 'decimal:2',
        'last_calculated_at' => 'datetime',
    ];

    /**
     * Get the user that owns the fund box.
     */
    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
