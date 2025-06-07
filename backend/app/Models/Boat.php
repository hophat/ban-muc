<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Boat extends Model
{
    use HasFactory;

    protected $fillable = [
        'farm_id',
        'name',
        'owner_name',
        'phone',
        'description',
    ];

    /**
     * Get the farm that owns the boat.
     */
    public function farm()
    {
        return $this->belongsTo(Farm::class);
    }

    /**
     * Get the purchases for the boat.
     */
    public function purchases()
    {
        return $this->hasMany(Purchase::class);
    }
}
