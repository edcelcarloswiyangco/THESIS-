<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ApiToken;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

class AuthController extends Controller
{
    public function register(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'full_name' => ['required', 'string', 'max:100'],
            'email' => ['required', 'email', 'max:255', 'unique:users,email'],
            'password' => ['required', 'string', 'min:6'],
            'contact_number' => ['required', 'string', 'max:20'],
            'address' => ['required', 'string', 'max:255'],
        ]);

        $user = User::query()->create([
            'name' => $validated['full_name'],
            'full_name' => $validated['full_name'],
            'email' => $validated['email'],
            'password' => Hash::make($validated['password']),
            'contact_number' => $validated['contact_number'],
            'address' => $validated['address'],
        ]);

        return response()->json($this->issueTokenResponse($user), 201);
    }

    public function login(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'email' => ['required', 'email'],
            'password' => ['required', 'string'],
        ]);

        $user = User::query()->where('email', $validated['email'])->first();

        if (! $user || ! Hash::check($validated['password'], $user->password)) {
            return response()->json([
                'message' => 'Invalid email or password.',
            ], 422);
        }

        return response()->json($this->issueTokenResponse($user));
    }

    public function me(Request $request): JsonResponse
    {
        return response()->json([
            'data' => $this->serializeUser($request->user()),
        ]);
    }

    public function updateMe(Request $request): JsonResponse
    {
        $user = $request->user();

        $validated = $request->validate([
            'contact_number' => ['required', 'string', 'max:20'],
            'address' => ['required', 'string', 'max:255'],
        ]);

        $user->contact_number = $validated['contact_number'];
        $user->address = $validated['address'];
        $user->save();

        return response()->json([
            'data' => $this->serializeUser($user),
            'message' => 'Profile updated successfully.',
        ]);
    }

    public function changePassword(Request $request): JsonResponse
    {
        $user = $request->user();

        $validated = $request->validate([
            'current_password' => ['required', 'string'],
            'password' => ['required', 'string', 'min:6', 'confirmed'],
        ]);

        if (! Hash::check($validated['current_password'], $user->password)) {
            return response()->json([
                'message' => 'Current password is incorrect.',
            ], 422);
        }

        $user->password = Hash::make($validated['password']);
        $user->save();

        return response()->json([
            'message' => 'Password changed successfully.',
        ]);
    }

    public function logout(Request $request): JsonResponse
    {
        /** @var ApiToken|null $token */
        $token = $request->attributes->get('api_token');

        if ($token) {
            $token->delete();
        }

        return response()->json([
            'message' => 'Logged out successfully.',
        ]);
    }

    private function issueTokenResponse(User $user): array
    {
        $plainTextToken = Str::random(64);

        ApiToken::query()->create([
            'user_id' => $user->id,
            'name' => 'mobile-app',
            'token_hash' => hash('sha256', $plainTextToken),
            'last_used_at' => now(),
        ]);

        return [
            'token_type' => 'Bearer',
            'token' => $plainTextToken,
            'data' => $this->serializeUser($user),
        ];
    }

    private function serializeUser(?User $user): ?array
    {
        if (! $user) {
            return null;
        }

        return [
            'id' => $user->id,
            'full_name' => $user->full_name,
            'name' => $user->full_name,
            'email' => $user->email,
            'contact_number' => $user->contact_number,
            'address' => $user->address,
            'is_admin' => false,
        ];
    }
}