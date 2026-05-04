<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Pet;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PetVaccinationController extends Controller
{
    public function store(Request $request, Pet $pet): JsonResponse
    {
        $user = $request->user();

        if ($pet->user_id !== $user->id) {
            return response()->json(['message' => 'Unauthorized.'], 403);
        }

        $validated = $request->validate([
            'vaccination_date' => ['required', 'date'],
            'vaccine_name' => ['nullable', 'string', 'max:100'],
            'vaccination_card' => ['required', 'image', 'max:5120'],
        ]);

        if (! $pet->vaccinationRecords()->exists() && ($pet->last_vaccination_date || $pet->vaccination_card_path)) {
            $pet->vaccinationRecords()->create([
                'vaccination_date' => $pet->last_vaccination_date,
                'vaccine_name' => $pet->last_vaccine_name,
                'vaccination_card_path' => $pet->vaccination_card_path,
            ]);
        }

        $cardPath = $request->file('vaccination_card')->store('vaccination_cards', 'public');

        $pet->vaccinationRecords()->create([
            'vaccination_date' => $validated['vaccination_date'],
            'vaccine_name' => $validated['vaccine_name'] ?? null,
            'vaccination_card_path' => $cardPath,
        ]);

        $pet->update([
            'rabies_status' => 'vaccinated',
            'last_vaccination_date' => $validated['vaccination_date'],
            'last_vaccine_name' => $validated['vaccine_name'] ?? null,
            'vaccination_card_path' => $cardPath,
        ]);

        $pet->load(['vaccinationRecords' => fn ($query) => $query->orderByDesc('vaccination_date')->orderByDesc('id')]);

        return response()->json([
            'data' => $this->serializePet($pet),
            'message' => 'Vaccination record added successfully.',
        ], 201);
    }

    private function serializePet(Pet $pet): array
    {
        return [
            'id' => $pet->id,
            'name' => $pet->name,
            'animal_type' => $pet->animal_type,
            'breed' => $pet->breed,
            'age' => $pet->age,
            'gender' => $pet->gender,
            'rabies_status' => $pet->rabies_status,
            'last_vaccination_date' => $pet->last_vaccination_date?->format('Y-m-d'),
            'last_vaccine_name' => $pet->last_vaccine_name,
            'pet_photo_path' => $pet->pet_photo_path,
            'vaccination_card_path' => $pet->vaccination_card_path,
            'vaccination_records' => $pet->vaccinationRecords->map(fn ($record) => [
                'id' => $record->id,
                'vaccination_date' => $record->vaccination_date?->format('Y-m-d'),
                'vaccine_name' => $record->vaccine_name,
                'vaccination_card_path' => $record->vaccination_card_path,
                'created_at' => $record->created_at,
                'updated_at' => $record->updated_at,
            ])->values(),
            'created_at' => $pet->created_at,
            'updated_at' => $pet->updated_at,
        ];
    }
}