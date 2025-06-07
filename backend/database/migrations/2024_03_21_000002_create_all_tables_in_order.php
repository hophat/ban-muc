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
        // 1. Tạo bảng users trước (vì farms phụ thuộc vào users)
        Schema::create('users', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('email')->unique();
            $table->string('phone')->nullable();
            $table->timestamp('email_verified_at')->nullable();
            $table->string('password');
            $table->enum('role', ['admin', 'staff', 'user'])->default('user');
            $table->rememberToken();
            $table->timestamps();
        });

        // 2. Tạo bảng farms (vì các bảng khác phụ thuộc vào farms)
        Schema::create('farms', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('address')->nullable();
            $table->string('phone')->nullable();
            $table->foreignId('owner_id')->constrained('users');
            $table->text('description')->nullable();
            $table->enum('status', ['active', 'inactive'])->default('active');
            $table->timestamps();
        });

        // 3. Thêm farm_id vào bảng users
        Schema::table('users', function (Blueprint $table) {
            $table->foreignId('farm_id')->nullable()->after('role')->constrained('farms');
        });

        // 4. Tạo các bảng phụ thuộc vào farms
        Schema::create('squid_types', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->text('description')->nullable();
            $table->foreignId('farm_id')->nullable()->constrained('farms');
            $table->timestamps();
        });

        Schema::create('boats', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('owner_name');
            $table->string('phone')->nullable();
            $table->text('description')->nullable();
            $table->foreignId('farm_id')->nullable()->constrained('farms');
            $table->timestamps();
        });

        Schema::create('customers', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('phone')->nullable();
            $table->text('address')->nullable();
            $table->text('description')->nullable();
            $table->foreignId('farm_id')->nullable()->constrained('farms');
            $table->timestamps();
        });

        // 5. Tạo các bảng giao dịch (phụ thuộc vào boats, customers, squid_types)
        Schema::create('purchases', function (Blueprint $table) {
            $table->id();
            $table->foreignId('boat_id')->constrained()->onDelete('cascade');
            $table->foreignId('squid_type_id')->constrained()->onDelete('cascade');
            $table->decimal('weight', 10, 2); // kg
            $table->decimal('unit_price', 15, 2); // giá/kg
            $table->decimal('total_amount', 15, 2); // tổng tiền
            $table->date('purchase_date');
            $table->text('notes')->nullable();
            $table->foreignId('farm_id')->nullable()->constrained('farms');
            $table->timestamps();
        });

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
            $table->foreignId('farm_id')->nullable()->constrained('farms');
            $table->timestamps();
        });

        Schema::create('expenses', function (Blueprint $table) {
            $table->id();
            $table->string('expense_type'); // loại chi phí (xăng, đá, vận chuyển...)
            $table->decimal('amount', 15, 2); // số tiền
            $table->date('expense_date');
            $table->text('notes')->nullable();
            $table->foreignId('farm_id')->nullable()->constrained('farms');
            $table->timestamps();
        });

        // 6. Tạo các bảng hệ thống của Laravel
        Schema::create('password_reset_tokens', function (Blueprint $table) {
            $table->string('email')->primary();
            $table->string('token');
            $table->timestamp('created_at')->nullable();
        });

        Schema::create('sessions', function (Blueprint $table) {
            $table->string('id')->primary();
            $table->foreignId('user_id')->nullable()->index();
            $table->string('ip_address', 45)->nullable();
            $table->text('user_agent')->nullable();
            $table->longText('payload');
            $table->integer('last_activity')->index();
        });

        Schema::create('personal_access_tokens', function (Blueprint $table) {
            $table->id();
            $table->morphs('tokenable');
            $table->string('name');
            $table->string('token', 64)->unique();
            $table->text('abilities')->nullable();
            $table->timestamp('last_used_at')->nullable();
            $table->timestamp('expires_at')->nullable();
            $table->timestamps();
        });

        Schema::create('cache', function (Blueprint $table) {
            $table->string('key')->primary();
            $table->mediumText('value');
            $table->integer('expiration');
        });

        Schema::create('cache_locks', function (Blueprint $table) {
            $table->string('key')->primary();
            $table->string('owner');
            $table->integer('expiration');
        });

        Schema::create('jobs', function (Blueprint $table) {
            $table->id();
            $table->string('queue')->index();
            $table->longText('payload');
            $table->unsignedTinyInteger('attempts');
            $table->unsignedInteger('reserved_at')->nullable();
            $table->unsignedInteger('available_at');
            $table->unsignedInteger('created_at');
        });

        Schema::create('job_batches', function (Blueprint $table) {
            $table->string('id')->primary();
            $table->string('name');
            $table->integer('total_jobs');
            $table->integer('pending_jobs');
            $table->integer('failed_jobs');
            $table->longText('failed_job_ids');
            $table->mediumText('options')->nullable();
            $table->integer('cancelled_at')->nullable();
            $table->integer('created_at');
            $table->integer('finished_at')->nullable();
        });

        Schema::create('failed_jobs', function (Blueprint $table) {
            $table->id();
            $table->string('uuid')->unique();
            $table->text('connection');
            $table->text('queue');
            $table->longText('payload');
            $table->longText('exception');
            $table->timestamp('failed_at')->useCurrent();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        // Xóa theo thứ tự ngược lại để tránh lỗi khóa ngoại
        Schema::dropIfExists('failed_jobs');
        Schema::dropIfExists('job_batches');
        Schema::dropIfExists('jobs');
        Schema::dropIfExists('cache_locks');
        Schema::dropIfExists('cache');
        Schema::dropIfExists('personal_access_tokens');
        Schema::dropIfExists('sessions');
        Schema::dropIfExists('password_reset_tokens');
        Schema::dropIfExists('expenses');
        Schema::dropIfExists('sales');
        Schema::dropIfExists('purchases');
        Schema::dropIfExists('customers');
        Schema::dropIfExists('boats');
        Schema::dropIfExists('squid_types');
        Schema::table('users', function (Blueprint $table) {
            $table->dropForeign(['farm_id']);
            $table->dropColumn('farm_id');
        });
        Schema::dropIfExists('farms');
        Schema::dropIfExists('users');
    }
}; 