<?php

namespace App\Http\Controllers;

use App\Models\User;
use App\Models\Farm;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;
use Illuminate\Support\Facades\DB;

class AuthController extends Controller
{
    /**
     * Login user
     */
    public function login(Request $request)
    {
        $request->validate([
            'phone' => 'required|string',
            'password' => 'required|string|min:6',
        ]);

        $user = User::where('phone', $request->phone)->first();

        if (!$user || !Hash::check($request->password, $user->password)) {
            throw ValidationException::withMessages([
                'phone' => ['Số điện thoại hoặc mật khẩu không chính xác.'],
            ]);
        }

        // Lấy thông tin farm của user
        $farm = Farm::find($user->farm_id);

        // Thêm thông tin farm vào user
        $user->farm = $farm;

        $token = $user->createToken('banmuc-token')->plainTextToken;

        return response()->json([
            'user' => $user,
            'token' => $token,
        ]);
    }

    /**
     * Logout user
     */
    public function logout(Request $request)
    {
        $request->user()->tokens()->delete();

        return response()->json([
            'message' => 'Đăng xuất thành công',
        ]);
    }

    /**
     * Get current user
     */
    public function user(Request $request)
    {
        return response()->json($request->user());
    }

    /**
     * Register new user (admin only)
     */
    public function registerAdmin(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:users',
            'phone' => 'required|string|max:255|unique:users',
            'password' => 'required|string|min:6|confirmed',
            'farm_name' => 'required|string|max:255',
            'farm_address' => 'required|string|max:255',
            'farm_phone' => 'required|string|max:255',
            'farm_description' => 'nullable|string',
        ]);
        
        DB::beginTransaction();
        try {
            $user = User::create([
                'name' => $request->name,
                'email' => $request->email,
                'phone' => $request->phone,
                'password' => Hash::make($request->password),
                'role' => 'admin',
                'farm_id' => null,
            ]);

            $farm = Farm::create([
                'name' => $request->farm_name,
                'address' => $request->farm_address,
                'phone' => $request->farm_phone,
                'description' => $request->farm_description,
                'status' => 'active',
                'owner_id' => $user->id,
            ]);

            $user->farm_id = $farm->id;
            $user->save();

            DB::commit();
        } catch (\Exception $e) {
            DB::rollBack();
            throw $e;
        }


        return response()->json([
            'message' => 'Tạo tài khoản và trang trại thành công',
            'user' => $user,
            'farm' => $farm,
        ], 201);
    }

    /**
     * Register new user (public)
     */
    public function register(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:users',
            'password' => 'required|string|min:6|confirmed',
            'farm_name' => 'required|string|max:255',
            'farm_address' => 'required|string|max:255',
            'farm_phone' => 'required|string|max:255',
            'farm_description' => 'required|string|max:255',
        ]);

        $user = User::create([
            'name' => $request->name,
            'email' => $request->email,
            'password' => Hash::make($request->password),
            'role' => 'user', // Mặc định là user thông thường
            'farm_name' => $request->farm_name,
            'farm_address' => $request->farm_address,
            'farm_phone' => $request->farm_phone,
            'farm_description' => $request->farm_description,
        ]);

        // Tự động đăng nhập sau khi đăng ký
        $token = $user->createToken('banmuc-token')->plainTextToken;

        return response()->json([
            'message' => 'Đăng ký tài khoản thành công',
            'user' => $user,
            'token' => $token,
        ], 201);
    }
}
