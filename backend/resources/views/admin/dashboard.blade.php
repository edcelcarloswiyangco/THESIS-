<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Admin · StrayConnect</title>
    <style>
        :root{--bg:#f4f7f7;--panel:#fff;--text:#102a43;--muted:#627d98;--accent:#0f766e;--danger:#b42318;--border:#d9e2ec}
        *{box-sizing:border-box}
        body{margin:0;font-family:Inter,system-ui,-apple-system,Segoe UI,sans-serif;background:linear-gradient(180deg,#f8fbfc,var(--bg));color:var(--text)}
        .app{display:flex;min-height:100vh}
        .sidebar{width:260px;background:var(--panel);border-right:1px solid var(--border);padding:22px;display:flex;flex-direction:column;gap:18px}
        .brand{font-weight:900;color:var(--accent);font-size:18px}
        .nav{display:flex;flex-direction:column;gap:6px}
        .nav a{display:block;padding:10px 12px;border-radius:10px;color:var(--text);text-decoration:none;font-weight:700}
        .nav a.active{background:#ecfdf3;color:var(--accent)}
        .content{flex:1;padding:28px}
        .topbar{display:flex;justify-content:space-between;align-items:center;margin-bottom:18px}
        .card{background:var(--panel);border:1px solid rgba(15,23,42,.06);border-radius:12px;padding:18px}
        table{width:100%;border-collapse:collapse}
        th,td{padding:12px 14px;border-bottom:1px solid var(--border);text-align:left}
        th{font-size:12px;color:var(--muted);text-transform:uppercase}
        .btn{background:var(--accent);color:#fff;padding:8px 12px;border-radius:8px;text-decoration:none;font-weight:700}
        .btn-ghost{background:transparent;border:1px solid var(--border);padding:8px 12px;border-radius:8px}
        .muted{color:var(--muted)}
        .status.active{color:#027a48;font-weight:700}
        .status.inactive{color:#b45309;font-weight:700}
        .modal{position:fixed;inset:0;background:rgba(2,6,23,.5);display:flex;align-items:center;justify-content:center;padding:20px;visibility:hidden;opacity:0;transition:opacity .15s ease,visibility .15s}
        .modal.show{visibility:visible;opacity:1}
        .modal-card{background:#fff;border-radius:12px;max-width:880px;width:100%;padding:18px}
        @media (max-width:800px){.sidebar{display:none}.content{padding:16px}}
    </style>
</head>
<body>
    <div class="app">
        <aside class="sidebar">
            <div class="brand">STRAYCONNECT</div>
            <nav class="nav">
                <a href="#" class="active">DASHBOARD</a>
                <a href="#">USER MANAGEMENT</a>
                <a href="#">PET DIRECTORY</a>
                <a href="#">REPORT MANAGEMENT</a>
                <a href="#">SETTING</a>
            </nav>
            <div class="muted" style="margin-top:auto">Signed in as<br><strong>{{ auth('admin')->user()->email }}</strong></div>
        </aside>

        <main class="content">
            <div class="topbar">
                <div>
                    <h2 style="margin:0">Users Management</h2>
                    <div class="muted">Manage registered users and view details</div>
                </div>
                <form method="POST" action="{{ route('admin.logout') }}">
                    @csrf
                    <button class="btn" type="submit">Logout</button>
                </form>
            </div>

            @if (session('success'))
                <div class="card" style="margin-bottom:12px"><strong>Success:</strong> {{ session('success') }}</div>
            @endif

            <div class="card">
                <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:12px">
                    <div><strong>Total users</strong><div class="muted">{{ $users->count() }} accounts registered</div></div>
                    <div class="muted">Last updated: {{ now()->format('M d, Y') }}</div>
                </div>

                @if ($users->isEmpty())
                    <div class="muted">No users have registered yet.</div>
                @else
                    <div style="overflow:auto">
                        <table>
                            <thead>
                                <tr>
                                    <th>User ID</th>
                                    <th>Full Name</th>
                                    <th>Status</th>
                                    <th>Contact</th>
                                    <th># Reports</th>
                                    <th>Action</th>
                                </tr>
                            </thead>
                            <tbody>
                                @foreach ($users as $user)
                                    <tr>
                                        <td>{{ $user->id }}</td>
                                        <td><strong>{{ $user->full_name ?? $user->name }}</strong><div class="muted">{{ $user->email }}</div></td>
                                        <td><span class="status {{ $user->status }}">{{ ucfirst($user->status) }}</span></td>
                                        <td>{{ $user->contact_number ?? '-' }}</td>
                                        <td>{{ $user->reports_count ?? 0 }}</td>
                                        <td>
                                            <button class="btn-ghost" onclick="openUser({{ $user->id }})">View</button>
                                            <form method="POST" action="{{ route('admin.users.destroy', $user) }}" style="display:inline" onsubmit="return confirm('Delete this user?');">
                                                @csrf
                                                @method('DELETE')
                                                <button class="btn-ghost" type="submit">Delete</button>
                                            </form>
                                        </td>
                                    </tr>
                                @endforeach
                            </tbody>
                        </table>
                    </div>
                @endif
            </div>
        </main>
    </div>

    <div id="userModal" class="modal" role="dialog" aria-hidden="true">
        <div class="modal-card">
            <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:12px">
                <h3 id="modalName" style="margin:0">User Details</h3>
                <button onclick="closeModal()" class="btn-ghost">Close</button>
            </div>
            <div id="modalBody">
                <div><strong>Email:</strong> <span id="modalEmail"></span></div>
                <div><strong>Contact:</strong> <span id="modalContact"></span></div>
                <div><strong>Address:</strong> <span id="modalAddress"></span></div>
                <hr/>
                <div><strong>Pets</strong>
                    <div id="modalPets" class="muted">No pet records found.</div>
                </div>
                <div style="margin-top:12px"><strong>Reports</strong>
                    <div id="modalReports" class="muted">No reports found.</div>
                </div>
            </div>
        </div>
    </div>

    <script>
        function openUser(id) {
            fetch('/admin/users/' + id + '/details')
                .then(r => r.json())
                .then(data => {
                    document.getElementById('modalName').textContent = data.full_name || ('User ' + data.id);
                    document.getElementById('modalEmail').textContent = data.email || '-';
                    document.getElementById('modalContact').textContent = data.contact_number || '-';
                    document.getElementById('modalAddress').textContent = data.address || '-';

                    const petsEl = document.getElementById('modalPets');
                    if (data.pets && data.pets.length) {
                        petsEl.innerHTML = '<ul>' + data.pets.map(p => '<li>' + (p.name || ('Pet #' + p.id)) + '</li>').join('') + '</ul>';
                    } else {
                        petsEl.textContent = 'No pet records found.';
                    }

                    const reportsEl = document.getElementById('modalReports');
                    if (data.reports && data.reports.length) {
                        reportsEl.innerHTML = '<ul>' + data.reports.map(r => '<li>' + (r.title || ('Report #' + r.id)) + '</li>').join('') + '</ul>';
                    } else {
                        reportsEl.textContent = 'No reports found.';
                    }

                    document.getElementById('userModal').classList.add('show');
                })
                .catch(err => {
                    alert('Unable to fetch user details');
                });
        }

        function closeModal() { document.getElementById('userModal').classList.remove('show'); }
    </script>
</body>
</html>