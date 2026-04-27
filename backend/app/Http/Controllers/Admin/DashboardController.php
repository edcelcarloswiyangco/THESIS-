<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\View\View;

class DashboardController extends Controller
{
    public function index(): View
    {
        return view('admin.dashboard', [
            'users' => User::query()->latest()->get(),
        ]);
    }

    public function destroy(Request $request, User $user): RedirectResponse
    {
        if ($user->is_admin) {
            return back()->with('error', 'Admin accounts cannot be deleted from the dashboard.');
        }

        if ($request->user()?->id === $user->id) {
            return back()->with('error', 'You cannot delete your own account while logged in.');
        }

        $user->delete();

        return redirect()->route('admin.dashboard')->with('success', 'User deleted successfully.');
    }
}