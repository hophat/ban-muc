<?php

namespace App\Http\Controllers;

use App\Models\SquidType;
use App\Traits\HasFarmAccess;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class SquidTypeController extends Controller
{
    use HasFarmAccess;

    /**
     * Display a listing of the resource.
     */
    public function index()
    {
        $farmId = $this->getAccessibleFarmId();
        if (!$farmId) {
            return response()->json(['message' => 'Unauthorized'], 401);
        }

        $squidTypes = SquidType::where('farm_id', $farmId)
            ->orderBy('name')
            ->get();

        return response()->json($squidTypes);
    }

    /**
     * Show the form for creating a new resource.
     */
    public function create()
    {
        //
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request)
    {
        $farmId = $this->getAccessibleFarmId();
        if (!$farmId) {
            return response()->json(['message' => 'Unauthorized'], 401);
        }

        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'description' => 'nullable|string',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $squidType = SquidType::create([
            'farm_id' => $farmId,
            'name' => $request->name,
            'description' => $request->description,
        ]);

        return response()->json($squidType, 201);
    }

    /**
     * Display the specified resource.
     */
    public function show(SquidType $squidType)
    {
        if (!$this->hasAccessToFarm($squidType->farm_id)) {
            return response()->json(['message' => 'Unauthorized'], 401);
        }

        return response()->json($squidType->load(['purchases', 'sales']));
    }

    /**
     * Show the form for editing the specified resource.
     */
    public function edit(string $id)
    {
        //
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, SquidType $squidType)
    {
        if (!$this->hasAccessToFarm($squidType->farm_id)) {
            return response()->json(['message' => 'Unauthorized'], 401);
        }

        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'description' => 'nullable|string',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $squidType->update($request->all());

        return response()->json($squidType);
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(SquidType $squidType)
    {
        if (!$this->hasAccessToFarm($squidType->farm_id)) {
            return response()->json(['message' => 'Unauthorized'], 401);
        }

        // Check if squid type is being used
        if ($squidType->purchases()->exists() || $squidType->sales()->exists()) {
            return response()->json([
                'message' => 'Không thể xóa loại mực này vì đang được sử dụng trong giao dịch',
            ], 422);
        }

        $squidType->delete();

        return response()->json(null, 204);
    }
}
