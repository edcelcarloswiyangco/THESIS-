<?php

use App\Http\Controllers\Api\MediaController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\ReportController;
use Illuminate\Support\Facades\Route;

Route::get('/health', function () {
    return response()->json([
        'status' => 'ok',
        'message' => 'Laravel API is running.',
    ]);
});

Route::get('/media', [MediaController::class, 'show']);
Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);

Route::middleware('api.token')->group(function () {
    Route::get('/me', [AuthController::class, 'me']);
    Route::patch('/me', [AuthController::class, 'updateMe']);
    Route::post('/me/password', [AuthController::class, 'changePassword']);
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/reports', [ReportController::class, 'index']);
    Route::post('/reports', [ReportController::class, 'store']);
});