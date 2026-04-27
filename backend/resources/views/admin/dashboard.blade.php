<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Admin Dashboard</title>
    <style>
        :root {
            --bg: #f4f7f7;
            --panel: #ffffff;
            --text: #102a43;
            --muted: #627d98;
            --accent: #0f766e;
            --danger: #b42318;
            --border: #d9e2ec;
        }
        * { box-sizing: border-box; }
        body {
            margin: 0;
            font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
            background:
                radial-gradient(circle at top right, rgba(15,118,110,.10), transparent 22%),
                linear-gradient(180deg, #f8fbfc, var(--bg));
            color: var(--text);
            padding: 24px;
        }
        .wrap { max-width: 1180px; margin: 0 auto; }
        .hero {
            display:flex; justify-content:space-between; gap:16px; align-items:flex-start; flex-wrap:wrap;
            margin-bottom: 20px;
        }
        .title { margin: 0; font-size: 34px; line-height: 1.1; }
        .sub { margin: 8px 0 0; color: var(--muted); }
        .pill { display:inline-flex; align-items:center; gap:8px; padding: 10px 14px; border-radius: 999px; background: rgba(15,118,110,.08); color: var(--accent); font-weight:700; }
        .card {
            background: var(--panel);
            border: 1px solid rgba(15,23,42,.06);
            border-radius: 24px;
            box-shadow: 0 20px 40px rgba(16,42,67,.08);
            overflow: hidden;
        }
        .card-head { padding: 20px 22px; border-bottom: 1px solid var(--border); display:flex; justify-content:space-between; align-items:center; gap:12px; flex-wrap:wrap; }
        .stats { color: var(--muted); font-size: 14px; }
        .notice { margin: 0 0 16px; padding: 12px 14px; border-radius: 14px; }
        .notice.success { background: #ecfdf3; color: #027a48; }
        .notice.error { background: #fff1f0; color: var(--danger); }
        table { width: 100%; border-collapse: collapse; }
        th, td { padding: 16px 18px; text-align: left; border-bottom: 1px solid var(--border); vertical-align: top; }
        th { background: #f8fafc; font-size: 13px; text-transform: uppercase; letter-spacing: .08em; color: var(--muted); }
        tbody tr:hover { background: #fbfdfe; }
        .badge { display:inline-flex; padding: 6px 10px; border-radius: 999px; font-size: 12px; font-weight: 700; }
        .badge.admin { background: #e0f2fe; color: #075985; }
        .badge.user { background: #ecfdf3; color: #027a48; }
        .muted { color: var(--muted); }
        .toolbar { display:flex; gap:12px; align-items:center; }
        .btn, .btn-danger {
            display:inline-flex; align-items:center; justify-content:center; border:0; border-radius: 12px; padding: 11px 16px; font-weight: 700; cursor: pointer; text-decoration:none;
        }
        .btn { background: var(--accent); color: white; }
        .btn-danger { background: #fff1f0; color: var(--danger); }
        .empty { padding: 28px 22px; color: var(--muted); }
        form { margin: 0; }
        @media (max-width: 720px) {
            body { padding: 16px; }
            th:nth-child(3), td:nth-child(3), th:nth-child(4), td:nth-child(4) { display: none; }
        }
    </style>
</head>
<body>
    <div class="wrap">
        <div class="hero">
            <div>
                <div class="pill">Admin Dashboard</div>
                <h1 class="title">Users Manager</h1>
                <p class="sub">See every registered account in the system. The mobile app handles client sign-in.</p>
            </div>
            <form method="POST" action="{{ route('admin.logout') }}">
                @csrf
                <button class="btn" type="submit">Logout</button>
            </form>
        </div>

        @if (session('success'))
            <div class="notice success">{{ session('success') }}</div>
        @endif

        @if (session('error'))
            <div class="notice error">{{ session('error') }}</div>
        @endif

        <div class="card">
            <div class="card-head">
                <div>
                    <strong>Total users</strong>
                    <div class="stats">{{ $users->count() }} accounts registered</div>
                </div>
                <div class="muted">Logged in as {{ auth()->user()->name }} ({{ auth()->user()->email }})</div>
            </div>

            @if ($users->isEmpty())
                <div class="empty">No users have registered yet.</div>
            @else
                <div style="overflow-x:auto;">
                    <table>
                        <thead>
                            <tr>
                                <th>Name</th>
                                <th>Email</th>
                                <th>Role</th>
                                <th>Registered</th>
                                <th>Action</th>
                            </tr>
                        </thead>
                        <tbody>
                            @foreach ($users as $user)
                                <tr>
                                    <td>
                                        <strong>{{ $user->name }}</strong>
                                        @if (auth()->id() === $user->id)
                                            <div class="muted">Current admin account</div>
                                        @endif
                                    </td>
                                    <td>{{ $user->email }}</td>
                                    <td>
                                        <span class="badge {{ $user->is_admin ? 'admin' : 'user' }}">
                                            {{ $user->is_admin ? 'Admin' : 'Client' }}
                                        </span>
                                    </td>
                                    <td>{{ $user->created_at?->format('M d, Y h:i A') }}</td>
                                    <td>
                                        @if (! $user->is_admin && auth()->id() !== $user->id)
                                            <form method="POST" action="{{ route('admin.users.destroy', $user) }}" onsubmit="return confirm('Delete this user?');">
                                                @csrf
                                                @method('DELETE')
                                                <button class="btn-danger" type="submit">Delete</button>
                                            </form>
                                        @else
                                            <span class="muted">Protected</span>
                                        @endif
                                    </td>
                                </tr>
                            @endforeach
                        </tbody>
                    </table>
                </div>
            @endif
        </div>
    </div>
</body>
</html>