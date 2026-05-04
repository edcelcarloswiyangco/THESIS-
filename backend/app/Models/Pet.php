<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Pet extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'name',
        'animal_type',
        'breed',
        'age',
        'gender',
        'rabies_status',
        'last_vaccination_date',
        'last_vaccine_name',
        'pet_photo_path',
        'vaccination_card_path',
    ];

    protected $casts = [
        'last_vaccination_date' => 'date',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function vaccinationRecords(): HasMany
    {
        return $this->hasMany(VaccinationRecord::class)->orderByDesc('vaccination_date')->orderByDesc('id');
    }
}
