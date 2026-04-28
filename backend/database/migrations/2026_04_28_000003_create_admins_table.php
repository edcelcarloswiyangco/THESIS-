<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('admins', function (Blueprint $table) {
            $table->id('admin_id');
            $table->string('email', 100)->unique();
            $table->string('password', 255);
            $table->rememberToken();
            $table->timestamps();
        });

        if (Schema::hasTable('users') && Schema::hasColumn('users', 'is_admin')) {
            $adminRows = DB::table('users')
                ->where('is_admin', true)
                ->select('email', 'password', 'created_at', 'updated_at')
                ->get();

            foreach ($adminRows as $row) {
                DB::table('admins')->updateOrInsert(
                    ['email' => $row->email],
                    [
                        'password' => $row->password,
                        'created_at' => $row->created_at,
                        'updated_at' => $row->updated_at,
                    ]
                );
            }
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('admins');
    }
};
