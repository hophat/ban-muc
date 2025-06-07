<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Sale extends Model
{
    use HasFactory;

    protected $fillable = [
        'farm_id',
        'customer_id',
        'squid_type_id',
        'weight',
        'unit_price',
        'total_amount',
        'sale_date',
        'payment_status',
        'notes',
    ];

    protected $casts = [
        'sale_date' => 'date',
        'weight' => 'decimal:2',
        'unit_price' => 'decimal:2',
        'total_amount' => 'decimal:2',
    ];

    /**
     * Get the farm that owns the sale.
     */
    public function farm()
    {
        return $this->belongsTo(Farm::class);
    }

    /**
     * Get the customer that owns the sale.
     */
    public function customer()
    {
        return $this->belongsTo(Customer::class);
    }

    /**
     * Get the squid type that owns the sale.
     */
    public function squidType()
    {
        return $this->belongsTo(SquidType::class);
    }

    /**
     * Calculate total amount automatically
     */
    protected static function boot()
    {
        parent::boot();

        static::saving(function ($model) {
            $model->total_amount = $model->weight * $model->unit_price;
        });
    }

    /**
     * Scope a query to only include unpaid sales.
     */
    public function scopeUnpaid($query)
    {
        return $query->where('payment_status', 'unpaid');
    }

    /**
     * Scope a query to only include paid sales.
     */
    public function scopePaid($query)
    {
        return $query->where('payment_status', 'paid');
    }
}
