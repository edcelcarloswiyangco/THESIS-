<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            if (! Schema::hasColumn('users', 'full_name')) {
                $table->string('full_name', 100)->default('')->after('id');
            }

            if (! Schema::hasColumn('users', 'contact_number')) {
                $table->string('contact_number', 20)->default('')->after('password');
            }

            if (! Schema::hasColumn('users', 'address')) {
                $table->string('address', 255)->default('')->after('contact_number');
            }
        });

        if (Schema::hasColumn('users', 'name')) {
            DB::table('users')->where('full_name', '')->update([
                'full_name' => DB::raw('name'),
            ]);
        }

        Schema::table('users', function (Blueprint $table) {
            if (Schema::hasColumn('users', 'is_admin')) {
                $table->dropColumn('is_admin');
            }
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            if (! Schema::hasColumn('users', 'is_admin')) {
                $table->boolean('is_admin')->default(false)->after('password');
            }

            if (Schema::hasColumn('users', 'address')) {
                $table->dropColumn('address');
            }

            if (Schema::hasColumn('users', 'contact_number')) {
                $table->dropColumn('contact_number');
            }

            if (Schema::hasColumn('users', 'full_name')) {
                $table->dropColumn('full_name');
            }
        });
    }
};
