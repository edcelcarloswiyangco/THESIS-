<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('pets', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->onDelete('cascade');
            $table->string('name', 100);
            $table->string('animal_type', 50);
            $table->string('breed', 100)->nullable();
            $table->integer('age');
            $table->enum('gender', ['male', 'female', 'unknown']);
            $table->enum('rabies_status', ['vaccinated', 'not_vaccinated', 'unknown']);
            $table->date('last_vaccination_date')->nullable();
            $table->string('vaccination_card_path')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('pets');
    }
};
