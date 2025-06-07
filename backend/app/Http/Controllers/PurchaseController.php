<?php

namespace App\Http\Controllers;

use App\Models\Purchase;
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

        // Verify boat belongs to the farm
        if (!$this->hasAccessToFarm($request->boat->farm_id)) {
            return response()->json(['message' => 'Unauthorized'], 401);
        }

        // Verify squid type belongs to the farm
        if (!$this->hasAccessToFarm($request->squidType->farm_id)) {
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
        //
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

        // Verify boat belongs to the farm
        if (!$this->hasAccessToFarm($request->boat->farm_id)) {
            return response()->json(['message' => 'Unauthorized'], 401);
        }

        // Verify squid type belongs to the farm
        if (!$this->hasAccessToFarm($request->squidType->farm_id)) {
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
