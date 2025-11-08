<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;

class Expense extends Model
{
    use SoftDeletes;

    protected $fillable = [
        'user_id',
        'organization_id',
        'department_id',
        'description',
        'price_usd',
        'price_syp',
        'price_try',
        'has_invoice',
        'invoice_path',
        'expense_date',
        'sync_status',
        'synced_at',
        'sync_retry_count',
        'sync_error_message',
    ];

    protected $casts = [
        'expense_date' => 'date',
        'synced_at' => 'datetime',
        'has_invoice' => 'boolean',
        'price_usd' => 'decimal:2',
        'price_syp' => 'decimal:2',
        'price_try' => 'decimal:2',
        'sync_retry_count' => 'integer',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function organization(): BelongsTo
    {
        return $this->belongsTo(Organization::class);
    }

    public function department(): BelongsTo
    {
        return $this->belongsTo(Department::class);
    }
}
