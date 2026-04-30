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
        Schema::table('animal_reports', function (Blueprint $table) {
            // Columns already exist in create_animal_reports_table migration
            // $table->string('video_path')->nullable()->after('image_path');
            // $table->timestamp('resolved_at')->nullable()->after('status');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('animal_reports', function (Blueprint $table) {
            // $table->dropColumn(['video_path', 'resolved_at']);
        });
    }
};
