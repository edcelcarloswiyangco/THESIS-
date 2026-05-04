<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('pets', function (Blueprint $table) {
            if (! Schema::hasColumn('pets', 'last_vaccine_name')) {
                $table->string('last_vaccine_name')->nullable()->after('last_vaccination_date');
            }
        });

        Schema::table('vaccination_records', function (Blueprint $table) {
            if (! Schema::hasColumn('vaccination_records', 'vaccine_name')) {
                $table->string('vaccine_name')->nullable()->after('vaccination_date');
            }
        });
    }

    public function down(): void
    {
        Schema::table('vaccination_records', function (Blueprint $table) {
            if (Schema::hasColumn('vaccination_records', 'vaccine_name')) {
                $table->dropColumn('vaccine_name');
            }
        });

        Schema::table('pets', function (Blueprint $table) {
            if (Schema::hasColumn('pets', 'last_vaccine_name')) {
                $table->dropColumn('last_vaccine_name');
            }
        });
    }
};
