<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Hash;
use Carbon\Carbon;
use App\Models\Farm;
use App\Models\ProductType;
use App\Models\Customer;
use App\Models\Purchase;
use App\Models\Sale;

class RecentDataSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $now = Carbon::now();
        $startDate = $now->copy()->subMonths(1)->startOfMonth();
        $endDate = $now->copy()->endOfMonth();
        $dates = [];
        // Lấy tất cả các ngày trong 2 tháng gần nhất
        for ($date = $startDate->copy(); $date->lte($endDate); $date->addDay()) {
            $dates[] = $date->copy();
        }

        $farms = Farm::all();
        foreach ($farms as $farm) {
            $productTypes = ProductType::where('farm_id', $farm->id)->get();
            $customers = Customer::where('farm_id', $farm->id)->get();
            if ($productTypes->isEmpty() || $customers->isEmpty()) continue;

            // Purchases
            for ($i = 0; $i < 20; $i++) {
                $purchaseDate = $dates[array_rand($dates)];
                $productType = $productTypes->random();
                $weight = rand(50, 300); // kg
                $unitPrice = rand(80000, 150000); // VND
                $totalAmount = $weight * $unitPrice;
                Purchase::create([
                    'farm_id' => $farm->id,
                    'product_type_id' => $productType->id,
                    'boat_id' => null, // hoặc random nếu có dữ liệu boat
                    'weight' => $weight,
                    'unit_price' => $unitPrice,
                    'total_amount' => $totalAmount,
                    'purchase_date' => $purchaseDate,
                    'notes' => 'Dữ liệu mẫu',
                ]);
            }

            // Sales
            for ($i = 0; $i < 20; $i++) {
                $saleDate = $dates[array_rand($dates)];
                $productType = $productTypes->random();
                $customer = $customers->random();
                $weight = rand(30, 200); // kg
                $unitPrice = rand(120000, 200000); // VND
                $totalAmount = $weight * $unitPrice;
                Sale::create([
                    'farm_id' => $farm->id,
                    'product_type_id' => $productType->id,
                    'customer_id' => $customer->id,
                    'weight' => $weight,
                    'unit_price' => $unitPrice,
                    'total_amount' => $totalAmount,
                    'sale_date' => $saleDate,
                    'payment_status' => 'paid',
                    'notes' => 'Dữ liệu mẫu',
                ]);
            }
        }
    }
} 