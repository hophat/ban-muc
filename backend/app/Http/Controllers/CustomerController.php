<?php

namespace App\Http\Controllers;

use App\Models\Customer;
use App\Traits\HasFarmAccess;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class CustomerController extends Controller
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

        $customers = Customer::where('farm_id', $farmId)
            ->orderBy('name')
            ->get();

        return response()->json($customers);
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
            'phone' => 'required|string|max:20',
            'address' => 'nullable|string',
            'description' => 'nullable|string',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $customer = Customer::create([
            'farm_id' => $farmId,
            'name' => $request->name,
            'phone' => $request->phone,
            'address' => $request->address,
            'description' => $request->description,
        ]);

        return response()->json($customer, 201);
    }

    /**
     * Display the specified resource.
     */
    public function show(Customer $customer)
    {
        if (!$this->hasAccessToFarm($customer->farm_id)) {
            return response()->json(['message' => 'Unauthorized'], 401);
        }

        return response()->json($customer->load(['sales' => function ($query) {
            $query->orderBy('sale_date', 'desc');
        }]));
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
    public function update(Request $request, Customer $customer)
    {
        if (!$this->hasAccessToFarm($customer->farm_id)) {
            return response()->json(['message' => 'Unauthorized'], 401);
        }

        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'phone' => 'required|string|max:20',
            'address' => 'nullable|string',
            'description' => 'nullable|string',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $customer->update($request->all());

        return response()->json($customer);
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(Customer $customer)
    {
        if (!$this->hasAccessToFarm($customer->farm_id)) {
            return response()->json(['message' => 'Unauthorized'], 401);
        }

        // Check if customer has any sales
        if ($customer->sales()->exists()) {
            return response()->json([
                'message' => 'Không thể xóa khách hàng này vì đã có giao dịch bán hàng',
            ], 422);
        }

        $customer->delete();

        return response()->json(null, 204);
    }
}
