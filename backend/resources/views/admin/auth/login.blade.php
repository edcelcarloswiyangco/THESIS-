<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Admin Login</title>
    <style>
        :root {
            color-scheme: light;
            --bg1: #102a43;
            --bg2: #1f8a70;
            --card: rgba(255,255,255,.95);
            --text: #102a43;
            --muted: #5b7083;
            --accent: #0f766e;
            --danger: #b42318;
        }
        * { box-sizing: border-box; }
        body {
            margin: 0;
            font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
            min-height: 100vh;
            background: radial-gradient(circle at top left, rgba(255,255,255,.18), transparent 24%), linear-gradient(135deg, var(--bg1), var(--bg2));
            display: grid;
            place-items: center;
            padding: 24px;
            color: var(--text);
        }
        .card {
            width: min(100%, 440px);
            background: var(--card);
            border-radius: 28px;
            padding: 32px;
            box-shadow: 0 24px 60px rgba(0,0,0,.22);
            backdrop-filter: blur(10px);
        }
        .eyebrow { text-transform: uppercase; letter-spacing: .16em; font-size: 12px; color: var(--accent); font-weight: 700; }
        h1 { margin: 10px 0 8px; font-size: 32px; line-height: 1.1; }
        p { margin: 0 0 24px; color: var(--muted); }
        label { display:block; margin: 0 0 8px; font-size: 14px; font-weight: 600; }
        input {
            width: 100%;
            border: 1px solid #d0dbe7;
            border-radius: 14px;
            padding: 14px 16px;
            font-size: 15px;
            margin-bottom: 16px;
            background: white;
        }
        .actions { display:flex; align-items:center; justify-content:space-between; gap: 12px; margin-top: 4px; }
        .remember { display:flex; align-items:center; gap: 8px; font-size: 14px; color: var(--muted); }
        button {
            border: 0;
            background: var(--accent);
            color: white;
            border-radius: 14px;
            padding: 13px 18px;
            font-weight: 700;
            cursor: pointer;
        }
        .error, .success {
            border-radius: 14px;
            padding: 12px 14px;
            margin-bottom: 16px;
            font-size: 14px;
        }
        .error { background: #fff1f0; color: var(--danger); }
        .success { background: #ecfdf3; color: #027a48; }
        .hint { margin-top: 16px; font-size: 13px; color: var(--muted); }
    </style>
</head>
<body>
    <div class="card">
        <div class="eyebrow">Admin Access</div>
        <h1>Sign in to the dashboard</h1>
        <p>Only the admin account can access the web dashboard.</p>

        @if ($errors->any())
            <div class="error">{{ $errors->first() }}</div>
        @endif

        @if (session('success'))
            <div class="success">{{ session('success') }}</div>
        @endif

        <form method="POST" action="{{ route('admin.login.store') }}">
            @csrf
            <label for="email">Email</label>
            <input id="email" name="email" type="email" value="{{ old('email') }}" autocomplete="username" required>

            <label for="password">Password</label>
            <input id="password" name="password" type="password" autocomplete="current-password" required>

            <div class="actions">
                <label class="remember">
                    <input type="checkbox" name="remember" style="width:auto; margin:0;">
                    Remember me
                </label>
                <button type="submit">Login</button>
            </div>

            <div class="hint">Default local admin: admin@example.com / admin1234</div>
        </form>
    </div>
</body>
</html>