<?php

namespace Database\Seeders;

use App\Models\User;
use App\Models\SquidType;
use App\Models\Boat;
use App\Models\Customer;
use App\Models\Purchase;
use App\Models\Sale;
use App\Models\Expense;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use Carbon\Carbon;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        // Create admin user
        User::create([
            'name' => 'Admin',
            'email' => 'admin@banmuc.com',
            'password' => Hash::make('admin123'),
            'role' => 'admin',
        ]);

        // Create staff user
        User::create([
            'name' => 'Nhân viên',
            'email' => 'staff@banmuc.com',
            'password' => Hash::make('staff123'),
            'role' => 'staff',
        ]);

        // Create squid types
        $squidTypes = [
            ['name' => 'hàng ống lớn', 'description' => 'hàng ống kích thước lớn, chất lượng cao'],
            ['name' => 'hàng ống nhỏ', 'description' => 'hàng ống kích thước nhỏ, phù hợp chế biến'],
            ['name' => 'hàng nang', 'description' => 'hàng nang tươi ngon'],
            ['name' => 'hàng khô', 'description' => 'hàng được sấy khô bảo quản'],
        ];

        foreach ($squidTypes as $type) {
            SquidType::create($type);
        }

        // Create boats
        $boats = [
            ['name' => 'Bình Minh 01', 'owner_name' => 'Nguyễn Văn A', 'phone' => '0901234567'],
            ['name' => 'Thuận Buồm 02', 'owner_name' => 'Trần Văn B', 'phone' => '0901234568'],
            ['name' => 'Hải Phong 03', 'owner_name' => 'Lê Văn C', 'phone' => '0901234569'],
            ['name' => 'Vượng Phát 04', 'owner_name' => 'Phạm Văn D', 'phone' => '0901234570'],
        ];

        foreach ($boats as $boat) {
            Boat::create($boat);
        }

        // Create customers
        $customers = [
            ['name' => 'Công ty TNHH Hải Sản Miền Nam', 'phone' => '0281234567', 'address' => 'TP.HCM'],
            ['name' => 'Chợ Hải Sản Bến Thành', 'phone' => '0281234568', 'address' => 'Quận 1, TP.HCM'],
            ['name' => 'Nhà hàng Hải Sản Tươi Sống', 'phone' => '0281234569', 'address' => 'Quận 3, TP.HCM'],
            ['name' => 'Công ty CP Xuất Khẩu Thủy Sản', 'phone' => '0281234570', 'address' => 'Bình Dương'],
        ];

        foreach ($customers as $customer) {
            Customer::create($customer);
        }

        // Create sample purchases (last 30 days)
        for ($i = 0; $i < 20; $i++) {
            Purchase::create([
                'boat_id' => rand(1, 4),
                'squid_type_id' => rand(1, 4),
                'weight' => rand(50, 500),
                'unit_price' => rand(80000, 150000),
                'purchase_date' => Carbon::now()->subDays(rand(0, 30)),
                'notes' => 'Mua từ ghe ' . ['Bình Minh 01', 'Thuận Buồm 02', 'Hải Phong 03', 'Vượng Phát 04'][rand(0, 3)],
            ]);
        }

        // Create sample sales (last 30 days)
        for ($i = 0; $i < 15; $i++) {
            Sale::create([
                'customer_id' => rand(1, 4),
                'squid_type_id' => rand(1, 4),
                'weight' => rand(30, 300),
                'unit_price' => rand(100000, 200000),
                'sale_date' => Carbon::now()->subDays(rand(0, 30)),
                'payment_status' => rand(0, 1) ? 'paid' : 'unpaid',
                'notes' => 'Bán cho khách hàng',
            ]);
        }

        // Create sample expenses (last 30 days)
        $expenseTypes = ['Xăng dầu', 'Đá lạnh', 'Vận chuyển', 'Bảo quản', 'Nhân công'];
        for ($i = 0; $i < 25; $i++) {
            Expense::create([
                'expense_type' => $expenseTypes[rand(0, 4)],
                'amount' => rand(100000, 2000000),
                'expense_date' => Carbon::now()->subDays(rand(0, 30)),
                'notes' => 'Chi phí hoạt động hàng ngày',
            ]);
        }

        $this->call(RecentDataSeeder::class);
    }
}
