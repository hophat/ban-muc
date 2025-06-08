<?php

namespace App\Http\Controllers;

use App\Models\Purchase;
use App\Models\Boat;
use App\Models\SquidType;
use App\Traits\HasFarmAccess;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class PurchaseController extends Controller
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
        $purchases = Purchase::with(['boat', 'squidType'])
            ->where('farm_id', $farmId)
            ->orderBy('purchase_date', 'desc')
            ->get();

        return response()->json($purchases);
    }

    /**
     * Show the form for creating a new resource.
     */
    public function create()
    {
        $farmId = $this->getAccessibleFarmId();
        if (!$farmId) {
            return response()->json(['message' => 'Unauthorized'], 401);
        }

        $boats = Boat::where('farm_id', $farmId)->get();
        $squidTypes = SquidType::where('farm_id', $farmId)->get();

        return response()->json([
            'boats' => $boats,
            'squid_types' => $squidTypes,
        ]);
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
            'boat_id' => 'required|exists:boats,id',
            'squid_type_id' => 'required|exists:squid_types,id',
            'weight' => 'required|numeric|min:0',
            'unit_price' => 'required|numeric|min:0',
            'purchase_date' => 'required|date',
            'notes' => 'nullable|string',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        // Load boat and squid type models
        $boat = Boat::findOrFail($request->boat_id);
        $squidType = SquidType::findOrFail($request->squid_type_id);

        // Verify boat belongs to the farm
        if (!$this->hasAccessToFarm($boat->farm_id)) {
            return response()->json(['message' => 'Unauthorized'], 401);
        }

        // Verify squid type belongs to the farm
        if (!$this->hasAccessToFarm($squidType->farm_id)) {
            return response()->json(['message' => 'Unauthorized'], 401);
        }

        $purchase = Purchase::create([
            'farm_id' => $farmId,
            'boat_id' => $request->boat_id,
            'squid_type_id' => $request->squid_type_id,
            'weight' => $request->weight,
            'unit_price' => $request->unit_price,
            'purchase_date' => $request->purchase_date,
            'notes' => $request->notes,
        ]);

        return response()->json($purchase->load(['boat', 'squidType']), 201);
    }

    /**
     * Display the specified resource.
     */
    public function show(Purchase $purchase)
    {
        if (!$this->hasAccessToFarm($purchase->farm_id)) {
            return response()->json(['message' => 'Unauthorized'], 401);
        }

        return response()->json($purchase->load(['boat', 'squidType']));
    }

    /**
     * Show the form for editing the specified resource.
     */
    public function edit(string $id)
    {
        $farmId = $this->getAccessibleFarmId();
        if (!$farmId) {
            return response()->json(['message' => 'Unauthorized'], 401);
        }

        try {
            $purchase = Purchase::with(['boat', 'squidType'])
                ->where('farm_id', $farmId)
                ->findOrFail($id);

            if (!$purchase) {
                return response()->json(['message' => 'Không tìm thấy giao dịch mua'], 404);
            }

            return response()->json($purchase);
        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json(['message' => 'Không tìm thấy giao dịch mua'], 404);
        }
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, Purchase $purchase)
    {
        if (!$this->hasAccessToFarm($purchase->farm_id)) {
            return response()->json(['message' => 'Unauthorized'], 401);
        }

        $validator = Validator::make($request->all(), [
            'boat_id' => 'required|exists:boats,id',
            'squid_type_id' => 'required|exists:squid_types,id',
            'weight' => 'required|numeric|min:0',
            'unit_price' => 'required|numeric|min:0',
            'purchase_date' => 'required|date',
            'notes' => 'nullable|string',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        // Load boat and squid type models
        $boat = \App\Models\Boat::findOrFail($request->boat_id);
        $squidType = \App\Models\SquidType::findOrFail($request->squid_type_id);

        // Verify boat belongs to the farm
        if (!$this->hasAccessToFarm($boat->farm_id)) {
            return response()->json(['message' => 'Unauthorized'], 401);
        }

        // Verify squid type belongs to the farm
        if (!$this->hasAccessToFarm($squidType->farm_id)) {
            return response()->json(['message' => 'Unauthorized'], 401);
        }

        $purchase->update($request->all());

        return response()->json($purchase->load(['boat', 'squidType']));
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(Purchase $purchase)
    {
        if (!$this->hasAccessToFarm($purchase->farm_id)) {
            return response()->json(['message' => 'Unauthorized'], 401);
        }

        $purchase->delete();

        return response()->json(null, 204);
    }
}
