<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class AnimalReport extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'report_type',
        'animal_type',
        'location_text',
        'latitude',
        'longitude',
        'description',
        'image_path',
        'status',
    ];

    protected function casts(): array
    {
        return [
            'latitude' => 'decimal:8',
            'longitude' => 'decimal:8',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}