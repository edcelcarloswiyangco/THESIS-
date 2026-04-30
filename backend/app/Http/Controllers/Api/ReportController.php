<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\AnimalReport;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ReportController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $reports = AnimalReport::query()
            ->where('user_id', $request->user()->id)
            ->latest('id')
            ->get();

        return response()->json([
            'data' => $reports->map(function (AnimalReport $report) {
                $imagePaths = $report->image_paths;
                if (is_string($imagePaths)) {
                    $decoded = json_decode($imagePaths, true);
                    $imagePaths = is_array($decoded) ? $decoded : [$report->image_path];
                }

                return [
                    'id' => $report->id,
                    'report_type' => $report->report_type,
                    'animal_type' => $report->animal_type,
                    'location_text' => $report->location_text,
                    'latitude' => $report->latitude,
                    'longitude' => $report->longitude,
                    'description' => $report->description,
                    'image_path' => $report->image_path,
                    'image_paths' => $imagePaths ?? [$report->image_path],
                    'video_path' => $report->video_path,
                    'status' => $report->status,
                    'resolved_at' => optional($report->resolved_at)->toIso8601String(),
                    'created_at' => optional($report->created_at)->toIso8601String(),
                ];
            }),
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'report_type' => ['required', 'string', 'max:50'],
            'animal_type' => ['required', 'string', 'max:100'],
            'location_text' => ['required', 'string', 'max:255'],
            'latitude' => ['nullable', 'numeric'],
            'longitude' => ['nullable', 'numeric'],
            'description' => ['required', 'string'],
            'images' => ['required', 'array', 'min:1', 'max:5'],
            'images.*' => ['required', 'image', 'max:5120'],
            'video' => ['nullable', 'file', 'mimetypes:video/mp4,video/quicktime,video/x-msvideo,video/x-matroska', 'max:51200'],
        ]);

        $paths = [];
        foreach ($request->file('images', []) as $imageFile) {
            $paths[] = $imageFile->store('reports', 'public');
        }

        $primaryImagePath = $paths[0] ?? null;
        $videoPath = $request->hasFile('video')
            ? $request->file('video')->store('reports', 'public')
            : null;

        $report = AnimalReport::query()->create([
            'user_id' => $request->user()->id,
            'report_type' => $validated['report_type'],
            'animal_type' => $validated['animal_type'],
            'location_text' => $validated['location_text'],
            'latitude' => $validated['latitude'] ?? null,
            'longitude' => $validated['longitude'] ?? null,
            'description' => $validated['description'],
            'image_path' => $primaryImagePath,
            'image_paths' => $paths,
            'video_path' => $videoPath,
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
                'image_paths' => $report->image_paths ?? [$report->image_path],
                'video_path' => $report->video_path,
                'status' => $report->status,
                'resolved_at' => optional($report->resolved_at)->toIso8601String(),
            ],
        ], 201);
    }
}