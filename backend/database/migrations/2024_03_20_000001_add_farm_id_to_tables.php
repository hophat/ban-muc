<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // Thêm farm_id vào bảng users
        Schema::table('users', function (Blueprint $table) {
            $table->foreignId('farm_id')->nullable()->constrained('farms');
        });

        // Thêm farm_id vào các bảng khác
        $tables = [
            'purchases',
            'sales',
            'expenses',
            'boats',
            'customers',
            'squid_types',
        ];

        foreach ($tables as $table) {
            Schema::table($table, function (Blueprint $table) {
                $table->foreignId('farm_id')->nullable()->constrained('farms');
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        // Xóa farm_id từ bảng users
        Schema::table('users', function (Blueprint $table) {
            $table->dropForeign(['farm_id']);
            $table->dropColumn('farm_id');
        });

        // Xóa farm_id từ các bảng khác
        $tables = [
            'purchases',
            'sales',
            'expenses',
            'boats',
            'customers',
            'squid_types',
        ];

        foreach ($tables as $table) {
            Schema::table($table, function (Blueprint $table) {
                $table->dropForeign(['farm_id']);
                $table->dropColumn('farm_id');
            });
        }
    }
}; 