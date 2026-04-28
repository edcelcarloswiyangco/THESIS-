<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\AnimalReport;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class ReportController extends Controller
{
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'report_type' => ['required', 'string', 'max:50'],
            'animal_type' => ['required', 'string', 'max:100'],
            'location_text' => ['required', 'string', 'max:255'],
            'latitude' => ['nullable', 'numeric'],
            'longitude' => ['nullable', 'numeric'],
            'description' => ['required', 'string'],
            'image' => ['required', 'image', 'max:5120'],
        ]);

        $path = $request->file('image')->store('reports', 'public');

        $report = AnimalReport::query()->create([
            'user_id' => $request->user()->id,
            'report_type' => $validated['report_type'],
            'animal_type' => $validated['animal_type'],
            'location_text' => $validated['location_text'],
            'latitude' => $validated['latitude'] ?? null,
            'longitude' => $validated['longitude'] ?? null,
            'description' => $validated['description'],
            'image_path' => $path,
            'status' => 'pending',
        ]);

        return response()->json([
            'message' => 'Report submitted successfully.',
            'data' => [
                'id' => $report->id,
                'report_type' => $report->report_type,
                'animal_type' => $report->animal_type,
                'location_text' => $report->location_text,
                'latitude' => $report->latitude,
                'longitude' => $report->longitude,
                'description' => $report->description,
                'image_path' => $report->image_path,
                'status' => $report->status,
            ],
        ], 201);
    }
}