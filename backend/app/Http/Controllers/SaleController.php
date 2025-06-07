<?php

namespace App\Http\Controllers;

use App\Models\Sale;
use App\Traits\HasFarmAccess;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class SaleController extends Controller
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

        $sales = Sale::with(['customer', 'squidType'])
            ->where('farm_id', $farmId)
            ->orderBy('sale_date', 'desc')
            ->get();

        return response()->json($sales);
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
            'customer_id' => 'required|exists:customers,id',
            'squid_type_id' => 'required|exists:squid_types,id',
            'weight' => 'required|numeric|min:0',
            'unit_price' => 'required|numeric|min:0',
            'sale_date' => 'required|date',
            'payment_status' => 'required|in:paid,unpaid',
            'notes' => 'nullable|string',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        // Verify customer belongs to the farm
        if (!$this->hasAccessToFarm($request->customer->farm_id)) {
            return response()->json(['message' => 'Unauthorized'], 401);
        }

        // Verify squid type belongs to the farm
        if (!$this->hasAccessToFarm($request->squidType->farm_id)) {
            return response()->json(['message' => 'Unauthorized'], 401);
        }

        $sale = Sale::create([
            'farm_id' => $farmId,
            'customer_id' => $request->customer_id,
            'squid_type_id' => $request->squid_type_id,
            'weight' => $request->weight,
            'unit_price' => $request->unit_price,
            'sale_date' => $request->sale_date,
            'payment_status' => $request->payment_status,
            'notes' => $request->notes,
        ]);

        return response()->json($sale->load(['customer', 'squidType']), 201);
    }

    /**
     * Display the specified resource.
     */
    public function show(Sale $sale)
    {
        if (!$this->hasAccessToFarm($sale->farm_id)) {
            return response()->json(['message' => 'Unauthorized'], 401);
        }

        return response()->json($sale->load(['customer', 'squidType']));
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
    public function update(Request $request, Sale $sale)
    {
        if (!$this->hasAccessToFarm($sale->farm_id)) {
            return response()->json(['message' => 'Unauthorized'], 401);
        }

        $validator = Validator::make($request->all(), [
            'customer_id' => 'required|exists:customers,id',
            'squid_type_id' => 'required|exists:squid_types,id',
            'weight' => 'required|numeric|min:0',
            'unit_price' => 'required|numeric|min:0',
            'sale_date' => 'required|date',
            'payment_status' => 'required|in:paid,unpaid',
            'notes' => 'nullable|string',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        // Verify customer belongs to the farm
        if (!$this->hasAccessToFarm($request->customer->farm_id)) {
            return response()->json(['message' => 'Unauthorized'], 401);
        }

        // Verify squid type belongs to the farm
        if (!$this->hasAccessToFarm($request->squidType->farm_id)) {
            return response()->json(['message' => 'Unauthorized'], 401);
        }

        $sale->update($request->all());

        return response()->json($sale->load(['customer', 'squidType']));
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(Sale $sale)
    {
        if (!$this->hasAccessToFarm($sale->farm_id)) {
            return response()->json(['message' => 'Unauthorized'], 401);
        }

        $sale->delete();

        return response()->json(null, 204);
    }

    /**
     * Update payment status
     */
    public function updatePaymentStatus(Request $request, Sale $sale)
    {
        $request->validate([
            'payment_status' => 'required|in:paid,unpaid',
        ]);

        $sale->update(['payment_status' => $request->payment_status]);

        return response()->json([
            'message' => 'Trạng thái thanh toán đã được cập nhật',
            'sale' => $sale,
        ]);
    }
}
