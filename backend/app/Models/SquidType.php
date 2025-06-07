<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class SquidType extends Model
{
    use HasFactory;

    protected $fillable = [
        'farm_id',
        'name',
        'description',
    ];

    /**
     * Get the farm that owns the squid type.
     */
    public function farm()
    {
        return $this->belongsTo(Farm::class);
    }

    /**
     * Get the purchases for the squid type.
     */
    public function purchases()
    {
        return $this->hasMany(Purchase::class);
    }

    /**
     * Get the sales for the squid type.
     */
    public function sales()
    {
        return $this->hasMany(Sale::class);
    }
}
