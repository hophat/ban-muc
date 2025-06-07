<?php

namespace App\Http\Controllers;

use App\Models\Boat;
use App\Traits\HasFarmAccess;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class BoatController extends Controller
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

        $boats = Boat::where('farm_id', $farmId)
            ->orderBy('name')
            ->get();

        return response()->json($boats);
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
            'owner_name' => 'required|string|max:255',
            'phone' => 'required|string|max:20',
            'description' => 'nullable|string',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $boat = Boat::create([
            'farm_id' => $farmId,
            'name' => $request->name,
            'owner_name' => $request->owner_name,
            'phone' => $request->phone,
            'description' => $request->description,
        ]);

        return response()->json($boat, 201);
    }

    /**
     * Display the specified resource.
     */
    public function show(Boat $boat)
    {
        if (!$this->hasAccessToFarm($boat->farm_id)) {
            return response()->json(['message' => 'Unauthorized'], 401);
        }

        return response()->json($boat->load('purchases'));
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
    public function update(Request $request, Boat $boat)
    {
        if (!$this->hasAccessToFarm($boat->farm_id)) {
            return response()->json(['message' => 'Unauthorized'], 401);
        }

        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'owner_name' => 'required|string|max:255',
            'phone' => 'required|string|max:20',
            'description' => 'nullable|string',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $boat->update($request->all());

        return response()->json($boat);
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(Boat $boat)
    {
        if (!$this->hasAccessToFarm($boat->farm_id)) {
            return response()->json(['message' => 'Unauthorized'], 401);
        }

        // Check if boat has any purchases
        if ($boat->purchases()->exists()) {
            return response()->json([
                'message' => 'Không thể xóa thuyền này vì đã có giao dịch mua hàng',
            ], 422);
        }

        $boat->delete();

        return response()->json(null, 204);
    }
}
