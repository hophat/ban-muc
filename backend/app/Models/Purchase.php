<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Purchase extends Model
{
    use HasFactory;

    protected $fillable = [
        'farm_id',
        'boat_id',
        'squid_type_id',
        'weight',
        'unit_price',
        'total_amount',
        'purchase_date',
        'notes',
    ];

    protected $casts = [
        'purchase_date' => 'date',
        'weight' => 'decimal:2',
        'unit_price' => 'decimal:2',
        'total_amount' => 'decimal:2',
    ];

    /**
     * Get the farm that owns the purchase.
     */
    public function farm()
    {
        return $this->belongsTo(Farm::class);
    }

    /**
     * Get the boat that owns the purchase.
     */
    public function boat()
    {
        return $this->belongsTo(Boat::class);
    }

    /**
     * Get the squid type that owns the purchase.
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
}
