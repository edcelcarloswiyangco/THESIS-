<div class="pet-card" style="background:var(--panel);border:1px solid rgba(15,23,42,.06);border-radius:12px;overflow:hidden;box-shadow:0 2px 8px rgba(15,23,42,.04);transition:transform .2s,box-shadow .2s">
    <!-- Pet Photo -->
    <div style="width:100%;height:200px;background:#f0f5f5;display:flex;align-items:center;justify-content:center;overflow:hidden">
        @if ($pet->pet_photo_path)
            <img src="{{ asset('storage/' . $pet->pet_photo_path) }}" alt="{{ $pet->name }}" style="width:100%;height:100%;object-fit:cover">
        @else
            <div style="font-size:48px;color:var(--muted)">🐾</div>
        @endif
    </div>

    <!-- Pet Info -->
    <div style="padding:14px">
        <!-- Name -->
        <h4 style="margin:0 0 8px 0;font-size:16px;color:var(--text)">{{ $pet->name ?? 'Unnamed Pet' }}</h4>

        <!-- Animal Type -->
        <div style="display:flex;align-items:center;margin-bottom:6px;font-size:13px">
            <span style="color:var(--muted);margin-right:6px">Type:</span>
            <span style="background:#f0f5f5;padding:2px 8px;border-radius:4px;color:var(--text);font-weight:600">{{ ucfirst($pet->animal_type ?? 'Unknown') }}</span>
        </div>

        <!-- Breed -->
        @if ($pet->breed)
            <div style="display:flex;align-items:center;margin-bottom:6px;font-size:13px">
                <span style="color:var(--muted);margin-right:6px">Breed:</span>
                <span style="color:var(--text)">{{ $pet->breed }}</span>
            </div>
        @endif

        <!-- Age -->
        @if ($pet->age)
            <div style="display:flex;align-items:center;margin-bottom:6px;font-size:13px">
                <span style="color:var(--muted);margin-right:6px">Age:</span>
                <span style="color:var(--text)">{{ $pet->age }}</span>
            </div>
        @endif

        <!-- Gender -->
        @if ($pet->gender)
            <div style="display:flex;align-items:center;margin-bottom:6px;font-size:13px">
                <span style="color:var(--muted);margin-right:6px">Gender:</span>
                <span style="color:var(--text)">{{ ucfirst($pet->gender) }}</span>
            </div>
        @endif

        <!-- Rabies Vaccination Status -->
        <div style="display:flex;align-items:center;margin-bottom:10px;font-size:13px">
            <span style="color:var(--muted);margin-right:6px">Rabies Status:</span>
            @php
                $statusColor = match($pet->rabies_status) {
                    'vaccinated' => '#10b981',
                    'not_vaccinated' => '#ef4444',
                    default => '#f59e0b'
                };
                $statusText = match($pet->rabies_status) {
                    'vaccinated' => 'Vaccinated',
                    'not_vaccinated' => 'Unvaccinated',
                    default => 'Unknown'
                };
            @endphp
            <span style="background:{{ $statusColor }};color:#fff;padding:3px 8px;border-radius:4px;font-weight:600;font-size:12px">{{ $statusText }}</span>
        </div>

        <!-- Owner Info -->
        @if ($pet->user)
            <div style="border-top:1px solid rgba(15,23,42,.06);padding-top:10px;margin-top:10px;font-size:12px">
                <div style="color:var(--muted);margin-bottom:2px">Owner:</div>
                <div style="color:var(--text);font-weight:600">{{ $pet->user->full_name ?? $pet->user->name }}</div>
                <div style="color:var(--muted);font-size:11px">{{ $pet->user->email }}</div>
            </div>
        @endif
    </div>
</div>
