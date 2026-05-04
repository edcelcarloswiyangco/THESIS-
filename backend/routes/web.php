<?php

use App\Http\Controllers\Admin\AuthController;
use App\Http\Controllers\Admin\DashboardController;
use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return auth('admin')->check()
        ? redirect()->route('admin.dashboard')
        : redirect()->route('admin.login');
});

Route::get('/admin/login', [AuthController::class, 'create'])->name('admin.login');
Route::post('/admin/login', [AuthController::class, 'store'])->name('admin.login.store');
Route::post('/admin/logout', [AuthController::class, 'destroy'])->name('admin.logout');

Route::middleware('admin.auth')->group(function () {
    Route::get('/admin/dashboard', [DashboardController::class, 'index'])->name('admin.dashboard');
    Route::get('/admin/users/{user}/details', [DashboardController::class, 'show'])->name('admin.users.show');
    Route::patch('/admin/reports/{report}/status', [DashboardController::class, 'updateReportStatus'])->name('admin.reports.status');
});
