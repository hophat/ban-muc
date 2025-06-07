<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\SquidTypeController;
use App\Http\Controllers\BoatController;
use App\Http\Controllers\CustomerController;
use App\Http\Controllers\PurchaseController;
use App\Http\Controllers\SaleController;
use App\Http\Controllers\ExpenseController;
use App\Http\Controllers\ReportController;
use App\Http\Controllers\FarmController;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
|
| Here is where you can register API routes for your application. These
| routes are loaded by the RouteServiceProvider and all of them will
| be assigned to the "api" middleware group. Make something great!
|
*/

// Test routes (no authentication)
Route::get('/test', function () {
    return ['message' => 'API đang hoạt động', 'status' => 'ok'];
});

Route::get('/simple', function () {
    return 'Hello World';
});

Route::get('/test-db', function () {
    try {
        $count = \App\Models\SquidType::count();
        return response()->json([
            'message' => 'Database kết nối thành công',
            'squid_types_count' => $count
        ]);
    } catch (\Exception $e) {
        return response()->json([
            'message' => 'Database lỗi',
            'error' => $e->getMessage()
        ], 500);
    }
});

// Authentication routes
Route::post('/login', [AuthController::class, 'login']);
Route::post('/register', [AuthController::class, 'registerAdmin']); // Public registration
// Route::post('/register', [AuthController::class, 'register']); // Public registration

// Protected routes
Route::middleware('auth:sanctum')->group(function () {
    // Auth routes
    Route::get('/user', [AuthController::class, 'user']);
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::post('/register-admin', [AuthController::class, 'registerAdmin']); // Admin only registration

    // User
    // Farm
    Route::apiResource('farms', FarmController::class);
    Route::get('/farm-setup', [FarmController::class, 'setup']);
    Route::post('/farms/{farm}/add-staff', [FarmController::class, 'addStaff']);
    Route::post('/farms/{farm}/remove-staff', [FarmController::class, 'removeStaff']);

    // Squid Types
    Route::apiResource('squid-types', SquidTypeController::class);

    // Boats
    Route::apiResource('boats', BoatController::class);

    // Customers
    Route::apiResource('customers', CustomerController::class);

    // Purchases
    Route::apiResource('purchases', PurchaseController::class);

    // Sales
    Route::apiResource('sales', SaleController::class);
    Route::patch('/sales/{sale}/payment-status', [SaleController::class, 'updatePaymentStatus']);

    // Expenses
    Route::apiResource('expenses', ExpenseController::class);
    Route::get('/expense-types', [ExpenseController::class, 'getExpenseTypes']);

    // Reports
    Route::prefix('reports')->group(function () {
        Route::get('/dashboard', [ReportController::class, 'dashboard']);
        Route::get('/revenue', [ReportController::class, 'revenue']);
        Route::get('/expenses', [ReportController::class, 'expenses']);
        Route::get('/profit', [ReportController::class, 'profit']);
        Route::get('/debts', [ReportController::class, 'debts']);
    });
}); 