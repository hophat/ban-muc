<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Farm extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'address',
        'phone',
        'email',
        'description',
        'owner_id',
    ];

    /**
     * Get the admin owner of the farm.
     */
    public function owner()
    {
        return $this->belongsTo(User::class, 'owner_id');
    }

    /**
     * Get the staff members of the farm.
     */
    public function staff()
    {
        return $this->hasMany(User::class, 'farm_id');
    }

    /**
     * Get the purchases for the farm.
     */
    public function purchases()
    {
        return $this->hasMany(Purchase::class);
    }

    /**
     * Get the sales for the farm.
     */
    public function sales()
    {
        return $this->hasMany(Sale::class);
    }

    /**
     * Get the expenses for the farm.
     */
    public function expenses()
    {
        return $this->hasMany(Expense::class);
    }

    /**
     * Get the boats for the farm.
     */
    public function boats()
    {
        return $this->hasMany(Boat::class);
    }

    /**
     * Get the customers for the farm.
     */
    public function customers()
    {
        return $this->hasMany(Customer::class);
    }

    /**
     * Get the squid types for the farm.
     */
    public function squidTypes()
    {
        return $this->hasMany(SquidType::class);
    }
} 