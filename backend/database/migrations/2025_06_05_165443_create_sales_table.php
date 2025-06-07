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
        Schema::create('sales', function (Blueprint $table) {
            $table->id();
            $table->foreignId('customer_id')->constrained()->onDelete('cascade');
            $table->foreignId('squid_type_id')->constrained()->onDelete('cascade');
            $table->decimal('weight', 10, 2); // kg
            $table->decimal('unit_price', 15, 2); // giá/kg
            $table->decimal('total_amount', 15, 2); // tổng tiền
            $table->date('sale_date');
            $table->enum('payment_status', ['paid', 'unpaid'])->default('unpaid');
            $table->text('notes')->nullable();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('sales');
    }
};
