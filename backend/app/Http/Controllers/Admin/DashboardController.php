<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;
use Illuminate\Http\RedirectResponse;
use Illuminate\View\View;

class DashboardController extends Controller
{
    public function index(): View
    {
        $users = User::query()->latest()->get();

        foreach ($users as $user) {
            if (Schema::hasTable('reports')) {
                $user->reports_count = DB::table('reports')->where('user_id', $user->id)->count();
            } else {
                $user->reports_count = 0;
            }

            $user->status = $user->email_verified_at ? 'active' : 'inactive';
        }

        return view('admin.dashboard', [
            'users' => $users,
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
            'registered_at' => $user->created_at,
        ];

        if (Schema::hasTable('pets')) {
            $data['pets'] = DB::table('pets')->where('user_id', $user->id)->get();
        } else {
            $data['pets'] = [];
        }

        if (Schema::hasTable('reports')) {
            $data['reports'] = DB::table('reports')->where('user_id', $user->id)->get();
        } else {
            $data['reports'] = [];
        }

        return response()->json($data);
    }

    public function destroy(User $user): RedirectResponse
    {
        $user->delete();

        return redirect()->route('admin.dashboard')->with('success', 'User deleted successfully.');
    }
}