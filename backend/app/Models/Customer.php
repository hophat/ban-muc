<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Customer extends Model
{
    use HasFactory;

    protected $fillable = [
        'farm_id',
        'name',
        'phone',
        'address',
        'description',
    ];

    /**
     * Get the farm that owns the customer.
     */
    public function farm()
    {
        return $this->belongsTo(Farm::class);
    }

    /**
     * Get the sales for the customer.
     */
    public function sales()
    {
        return $this->hasMany(Sale::class);
    }

    /**
     * Get total unpaid amount for the customer.
     */
    public function getTotalDebtAttribute()
    {
        return $this->sales()->where('payment_status', 'unpaid')->sum('total_amount');
    }
}
