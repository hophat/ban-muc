<?php

namespace App\Http\Controllers;

use App\Models\Expense;
use App\Traits\HasFarmAccess;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class ExpenseController extends Controller
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

        $expenses = Expense::where('farm_id', $farmId)
            ->orderBy('expense_date', 'desc')
            ->get();

        return response()->json($expenses);
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
            'expense_type' => 'required|string',
            'amount' => 'required|numeric|min:0',
            'expense_date' => 'required|date',
            'notes' => 'nullable|string',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $expense = Expense::create([
            'farm_id' => $farmId,
            'expense_type' => $request->expense_type,
            'amount' => $request->amount,
            'expense_date' => $request->expense_date,
            'notes' => $request->notes,
        ]);

        return response()->json($expense, 201);
    }

    /**
     * Display the specified resource.
     */
    public function show(Expense $expense)
    {
        if (!$this->hasAccessToFarm($expense->farm_id)) {
            return response()->json(['message' => 'Unauthorized'], 401);
        }

        return response()->json($expense);
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
    public function update(Request $request, Expense $expense)
    {
        if (!$this->hasAccessToFarm($expense->farm_id)) {
            return response()->json(['message' => 'Unauthorized'], 401);
        }

        $validator = Validator::make($request->all(), [
            'expense_type' => 'required|string',
            'amount' => 'required|numeric|min:0',
            'expense_date' => 'required|date',
            'notes' => 'nullable|string',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $expense->update($request->all());

        return response()->json($expense);
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(Expense $expense)
    {
        if (!$this->hasAccessToFarm($expense->farm_id)) {
            return response()->json(['message' => 'Unauthorized'], 401);
        }

        $expense->delete();

        return response()->json(null, 204);
    }

    /**
     * Get expense types for dropdown
     */
    public function getExpenseTypes()
    {
        $expenseTypes = Expense::select('expense_type')
            ->distinct()
            ->orderBy('expense_type')
            ->pluck('expense_type');

        return response()->json($expenseTypes);
    }
}
