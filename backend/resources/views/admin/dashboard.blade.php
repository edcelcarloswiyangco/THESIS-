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
        .summary-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(210px,1fr));gap:16px;margin-bottom:18px}
        .stat-card{background:#f8fffc;border:1px solid #d9f7ec;border-radius:14px;padding:18px}
        .stat-card strong{display:block;margin-bottom:6px}
        .tabs{display:flex;gap:10px;margin-bottom:16px;flex-wrap:wrap}
        .tab{background:transparent;border:1px solid var(--border);border-radius:999px;padding:10px 16px;color:var(--text);cursor:pointer;font-weight:700}
        .tab.active{background:#ecfdf3;color:var(--accent);border-color:#86efac}
        .tab-panel.hidden{display:none}
        .report-card{border:1px solid #d9e2ec;border-radius:12px;padding:16px;margin-bottom:16px;background:#f9fbfd}
        .report-card h4{margin:0 0 8px 0;font-size:16px}
        .report-row{display:flex;justify-content:space-between;align-items:center;padding:14px 16px;border:1px solid var(--border);border-radius:12px;background:#fff;margin-bottom:12px;gap:16px}
        .report-summary{flex:1;min-width:0}
        .report-summary h4{margin:0 0 4px 0;font-size:15px}
        .report-summary .muted{display:block;font-size:13px;margin-top:4px;color:var(--muted)}
        .report-actions{white-space:nowrap}
        .report-actions .btn-ghost{min-width:84px}
        .report-meta{margin-bottom:10px;color:#475569;line-height:1.5}
        .report-media{display:flex;flex-wrap:wrap;gap:12px;margin-top:12px}
        .report-media img{width:calc(50% - 6px);max-width:220px;max-height:220px;border-radius:12px;object-fit:cover;border:1px solid #d9e2ec}
        .report-media video{width:100%;max-width:420px;border-radius:12px;border:1px solid #d9e2ec}
        .modal{position:fixed;inset:0;background:rgba(2,6,23,.5);display:flex;align-items:center;justify-content:center;padding:20px;visibility:hidden;opacity:0;transition:opacity .15s ease,visibility .15s}
        .modal.show{visibility:visible;opacity:1}
        .modal-card{background:#fff;border-radius:12px;max-width:880px;width:100%;padding:18px;max-height:calc(100vh - 60px);overflow:auto}
        .modal.show{visibility:visible;opacity:1}
        .modal-card{background:#fff;border-radius:12px;max-width:880px;width:100%;padding:18px}
        @media (max-width:800px){.sidebar{display:none}.content{padding:16px}}
    </style>
</head>
<body>
    <div class="app">
        <?php $section = request('section', 'dashboard'); ?>
        <aside class="sidebar">
            <div class="brand">STRAYCONNECT</div>
            <nav class="nav">
                <a href="{{ route('admin.dashboard', ['section' => 'dashboard']) }}" class="{{ $section === 'dashboard' ? 'active' : '' }}">DASHBOARD</a>
                <a href="{{ route('admin.dashboard', ['section' => 'user-management']) }}" class="{{ $section === 'user-management' ? 'active' : '' }}">USER MANAGEMENT</a>
                <a href="{{ route('admin.dashboard', ['section' => 'pet-directory']) }}" class="{{ $section === 'pet-directory' ? 'active' : '' }}">PET DIRECTORY</a>
                <a href="{{ route('admin.dashboard', ['section' => 'report-management']) }}" class="{{ $section === 'report-management' ? 'active' : '' }}">REPORT MANAGEMENT</a>
                <a href="{{ route('admin.dashboard', ['section' => 'settings']) }}" class="{{ $section === 'settings' ? 'active' : '' }}">SETTINGS</a>
            </nav>
            <div class="muted" style="margin-top:auto">Signed in as<br><strong>{{ auth('admin')->user()->email }}</strong></div>
        </aside>

        <main class="content">
            <div class="topbar">
                <div>
                    @if ($section === 'dashboard')
                        <h2 style="margin:0">Dashboard</h2>
                        <div class="muted">High-level overview of site activity</div>
                    @elseif ($section === 'user-management')
                        <h2 style="margin:0">User Management</h2>
                        <div class="muted">Manage registered users and view account details</div>
                    @elseif ($section === 'pet-directory')
                        <h2 style="margin:0">Pet Directory</h2>
                        <div class="muted">Review pet records and ownership details</div>
                    @elseif ($section === 'report-management')
                        <h2 style="margin:0">Report Management</h2>
                        <div class="muted">View and manage submitted animal reports</div>
                    @else
                        <h2 style="margin:0">Settings</h2>
                        <div class="muted">Admin account actions and system controls</div>
                    @endif
                </div>
            </div>

            @if (session('success'))
                <div class="card" style="margin-bottom:12px"><strong>Success:</strong> {{ session('success') }}</div>
            @endif

            @if ($section === 'dashboard')
                <div class="summary-grid">
                    <div class="stat-card">
                        <strong>Total Users</strong>
                        <div class="muted">{{ $summary['total_users'] ?? 0 }} accounts</div>
                    </div>
                    <div class="stat-card">
                        <strong>Total Reports</strong>
                        <div class="muted">{{ $summary['total_reports'] ?? 0 }} reports submitted</div>
                    </div>
                    <div class="stat-card">
                        <strong>Total Pets</strong>
                        <div class="muted">{{ $summary['total_pets'] ?? 0 }} registered pets</div>
                    </div>
                </div>
                <div class="card">
                    <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:12px">
                        <div><strong>Dashboard summary</strong><div class="muted">Quick site metrics and activity</div></div>
                        <div class="muted">Last updated: {{ now()->format('M d, Y') }}</div>
                    </div>
                    <div class="muted">Use the sidebar to switch between user management, pet directory, reports, and settings.</div>
                </div>
            @elseif ($section === 'user-management')
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
                                            <td>{{ $user->contact_number ?? '-' }}</td>
                                            <td>{{ $user->reports_count ?? 0 }}</td>
                                            <td>
                                                <button class="btn-ghost" onclick="openUser({{ $user->id }})">View</button>
                                            </td>
                                        </tr>
                                    @endforeach
                                </tbody>
                            </table>
                        </div>
                    @endif
                </div>
            @elseif ($section === 'pet-directory')
                <div class="card">
                    <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:12px">
                        <div><strong>Pet Directory</strong><div class="muted">Explore the pet records database</div></div>
                    </div>
                    <div class="muted">This section is reserved for future pet directory controls and filters.</div>
                </div>
            @elseif ($section === 'report-management')
                <div class="card">
                    <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:12px">
                        <div><strong>Report Management</strong><div class="muted">Browse all submitted reports and open report details</div></div>
                        <div class="muted">Last updated: {{ now()->format('M d, Y') }}</div>
                    </div>

                    @if ($reports->isEmpty())
                        <div class="muted">No reports have been submitted yet.</div>
                    @else
                        <div>
                            @foreach ($reports as $report)
                                <div class="report-row">
                                    <div class="report-summary">
                                        <h4>Report #{{ $report->id }} — {{ ucfirst($report->report_type) }} ({{ $report->animal_type }})</h4>
                                        <span class="muted">Submitted: {{ $report->created_at->format('M d, Y') }}</span>
                                    </div>
                                    <div class="report-actions">
                                        <button class="btn-ghost" type="button" onclick="openReport({{ $report->id }})">View</button>
                                    </div>
                                </div>
                            @endforeach
                        </div>
                    @endif
                </div>
            @else
                <div class="card">
                    <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:12px">
                        <div><strong>Settings</strong><div class="muted">Manage admin actions and account controls</div></div>
                    </div>
                    <div style="margin-bottom:16px">
                        <div><strong>Admin</strong></div>
                        <div class="muted">{{ auth('admin')->user()->email }}</div>
                    </div>
                    <form method="POST" action="{{ route('admin.logout') }}">
                        @csrf
                        <button class="btn" type="submit">Logout</button>
                    </form>
                </div>
            @endif
        </main>
    </div>

    <div id="userModal" class="modal" role="dialog" aria-hidden="true">
        <div class="modal-card">
            <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:12px">
                <div>
                    <h3 id="modalName" style="margin:0">User Details</h3>
                    <div class="muted" id="modalSubtitle">Overview</div>
                </div>
                <button onclick="closeModal()" class="btn-ghost">Close</button>
            </div>
            <div class="tabs">
                <button id="overviewTab" class="tab active" type="button" onclick="showTab('overview')">Overview</button>
                <button id="petsTab" class="tab" type="button" onclick="showTab('pets')">Pets</button>
                <button id="reportsTab" class="tab" type="button" onclick="showTab('reports')">Reports</button>
            </div>
            <div id="tabOverview" class="tab-panel">
                <div><strong>Email:</strong> <span id="modalEmail"></span></div>
                <div><strong>Contact:</strong> <span id="modalContact"></span></div>
                <div><strong>Address:</strong> <span id="modalAddress"></span></div>
                <div><strong>Status:</strong> <span id="modalStatus"></span></div>
                <div><strong>Registered:</strong> <span id="modalRegistered"></span></div>
                <div><strong>Pets count:</strong> <span id="modalPetsCount"></span></div>
                <div><strong>Reports count:</strong> <span id="modalReportsCount"></span></div>
            </div>
            <div id="tabPets" class="tab-panel hidden">
                <div id="modalPets" class="muted">No pet records found.</div>
            </div>
            <div id="tabReports" class="tab-panel hidden">
                <div id="modalReports" class="muted">No reports found.</div>
            </div>
        </div>
    </div>

    <div id="reportModal" class="modal" role="dialog" aria-hidden="true">
        <div class="modal-card">
            <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:12px">
                <div>
                    <h3 id="reportModalTitle" style="margin:0">Report Details</h3>
                    <div class="muted" id="reportModalSubtitle"></div>
                </div>
                <button onclick="closeReportModal()" class="btn-ghost">Close</button>
            </div>
            <div id="reportDetails"></div>
        </div>
    </div>

    <script>
        function showTab(tabName) {
            ['overview', 'pets', 'reports'].forEach(name => {
                document.getElementById(name + 'Tab').classList.toggle('active', name === tabName);
                document.getElementById('tab' + name.charAt(0).toUpperCase() + name.slice(1)).classList.toggle('hidden', name !== tabName);
            });
            document.getElementById('modalSubtitle').textContent = tabName === 'overview' ? 'Overview' : tabName === 'pets' ? 'Pets' : 'Reports';
        }

        function openUser(id) {
            fetch('/admin/users/' + id + '/details')
                .then(r => r.json())
                .then(data => {
                    document.getElementById('modalName').textContent = data.full_name || ('User ' + data.id);
                    document.getElementById('modalEmail').textContent = data.email || '-';
                    document.getElementById('modalContact').textContent = data.contact_number || '-';
                    document.getElementById('modalAddress').textContent = data.address || '-';
                    document.getElementById('modalStatus').textContent = data.status ? data.status.charAt(0).toUpperCase() + data.status.slice(1) : '-';
                    document.getElementById('modalRegistered').textContent = data.registered_at || '-';
                    document.getElementById('modalPetsCount').textContent = data.pets_count ?? 0;
                    document.getElementById('modalReportsCount').textContent = data.reports_count ?? 0;

                    const petsEl = document.getElementById('modalPets');
                    if (data.pets && data.pets.length) {
                        petsEl.innerHTML = '<ul>' + data.pets.map(p => '<li>' + (p.name || ('Pet #' + p.id)) + '</li>').join('') + '</ul>';
                    } else {
                        petsEl.textContent = 'No pet records found.';
                    }

                    const reportsEl = document.getElementById('modalReports');
                    if (data.reports && data.reports.length) {
                        reportsEl.innerHTML = data.reports.map(r => {
                            let images = [];
                            try {
                                if (Array.isArray(r.image_paths)) {
                                    images = r.image_paths;
                                } else if (typeof r.image_paths === 'string' && r.image_paths.trim().length) {
                                    images = JSON.parse(r.image_paths);
                                }
                            } catch (error) {
                                images = [];
                            }

                            const imageHtml = images.length
                                ? `<div class="report-media">${images.map(img => `<img src="/storage/${img}" alt="Report image">`).join('')}</div>`
                                : '';
                            const videoHtml = r.video_path ? `<div class="report-media"><video controls><source src="/storage/${r.video_path}" type="video/mp4"></video></div>` : '';
                            return `
                                <div class="report-card">
                                    <h4>Report #${r.id} — ${r.report_type} (${r.animal_type})</h4>
                                    <div class="report-meta"><strong>Location:</strong> ${r.location_text || '-'}<br><strong>Description:</strong> ${r.description || '-'}</div>
                                    ${imageHtml}
                                    ${videoHtml}
                                </div>
                            `;
                        }).join('');
                    } else {
                        reportsEl.textContent = 'No reports found.';
                    }

                    if (data.reports && data.reports.length) {
                        showTab('reports');
                    } else {
                        showTab('overview');
                    }
                    document.getElementById('userModal').classList.add('show');
                })
                .catch(err => {
                    alert('Unable to fetch user details');
                });
        }

        @php
            $reportData = $reports->map(function ($report) {
                return [
                    'id' => $report->id,
                    'report_type' => $report->report_type,
                    'animal_type' => $report->animal_type,
                    'description' => $report->description,
                    'location_text' => $report->location_text,
                    'latitude' => $report->latitude,
                    'longitude' => $report->longitude,
                    'status' => $report->status,
                    'created_at' => optional($report->created_at)->format('M d, Y H:i'),
                    'image_paths' => $report->image_paths,
                    'video_path' => $report->video_path,
                    'user_name' => optional($report->user)->full_name ?? optional($report->user)->name,
                    'user_email' => optional($report->user)->email,
                    'user_contact' => optional($report->user)->contact_number,
                ];
            })->toArray();
        @endphp

        const reportData = @json($reportData);

        function openReport(id) {
            const report = reportData.find(r => r.id === id);
            if (!report) {
                alert('Report not found');
                return;
            }

            document.getElementById('reportModalTitle').textContent = `Report #${report.id} — ${report.report_type} (${report.animal_type})`;
            document.getElementById('reportModalSubtitle').textContent = `${report.created_at} • ${report.status ? report.status.charAt(0).toUpperCase() + report.status.slice(1) : 'Unknown status'}`;

            let mediaHtml = '';
            if (Array.isArray(report.image_paths) && report.image_paths.length) {
                mediaHtml += '<div class="report-media">' + report.image_paths.map(path => `<img src="/storage/${path}" alt="Report image">`).join('') + '</div>';
            }
            if (report.video_path) {
                mediaHtml += `<div class="report-media"><video controls><source src="/storage/${report.video_path}" type="video/mp4"></video></div>`;
            }

            document.getElementById('reportDetails').innerHTML = `
                <div class="report-card">
                    <div class="report-meta"><strong>Submitted by:</strong> ${report.user_name || '-'}<br><strong>Email:</strong> ${report.user_email || '-'}<br><strong>Contact:</strong> ${report.user_contact || '-'}<br><strong>Location:</strong> ${report.location_text || '-'}<br><strong>Coordinates:</strong> ${report.latitude || '-'}, ${report.longitude || '-'}</div>
                    <div class="report-meta" style="margin-top:12px"><strong>Description:</strong> ${report.description || '-'}</div>
                    ${mediaHtml || '<div class="muted">No media attached.</div>'}
                </div>
            `;

            document.getElementById('reportModal').classList.add('show');
        }

        function closeModal() { document.getElementById('userModal').classList.remove('show'); }
        function closeReportModal() { document.getElementById('reportModal').classList.remove('show'); }

        @if ($section === 'user-management')
            setInterval(() => {
                if (!document.hidden) {
                    window.location.reload();
                }
            }, 600000);
        @endif
    </script>
</body>
</html>