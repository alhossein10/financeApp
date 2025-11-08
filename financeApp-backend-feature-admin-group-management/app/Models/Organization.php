<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Organization extends Model
{
    use HasFactory;

    /**
     * The attributes that are mass assignable.
     *
     * @var array<int, string>
     */
    protected $fillable = [
        'name',
    ];

    /**
     * Get the departments for the organization.
     */
    public function departments()
    {
        return $this->hasMany(Department::class);
    }

    /**
     * Get the users for the organization.
     */
    public function users()
    {
        return $this->hasMany(User::class);
    }

    /**
     * Get the expenses for the organization.
     */
    public function expenses()
    {
        return $this->hasMany(Expense::class);
    }

    /**
     * Get the transfers for the organization.
     */
    public function transfers()
    {
        return $this->hasMany(Transfer::class);
    }

    /**
     * Get the incoming transactions for the organization.
     */
    public function incomings()
    {
        return $this->hasMany(Incoming::class);
    }
}
