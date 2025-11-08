<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Exchange extends Model
{
    protected $fillable = [
        'transfer_id',
        'converted_amount_syp',
        'converted_amount_try',
        'exchange_rate_usd_to_syp',
        'exchange_rate_usd_to_try',
        'exchange_date',
    ];

    protected $casts = [
        'exchange_date' => 'date',
        'converted_amount_syp' => 'decimal:2',
        'converted_amount_try' => 'decimal:2',
        'exchange_rate_usd_to_syp' => 'decimal:4',
        'exchange_rate_usd_to_try' => 'decimal:4',
    ];

    public function transfer(): BelongsTo
    {
        return $this->belongsTo(Transfer::class);
    }
}
