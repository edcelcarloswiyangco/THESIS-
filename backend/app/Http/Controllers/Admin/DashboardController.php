<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\AnimalReport;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;
use Illuminate\View\View;

class DashboardController extends Controller
{
    public function index(): View
    {
        $users = User::query()->latest()->get();

        $totalReports = Schema::hasTable('animal_reports')
            ? DB::table('animal_reports')->count()
            : 0;

        $totalPets = Schema::hasTable('pets')
            ? DB::table('pets')->count()
            : 0;

        foreach ($users as $user) {
            $user->reports_count = Schema::hasTable('animal_reports')
                ? DB::table('animal_reports')->where('user_id', $user->id)->count()
                : 0;
            $user->status = $user->email_verified_at ? 'active' : 'inactive';
        }

        $reports = Schema::hasTable('animal_reports')
            ? AnimalReport::query()->with('user')->latest('id')->get()
            : collect();

        return view('admin.dashboard', [
            'users' => $users,
            'summary' => [
                'total_users' => $users->count(),
                'total_reports' => $totalReports,
                'total_pets' => $totalPets,
            ],
            'reports' => $reports,
        ]);
    }

    public function show(User $user)
    {
        $data = [
            'id' => $user->id,
            'full_name' => $user->full_name ?? $user->name,
            'email' => $user->email,
            'contact_number' => $user->contact_number,
            'address' => $user->address,
            'registered_at' => $user->created_at ? $user->created_at->format('M d, Y') : null,
            'status' => $user->email_verified_at ? 'active' : 'inactive',
        ];

        if (Schema::hasTable('pets')) {
            $data['pets'] = DB::table('pets')->where('user_id', $user->id)->get();
        } else {
            $data['pets'] = [];
        }

        if (Schema::hasTable('animal_reports')) {
            $data['reports'] = DB::table('animal_reports')->where('user_id', $user->id)->get();
        } else {
            $data['reports'] = [];
        }

        $data['pets_count'] = is_countable($data['pets']) ? count($data['pets']) : 0;
        $data['reports_count'] = is_countable($data['reports']) ? count($data['reports']) : 0;

        return response()->json($data);
    }
}