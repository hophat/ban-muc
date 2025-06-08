<?php

namespace App\Traits;

use App\Models\User;
use Illuminate\Support\Facades\Auth;

trait HasFarmAccess
{
    /**
     * Get the farm ID that the authenticated user has access to
     */
    protected function getAccessibleFarmId(): ?int
    {
        $user = Auth::user();
        if (!$user) {
            return null;
        }
        return $user->farm_id;
    }

    /**
     * Get the farm that the authenticated user has access to
     */
    protected function getAccessibleFarm()
    {
        $user = Auth::user();
        if (!$user) {
            return null;
        }

        return $user->farm_id;
    }

    /**
     * Check if the authenticated user has access to the given farm
     */
    protected function hasAccessToFarm(?int $farmId): bool
    {
        if (!$farmId) {
            return false;
        }

        $user = Auth::user();
        if (!$user) {
            return false;
        }

        // if ($user->role === 'admin') {
        //     return $user->ownedFarm?->id === $farmId;
        // }

        return $user->farm_id === $farmId;
    }
} 