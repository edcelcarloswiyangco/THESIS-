<?php

namespace Database\Seeders;

use App\Models\Pet;
use App\Models\User;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class PetSeeder extends Seeder
{
    use WithoutModelEvents;

    /**
     * Seed the pets table with sample data.
     */
    public function run(): void
    {
        $users = User::all();

        if ($users->isEmpty()) {
            return; // No users to create pets for
        }

        $petData = [
            [
                'name' => 'Buddy',
                'animal_type' => 'dog',
                'breed' => 'Golden Retriever',
                'age' => '3 years',
                'gender' => 'male',
                'rabies_status' => 'vaccinated',
                'last_vaccination_date' => now()->subMonths(3),
                'last_vaccine_name' => 'Rabies Vaccine',
            ],
            [
                'name' => 'Whiskers',
                'animal_type' => 'cat',
                'breed' => 'Siamese',
                'age' => '2 years',
                'gender' => 'female',
                'rabies_status' => 'vaccinated',
                'last_vaccination_date' => now()->subMonths(6),
                'last_vaccine_name' => 'Rabies Vaccine',
            ],
            [
                'name' => 'Max',
                'animal_type' => 'dog',
                'breed' => 'Labrador',
                'age' => '5 years',
                'gender' => 'male',
                'rabies_status' => 'not_vaccinated',
                'last_vaccination_date' => null,
                'last_vaccine_name' => null,
            ],
            [
                'name' => 'Luna',
                'animal_type' => 'cat',
                'breed' => 'Persian',
                'age' => '4 years',
                'gender' => 'female',
                'rabies_status' => 'vaccinated',
                'last_vaccination_date' => now()->subMonths(2),
                'last_vaccine_name' => 'Rabies Vaccine',
            ],
            [
                'name' => 'Rex',
                'animal_type' => 'dog',
                'breed' => 'German Shepherd',
                'age' => '1 year',
                'gender' => 'male',
                'rabies_status' => 'not_vaccinated',
                'last_vaccination_date' => null,
                'last_vaccine_name' => null,
            ],
            [
                'name' => 'Muffin',
                'animal_type' => 'rabbit',
                'breed' => 'Holland Lop',
                'age' => '6 months',
                'gender' => 'female',
                'rabies_status' => 'unknown',
                'last_vaccination_date' => null,
                'last_vaccine_name' => null,
            ],
            [
                'name' => 'Spike',
                'animal_type' => 'dog',
                'breed' => 'Bulldog',
                'age' => '2 years',
                'gender' => 'male',
                'rabies_status' => 'vaccinated',
                'last_vaccination_date' => now()->subMonths(1),
                'last_vaccine_name' => 'Rabies Vaccine',
            ],
            [
                'name' => 'Mittens',
                'animal_type' => 'cat',
                'breed' => null,
                'age' => '7 years',
                'gender' => 'male',
                'rabies_status' => 'unknown',
                'last_vaccination_date' => null,
                'last_vaccine_name' => null,
            ],
        ];

        foreach ($petData as $data) {
            Pet::create(array_merge($data, ['user_id' => $users->random()->id]));
        }
    }
}
