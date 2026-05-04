<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Pet;
use App\Models\VaccinationRecord;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class PetController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        $pets = Pet::query()
            ->with(['vaccinationRecords' => fn ($query) => $query->orderByDesc('vaccination_date')->orderByDesc('id')])
            ->where('user_id', $user->id)
            ->get();

        return response()->json([
            'data' => $pets->map(fn ($pet) => $this->serializePet($pet)),
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $user = $request->user();

        $validated = $request->validate([
            'name' => ['required', 'string', 'max:100'],
            'animal_type' => ['required', 'string', 'max:50'],
            'breed' => ['nullable', 'string', 'max:100'],
            'age' => ['required', 'integer', 'min:0'],
            'gender' => ['required', 'in:male,female,unknown'],
            'rabies_status' => ['required', 'in:vaccinated,not_vaccinated,unknown'],
            'last_vaccination_date' => ['nullable', 'date'],
            'vaccine_name' => ['nullable', 'string', 'max:100'],
            'pet_photo' => ['nullable', 'image', 'max:5120'],
            'vaccination_card' => ['nullable', 'image', 'max:5120'],
        ]);

        if ($validated['rabies_status'] === 'vaccinated') {
            if (!$request->has('last_vaccination_date') || empty($validated['last_vaccination_date'])) {
                return response()->json(['message' => 'Vaccination date is required when rabies status is vaccinated.'], 422);
            }
            if (!$request->hasFile('vaccination_card')) {
                return response()->json(['message' => 'Vaccination card is required when rabies status is vaccinated.'], 422);
            }
        }

        $vaccinationCardPath = null;
        $petPhotoPath = null;

        if ($request->hasFile('pet_photo')) {
            $petPhotoPath = $request->file('pet_photo')->store('pet_photos', 'public');
        }

        if ($request->hasFile('vaccination_card')) {
            $file = $request->file('vaccination_card');
            $path = $file->store('vaccination_cards', 'public');
            $vaccinationCardPath = $path;
        }

        $pet = Pet::query()->create([
            'user_id' => $user->id,
            'name' => $validated['name'],
            'animal_type' => $validated['animal_type'],
            'breed' => $validated['breed'] ?? null,
            'age' => $validated['age'],
            'gender' => $validated['gender'],
            'rabies_status' => $validated['rabies_status'],
            'last_vaccination_date' => $validated['last_vaccination_date'] ?? null,
            'last_vaccine_name' => $validated['rabies_status'] === 'vaccinated' ? ($validated['vaccine_name'] ?? null) : null,
            'pet_photo_path' => $petPhotoPath,
            'vaccination_card_path' => $vaccinationCardPath,
        ]);

        if ($pet->rabies_status === 'vaccinated' && $pet->last_vaccination_date) {
            $pet->vaccinationRecords()->create([
                'vaccination_date' => $pet->last_vaccination_date,
                'vaccine_name' => $pet->last_vaccine_name,
                'vaccination_card_path' => $pet->vaccination_card_path,
            ]);
        }

        return response()->json([
            'data' => $this->serializePet($pet->load(['vaccinationRecords' => fn ($query) => $query->orderByDesc('vaccination_date')->orderByDesc('id')])),
            'message' => 'Pet registered successfully.',
        ], 201);
    }

    public function update(Request $request, Pet $pet): JsonResponse
    {
        $user = $request->user();

        if ($pet->user_id !== $user->id) {
            return response()->json(['message' => 'Unauthorized.'], 403);
        }

        $validated = $request->validate([
            'name' => ['required', 'string', 'max:100'],
            'animal_type' => ['required', 'string', 'max:50'],
            'breed' => ['nullable', 'string', 'max:100'],
            'age' => ['required', 'integer', 'min:0'],
            'gender' => ['required', 'in:male,female,unknown'],
            'rabies_status' => ['required', 'in:vaccinated,not_vaccinated,unknown'],
            'last_vaccination_date' => ['nullable', 'date'],
            'vaccine_name' => ['nullable', 'string', 'max:100'],
            'pet_photo' => ['nullable', 'image', 'max:5120'],
            'vaccination_card' => ['nullable', 'image', 'max:5120'],
        ]);

        if ($validated['rabies_status'] === 'vaccinated') {
            if (!$request->has('last_vaccination_date') || empty($validated['last_vaccination_date'])) {
                return response()->json(['message' => 'Vaccination date is required when rabies status is vaccinated.'], 422);
            }
        }

        if ($request->hasFile('pet_photo')) {
            if ($pet->pet_photo_path) {
                Storage::disk('public')->delete($pet->pet_photo_path);
            }
            $validated['pet_photo_path'] = $request->file('pet_photo')->store('pet_photos', 'public');
        }

        if ($request->hasFile('vaccination_card')) {
            if ($pet->vaccination_card_path) {
                Storage::disk('public')->delete($pet->vaccination_card_path);
            }
            $file = $request->file('vaccination_card');
            $path = $file->store('vaccination_cards', 'public');
            $validated['vaccination_card_path'] = $path;
        }

        $pet->update([
            'name' => $validated['name'],
            'animal_type' => $validated['animal_type'],
            'breed' => $validated['breed'] ?? $pet->breed,
            'age' => $validated['age'],
            'gender' => $validated['gender'],
            'rabies_status' => $validated['rabies_status'],
            'last_vaccination_date' => $validated['last_vaccination_date'] ?? $pet->last_vaccination_date,
            'last_vaccine_name' => $validated['rabies_status'] === 'vaccinated'
                ? (($validated['vaccine_name'] ?? $pet->last_vaccine_name))
                : null,
            'pet_photo_path' => $validated['pet_photo_path'] ?? $pet->pet_photo_path,
            'vaccination_card_path' => $validated['vaccination_card_path'] ?? $pet->vaccination_card_path,
        ]);

        return response()->json([
            'data' => $this->serializePet($pet->load(['vaccinationRecords' => fn ($query) => $query->orderByDesc('vaccination_date')->orderByDesc('id')])),
            'message' => 'Pet updated successfully.',
        ]);
    }

    public function destroy(Request $request, Pet $pet): JsonResponse
    {
        $user = $request->user();

        if ($pet->user_id !== $user->id) {
            return response()->json(['message' => 'Unauthorized.'], 403);
        }

        if ($pet->vaccination_card_path) {
            Storage::disk('public')->delete($pet->vaccination_card_path);
        }
        if ($pet->pet_photo_path) {
            Storage::disk('public')->delete($pet->pet_photo_path);
        }

        $pet->delete();

        return response()->json(['message' => 'Pet deleted successfully.']);
    }

    public function storeVaccination(Request $request, Pet $pet): JsonResponse
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

        $this->seedLegacyVaccinationRecord($pet);

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
        $vaccinationRecords = $pet->relationLoaded('vaccinationRecords')
            ? $pet->vaccinationRecords
            : $pet->vaccinationRecords()->orderByDesc('vaccination_date')->orderByDesc('id')->get();

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
            'vaccination_records' => $vaccinationRecords->map(
                fn (VaccinationRecord $record) => $this->serializeVaccinationRecord($record)
            )->values(),
            'created_at' => $pet->created_at,
            'updated_at' => $pet->updated_at,
        ];
    }

    private function serializeVaccinationRecord(VaccinationRecord $record): array
    {
        return [
            'id' => $record->id,
            'vaccination_date' => $record->vaccination_date?->format('Y-m-d'),
            'vaccine_name' => $record->vaccine_name,
            'vaccination_card_path' => $record->vaccination_card_path,
            'created_at' => $record->created_at,
            'updated_at' => $record->updated_at,
        ];
    }

    private function seedLegacyVaccinationRecord(Pet $pet): void
    {
        if ($pet->vaccinationRecords()->exists()) {
            return;
        }

        if (! $pet->last_vaccination_date && ! $pet->vaccination_card_path) {
            return;
        }

        $pet->vaccinationRecords()->create([
            'vaccination_date' => $pet->last_vaccination_date,
            'vaccine_name' => $pet->last_vaccine_name,
            'vaccination_card_path' => $pet->vaccination_card_path,
        ]);
    }
}
