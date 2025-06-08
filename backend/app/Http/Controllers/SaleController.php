<?php

namespace App\Http\Controllers;

use App\Models\Sale;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Auth;
use Illuminate\Validation\ValidationException;

class SaleController extends Controller
{
    public function index()
    {
        try {
            $sales = Sale::with(['customer', 'squidType'])
                ->where('farm_id', Auth::user()->farm_id)
                ->orderBy('sale_date', 'desc')
                ->get();

            return response()->json($sales);
        } catch (\Exception $e) {
            Log::error('Error fetching sales: ' . $e->getMessage());
            return response()->json(['message' => 'Lỗi khi lấy danh sách giao dịch'], 500);
        }
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
        try {
            $request->validate([
                'customer_id' => 'required|exists:customers,id',
                'squid_type_id' => 'required|exists:squid_types,id',
                'weight' => 'required|numeric|min:0',
                'unit_price' => 'required|numeric|min:0',
                'sale_date' => 'required|date',
                'payment_status' => 'required|in:paid,unpaid,partial',
                'notes' => 'nullable|string',
            ]);

            DB::beginTransaction();

            $sale = Sale::create([
                'customer_id' => $request->customer_id,
                'squid_type_id' => $request->squid_type_id,
                'weight' => $request->weight,
                'unit_price' => $request->unit_price,
                'total_amount' => $request->weight * $request->unit_price,
                'sale_date' => $request->sale_date,
                'payment_status' => $request->payment_status,
                'notes' => $request->notes,
                'farm_id' => Auth::user()->farm_id,
            ]);

            DB::commit();

            return response()->json([
                'message' => 'Thêm giao dịch bán thành công',
                'sale' => $sale->load(['customer', 'squidType']),
            ], 201);
        } catch (ValidationException $e) {
            return response()->json([
                'message' => 'Dữ liệu không hợp lệ',
                'errors' => $e->errors(),
            ], 422);
        } catch (\Exception $e) {
            DB::rollBack();
            Log::error('Error creating sale: ' . $e->getMessage());
            return response()->json(['message' => 'Lỗi khi thêm giao dịch'], 500);
        }
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
        try {
            // Kiểm tra quyền truy cập
            if ($sale->farm_id !== Auth::user()->farm_id) {
                return response()->json(['message' => 'Không có quyền cập nhật giao dịch này'], 403);
            }

            $request->validate([
                'customer_id' => 'sometimes|required|exists:customers,id',
                'squid_type_id' => 'sometimes|required|exists:squid_types,id',
                'weight' => 'sometimes|required|numeric|min:0',
                'unit_price' => 'sometimes|required|numeric|min:0',
                'sale_date' => 'sometimes|required|date',
                'payment_status' => 'sometimes|required|in:paid,unpaid,partial',
                'notes' => 'nullable|string',
            ]);

            DB::beginTransaction();

            // Cập nhật các trường được cung cấp
            $updateData = $request->only([
                'customer_id',
                'squid_type_id',
                'weight',
                'unit_price',
                'sale_date',
                'payment_status',
                'notes',
            ]);

            // Nếu có cập nhật weight hoặc unit_price, tính lại total_amount
            if (isset($updateData['weight']) || isset($updateData['unit_price'])) {
                $weight = $updateData['weight'] ?? $sale->weight;
                $unitPrice = $updateData['unit_price'] ?? $sale->unit_price;
                $updateData['total_amount'] = $weight * $unitPrice;
            }

            $sale->update($updateData);

            DB::commit();

            return response()->json([
                'message' => 'Cập nhật giao dịch thành công',
                'sale' => $sale->fresh(['customer', 'squidType']),
            ]);
        } catch (ValidationException $e) {
            return response()->json([
                'message' => 'Dữ liệu không hợp lệ',
                'errors' => $e->errors(),
            ], 422);
        } catch (\Exception $e) {
            DB::rollBack();
            Log::error('Error updating sale: ' . $e->getMessage());
            return response()->json(['message' => 'Lỗi khi cập nhật giao dịch'], 500);
        }
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(Sale $sale)
    {
        try {
            // Kiểm tra quyền truy cập
            if ($sale->farm_id !== Auth::user()->farm_id) {
                return response()->json(['message' => 'Không có quyền xóa giao dịch này'], 403);
            }

            DB::beginTransaction();
            $sale->delete();
            DB::commit();

            return response()->json(['message' => 'Xóa giao dịch thành công']);
        } catch (\Exception $e) {
            DB::rollBack();
            Log::error('Error deleting sale: ' . $e->getMessage());
            return response()->json(['message' => 'Lỗi khi xóa giao dịch'], 500);
        }
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
