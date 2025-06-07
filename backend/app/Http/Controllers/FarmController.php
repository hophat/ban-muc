<?php

namespace App\Http\Controllers;

use App\Models\Farm;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Validation\ValidationException;

class FarmController extends Controller
{
    /**
     * Hiển thị danh sách các trại
     */
    public function index()
    {
        $farms = Farm::with('owner')->get();
        return response()->json($farms);
    }

    /**
     * Tạo trại mới
     */
    public function setup(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'address' => 'required|string|max:255',
            'phone' => 'required|string|max:255',
            'description' => 'required|string',
        ]);

        // Chỉ admin mới được tạo trại
        if (Auth::user()->role !== 'admin') {
            throw ValidationException::withMessages([
                'role' => ['Bạn không có quyền tạo trại.'],
            ]);
        }

        $farm = Farm::create([
            'name' => $request->name,
            'address' => $request->address,
            'phone' => $request->phone,
            'description' => $request->description,
            'owner_id' => Auth::id(),
            'status' => 'active',
        ]);

        return response()->json([
            'message' => 'Tạo trại thành công',
            'farm' => $farm,
        ], 201);
    }

    /**
     * Hiển thị thông tin chi tiết trại
     */
    public function show(Farm $farm)
    {
        $farm->load(['owner', 'staff']);
        return response()->json($farm);
    }

    /**
     * Cập nhật thông tin trại
     */
    public function update(Request $request, Farm $farm)
    {
        // Kiểm tra quyền
        if (Auth::user()->role !== 'admin' || Auth::id() !== $farm->owner_id) {
            throw ValidationException::withMessages([
                'role' => ['Bạn không có quyền cập nhật thông tin trại này.'],
            ]);
        }

        $request->validate([
            'name' => 'required|string|max:255',
            'address' => 'required|string|max:255',
            'phone' => 'required|string|max:255',
            'description' => 'required|string',
            'status' => 'required|in:active,inactive',
        ]);

        $farm->update($request->all());

        return response()->json([
            'message' => 'Cập nhật thông tin trại thành công',
            'farm' => $farm,
        ]);
    }

    /**
     * Xóa trại
     */
    public function destroy(Farm $farm)
    {
        // Kiểm tra quyền
        if (Auth::user()->role !== 'admin' || Auth::id() !== $farm->owner_id) {
            throw ValidationException::withMessages([
                'role' => ['Bạn không có quyền xóa trại này.'],
            ]);
        }

        $farm->delete();

        return response()->json([
            'message' => 'Xóa trại thành công',
        ]);
    }

    /**
     * Thêm nhân viên vào trại
     */
    public function addStaff(Request $request, Farm $farm)
    {
        // Kiểm tra quyền
        if (Auth::user()->role !== 'admin' || Auth::id() !== $farm->owner_id) {
            throw ValidationException::withMessages([
                'role' => ['Bạn không có quyền thêm nhân viên vào trại này.'],
            ]);
        }

        $request->validate([
            'user_id' => 'required|exists:users,id',
        ]);

        $user = User::findOrFail($request->user_id);
        
        // Kiểm tra xem user có phải là staff không
        if (!$user->isStaff()) {
            throw ValidationException::withMessages([
                'user_id' => ['Người dùng này không phải là nhân viên.'],
            ]);
        }

        // Cập nhật farm_id cho user
        $user->update(['farm_id' => $farm->id]);

        return response()->json([
            'message' => 'Thêm nhân viên vào trại thành công',
            'staff' => $user,
        ]);
    }

    /**
     * Xóa nhân viên khỏi trại
     */
    public function removeStaff(Request $request, Farm $farm)
    {
        // Kiểm tra quyền
        if (Auth::user()->role !== 'admin' || Auth::id() !== $farm->owner_id) {
            throw ValidationException::withMessages([
                'role' => ['Bạn không có quyền xóa nhân viên khỏi trại này.'],
            ]);
        }

        $request->validate([
            'user_id' => 'required|exists:users,id',
        ]);

        $user = User::findOrFail($request->user_id);
        
        // Kiểm tra xem user có thuộc trại này không
        if ($user->farm_id !== $farm->id) {
            throw ValidationException::withMessages([
                'user_id' => ['Nhân viên này không thuộc trại của bạn.'],
            ]);
        }

        // Xóa farm_id của user
        $user->update(['farm_id' => null]);

        return response()->json([
            'message' => 'Xóa nhân viên khỏi trại thành công',
        ]);
    }
}
