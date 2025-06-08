<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\ProductType;
use App\Models\Customer;
use App\Models\Farm;

class DefaultDataSeeder extends Seeder
{
    public function run()
    {
        // Thêm loại hàng mặc định
        $productTypes = [
            [
                'name' => 'Mực ống',
                'description' => 'Mực ống tươi sống',
                'unit' => 'kg',
            ],
            [
                'name' => 'Mực nang',
                'description' => 'Mực nang tươi sống',
                'unit' => 'kg',
            ],
            [
                'name' => 'Mực lá',
                'description' => 'Mực lá tươi sống',
                'unit' => 'kg',
            ],
        ];

        // Thêm khách hàng mặc định
        $customers = [
            [
                'name' => 'Nhà hàng Hải Sản Xanh',
                'phone' => '0123456789',
                'address' => '123 Đường Biển, Quận 1, TP.HCM',
                'description' => 'Nhà hàng chuyên về hải sản',
            ],
            [
                'name' => 'Công ty Thực Phẩm Sạch',
                'phone' => '0987654321',
                'address' => '456 Đường Thủy Sản, Quận 4, TP.HCM',
                'description' => 'Công ty phân phối thực phẩm',
            ],
            [
                'name' => 'Chợ Hải Sản Trung Tâm',
                'phone' => '0369852147',
                'address' => '789 Đường Chợ, Quận 5, TP.HCM',
                'description' => 'Chợ đầu mối hải sản',
            ],
        ];

        // Lấy tất cả các trang trại
        $farms = Farm::all();

        foreach ($farms as $farm) {
            // Thêm loại hàng cho từng trang trại
            foreach ($productTypes as $type) {
                ProductType::create([
                    'name' => $type['name'],
                    'description' => $type['description'],
                    'unit' => $type['unit'],
                    'farm_id' => $farm->id,
                ]);
            }

            // Thêm khách hàng cho từng trang trại
            foreach ($customers as $customer) {
                Customer::create([
                    'name' => $customer['name'],
                    'phone' => $customer['phone'],
                    'address' => $customer['address'],
                    'description' => $customer['description'],
                    'farm_id' => $farm->id,
                ]);
            }
        }
    }
} 