<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="csrf-token" content="{{ csrf_token() }}">
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
        .btn{background:var(--accent);color:#fff;padding:8px 12px;border-radius:8px;text-decoration:none;font-weight:700;border:none;cursor:pointer}
        .btn-ghost{background:transparent;border:1px solid var(--border);padding:8px 12px;border-radius:8px;cursor:pointer}
        .muted{color:var(--muted)}
        .status.active{color:#027a48;font-weight:700}
        .status.inactive{color:#b45309;font-weight:700}
        .summary-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(210px,1fr));gap:16px;margin-bottom:18px}
        .stat-card{background:#f8fffc;border:1px solid #d9f7ec;border-radius:14px;padding:18px}
        .stat-card strong{display:block;margin-bottom:6px}
        .analytics-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(260px,1fr));gap:16px;margin-bottom:18px}
        .metric-card{color:#fff;border:none;min-height:128px;display:flex;flex-direction:column;justify-content:space-between}
        .metric-card strong{display:block;font-size:15px;letter-spacing:.02em;text-transform:uppercase;margin-bottom:6px}
        .metric-value{font-size:34px;font-weight:900;line-height:1}
        .metric-note{font-size:13px;opacity:.88;margin-top:10px}
        .metric-card.pending{background:linear-gradient(135deg,#ef4444,#b91c1c)}
        .metric-card.in-progress{background:linear-gradient(135deg,#f59e0b,#d97706)}
        .metric-card.resolved{background:linear-gradient(135deg,#10b981,#047857)}
        .charts-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(320px,1fr));gap:16px;margin-top:18px}
        .chart-card{background:var(--panel);border:1px solid rgba(15,23,42,.06);border-radius:16px;padding:18px;box-shadow:0 10px 25px rgba(15,23,42,.04)}
        .chart-card.wide{grid-column:1 / -1}
        .chart-card h3{margin:0 0 4px 0;font-size:17px}
        .chart-card .muted{font-size:13px}
        .chart-toolbar{display:flex;justify-content:space-between;align-items:center;gap:12px;flex-wrap:wrap;margin-bottom:14px}
        .chart-select{border:1px solid var(--border);border-radius:10px;background:#fff;padding:10px 12px;font:inherit;color:var(--text)}
        .chart-box{min-height:320px}
        .chart-box.tall{min-height:360px}
        .report-toolbar{display:flex;justify-content:space-between;align-items:flex-start;gap:12px;flex-wrap:wrap;margin-bottom:16px}
        .report-filters{display:flex;gap:10px;flex-wrap:wrap;align-items:center}
        .report-search{min-width:240px;max-width:360px;border:1px solid var(--border);border-radius:10px;background:#fff;padding:10px 12px;font:inherit;color:var(--text)}
        .report-filter{border:1px solid var(--border);border-radius:10px;background:#fff;padding:10px 12px;font:inherit;color:var(--text)}
        .report-status-pill{display:inline-flex;align-items:center;padding:6px 10px;border-radius:999px;font-size:12px;font-weight:800;text-transform:uppercase;letter-spacing:.02em}
        .report-status-pill.pending{background:#fef3f2;color:#b42318}
        .report-status-pill.in_progress{background:#fffaeb;color:#b54708}
        .report-status-pill.resolved{background:#ecfdf3;color:#027a48}
        .report-actions{white-space:nowrap;display:flex;gap:8px;flex-wrap:wrap;align-items:center}
        .report-status-row-action,.btn-status{background:var(--accent);color:#fff;border:none;padding:8px 12px;border-radius:8px;font-weight:700;cursor:pointer}
        .btn-status.secondary,.report-status-row-action.secondary{background:#f59e0b}
        .report-status-row-action[disabled],.btn-status[disabled]{opacity:.55;cursor:not-allowed}
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
        .report-meta{margin-bottom:10px;color:#475569;line-height:1.5}
        .report-media{display:flex;flex-wrap:wrap;gap:12px;margin-top:12px}
        .report-media img{width:calc(50% - 6px);max-width:220px;max-height:220px;border-radius:12px;object-fit:cover;border:1px solid #d9e2ec}
        .report-media video{width:100%;max-width:420px;border-radius:12px;border:1px solid #d9e2ec}
        .modal{position:fixed;inset:0;background:rgba(2,6,23,.5);display:flex;align-items:center;justify-content:center;padding:20px;visibility:hidden;opacity:0;transition:opacity .15s ease,visibility .15s}
        .modal.show{visibility:visible;opacity:1}
        .modal-card{background:#fff;border-radius:12px;max-width:880px;width:100%;padding:18px;max-height:calc(100vh - 60px);overflow:auto}
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

                <div class="analytics-grid">
                    <div class="card metric-card pending">
                        <div>
                            <strong>Pending Today</strong>
                            <div class="metric-value">{{ $analytics['today_status_counts']['pending'] ?? 0 }}</div>
                        </div>
                        <div class="metric-note">Reports created today</div>
                    </div>
                    <div class="card metric-card in-progress">
                        <div>
                            <strong>In Progress Today</strong>
                            <div class="metric-value">{{ $analytics['today_status_counts']['in_progress'] ?? 0 }}</div>
                        </div>
                        <div class="metric-note">Reports created today</div>
                    </div>
                    <div class="card metric-card resolved">
                        <div>
                            <strong>Resolved Today</strong>
                            <div class="metric-value">{{ $analytics['today_status_counts']['resolved'] ?? 0 }}</div>
                        </div>
                        <div class="metric-note">Reports created today</div>
                    </div>
                </div>

                <div class="charts-grid">
                    <div class="chart-card wide">
                        <div class="chart-toolbar">
                            <div>
                                <h3>Report Trend</h3>
                                <div class="muted">Daily report volume for the last 7 days, this month, or today</div>
                            </div>
                            <select id="trendRange" class="chart-select" aria-label="Select trend range">
                                <option value="today" selected>Today</option>
                                <option value="seven_days">Last 7 Days</option>
                                <option value="month">This Month</option>
                            </select>
                        </div>
                        <div id="trendChart" class="chart-box"></div>
                    </div>

                    <div class="chart-card">
                        <h3>Animal Type Distribution</h3>
                        <div id="animalTypeChart" class="chart-box tall"></div>
                    </div>

                    <div class="chart-card">
                        <h3>Report status</h3>
                        <div id="statusBarChart" class="chart-box tall"></div>
                    </div>

                    <div class="chart-card">
                        <h3>Vaccinated vs Unvaccinated</h3>
                        <div id="vaccinationChart" class="chart-box tall"></div>
                    </div>

                    <div class="chart-card">
                        <h3>Most Registered Animal Type</h3>
                        <div id="registeredPetTypeChart" class="chart-box tall"></div>
                    </div>
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
                <div>
                    <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:18px">
                        <div><strong>Pet Directory</strong><div class="muted">Explore all registered pets</div></div>
                    </div>

                    <!-- Vaccination Status Tabs -->
                    <div class="tabs">
                        <button class="tab active" onclick="filterPets('all')" id="tab-all">All Pets <span class="muted" style="margin-left:6px">({{ count($pets_by_status['vaccinated']) + count($pets_by_status['not_vaccinated']) + count($pets_by_status['unknown']) }})</span></button>
                        <button class="tab" onclick="filterPets('vaccinated')" id="tab-vaccinated">Vaccinated <span class="muted" style="margin-left:6px">({{ count($pets_by_status['vaccinated']) }})</span></button>
                        <button class="tab" onclick="filterPets('not_vaccinated')" id="tab-not-vaccinated">Unvaccinated <span class="muted" style="margin-left:6px">({{ count($pets_by_status['not_vaccinated']) }})</span></button>
                        <button class="tab" onclick="filterPets('unknown')" id="tab-unknown">Unknown Status <span class="muted" style="margin-left:6px">({{ count($pets_by_status['unknown']) }})</span></button>
                    </div>

                    <!-- All Pets Grid -->
                    <div id="pets-all" class="tab-panel">
                        @php
                            $allPets = collect($pets_by_status['vaccinated'])->merge($pets_by_status['not_vaccinated'])->merge($pets_by_status['unknown']);
                        @endphp
                        @if ($allPets->count() > 0)
                            <div style="display:grid;grid-template-columns:repeat(auto-fill,minmax(240px,1fr));gap:16px">
                                @foreach ($allPets as $pet)
                                    @include('admin.pet-card', ['pet' => $pet])
                                @endforeach
                            </div>
                        @else
                            <div class="muted">No pets registered yet.</div>
                        @endif
                    </div>

                    <!-- Vaccinated Pets Grid -->
                    <div id="pets-vaccinated" class="tab-panel hidden">
                        @if ($pets_by_status['vaccinated']->count() > 0)
                            <div style="display:grid;grid-template-columns:repeat(auto-fill,minmax(240px,1fr));gap:16px">
                                @foreach ($pets_by_status['vaccinated'] as $pet)
                                    @include('admin.pet-card', ['pet' => $pet])
                                @endforeach
                            </div>
                        @else
                            <div class="muted">No vaccinated pets.</div>
                        @endif
                    </div>

                    <!-- Unvaccinated Pets Grid -->
                    <div id="pets-not_vaccinated" class="tab-panel hidden">
                        @if ($pets_by_status['not_vaccinated']->count() > 0)
                            <div style="display:grid;grid-template-columns:repeat(auto-fill,minmax(240px,1fr));gap:16px">
                                @foreach ($pets_by_status['not_vaccinated'] as $pet)
                                    @include('admin.pet-card', ['pet' => $pet])
                                @endforeach
                            </div>
                        @else
                            <div class="muted">No unvaccinated pets.</div>
                        @endif
                    </div>

                    <!-- Unknown Status Pets Grid -->
                    <div id="pets-unknown" class="tab-panel hidden">
                        @if ($pets_by_status['unknown']->count() > 0)
                            <div style="display:grid;grid-template-columns:repeat(auto-fill,minmax(240px,1fr));gap:16px">
                                @foreach ($pets_by_status['unknown'] as $pet)
                                    @include('admin.pet-card', ['pet' => $pet])
                                @endforeach
                            </div>
                        @else
                            <div class="muted">No pets with unknown vaccination status.</div>
                        @endif
                    </div>
                </div>
            @elseif ($section === 'report-management')
                <div class="card">
                    <div class="report-toolbar">
                        <div>
                            <strong>Report Management</strong>
                            <div class="muted">Browse all submitted reports and open report details</div>
                        </div>
                        <form method="GET" action="{{ route('admin.dashboard') }}" class="report-filters">
                            <input type="hidden" name="section" value="report-management">
                            <select name="report_status" class="report-filter" aria-label="Filter by status">
                                <option value="">All Statuses</option>
                                <option value="pending" {{ ($report_filters['status'] ?? '') === 'pending' ? 'selected' : '' }}>Pending</option>
                                <option value="in_progress" {{ ($report_filters['status'] ?? '') === 'in_progress' ? 'selected' : '' }}>In Progress</option>
                                <option value="resolved" {{ ($report_filters['status'] ?? '') === 'resolved' ? 'selected' : '' }}>Resolved</option>
                            </select>
                            <input
                                type="search"
                                name="report_search"
                                class="report-search"
                                placeholder="Search reports..."
                                value="{{ $report_filters['search'] ?? '' }}"
                            >
                            <button class="btn" type="submit">Filter</button>
                        </form>
                    </div>

                    @if ($reports->isEmpty())
                        <div class="muted">No reports have been submitted yet.</div>
                    @else
                        <div>
                            @foreach ($reports as $report)
                                @php
                                    $reportNextStatus = match ($report->status) {
                                        'pending' => 'in_progress',
                                        'in_progress' => 'resolved',
                                        default => null,
                                    };
                                @endphp
                                <div class="report-row" data-report-id="{{ $report->id }}">
                                    <div class="report-summary">
                                        <h4>Report #{{ $report->id }} — {{ ucfirst($report->report_type) }} ({{ $report->animal_type }})</h4>
                                        <span class="muted">Submitted: {{ $report->created_at->format('M d, Y') }}</span>
                                        <div style="margin-top:8px">
                                            <span class="report-status-pill {{ $report->status }}">{{ str_replace('_', ' ', $report->status) }}</span>
                                        </div>
                                    </div>
                                    <div class="report-actions">
                                        <button class="btn-ghost" type="button" onclick="openReport({{ $report->id }})">View</button>
                                        <button
                                            class="report-status-row-action"
                                            type="button"
                                            @if (!$reportNextStatus) disabled @endif
                                            data-next-status="{{ $reportNextStatus }}"
                                            onclick="changeReportStatus({{ $report->id }}, this.dataset.nextStatus)"
                                        >
                                            {{ $reportNextStatus === 'in_progress' ? 'Mark In Progress' : ($reportNextStatus === 'resolved' ? 'Mark Resolved' : 'Resolved') }}
                                        </button>
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
                <div style="display:flex;align-items:center;gap:10px">
                    <button id="reportStatusAction" class="btn-status" type="button" disabled>Resolved</button>
                    <button onclick="closeReportModal()" class="btn-ghost">Close</button>
                </div>
            </div>
            <div id="reportDetails"></div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/apexcharts"></script>
    <script>
        const analytics = @json($analytics ?? []);
        const trendData = analytics.trend_data || { today: { labels: [], data: [] }, seven_days: { labels: [], data: [] }, month: { labels: [], data: [] } };
        const statusBreakdown = analytics.status_breakdown || { pending: 0, in_progress: 0, resolved: 0 };
        const animalTypeDistribution = analytics.animal_type_distribution || {};
        const petVaccinationDistribution = analytics.pet_vaccination_distribution || { vaccinated: 0, unvaccinated: 0 };
        const registeredPetTypeDistribution = analytics.registered_pet_type_distribution || {};

        let trendChart;
        let statusBarChart;
        let animalTypeChart;
        let vaccinationChart;
        let registeredPetTypeChart;

        function buildTrendOptions(seriesData, labels) {
            return {
                chart: {
                    type: 'line',
                    height: 320,
                    toolbar: { show: false },
                    zoom: { enabled: false },
                    fontFamily: 'Inter, system-ui, -apple-system, Segoe UI, sans-serif',
                },
                series: [{ name: 'Reports', data: seriesData }],
                stroke: { curve: 'smooth', width: 5 },
                colors: ['#0f766e'],
                markers: { size: 6, colors: ['#0f766e'], strokeColors: '#fff', strokeWidth: 2, hover: { size: 8 } },
                dataLabels: { enabled: false },
                grid: { borderColor: '#e2e8f0', strokeDashArray: 4 },
                xaxis: { categories: labels, labels: { style: { colors: '#64748b' } } },
                yaxis: { labels: { style: { colors: '#64748b' } } },
                tooltip: { theme: 'light' },
                fill: { type: 'solid', opacity: 0.2 },
            };
        }

        function renderTrendChart(range) {
            const dataset = trendData[range] || trendData.seven_days;
            const options = buildTrendOptions(dataset.data || [], dataset.labels || []);

            if (!trendChart) {
                trendChart = new ApexCharts(document.querySelector('#trendChart'), options);
                trendChart.render();
                return;
            }

            trendChart.updateOptions({ xaxis: { categories: options.xaxis.categories } });
            trendChart.updateSeries([{ name: 'Reports', data: options.series[0].data }]);
        }

        function renderStatusBarChart() {
            const options = {
                chart: {
                    type: 'bar',
                    height: 320,
                    toolbar: { show: false },
                    fontFamily: 'Inter, system-ui, -apple-system, Segoe UI, sans-serif',
                },
                plotOptions: {
                    bar: {
                        horizontal: false,
                        columnWidth: '50%',
                        borderRadius: 8,
                    },
                },
                colors: ['#ef4444', '#f59e0b', '#10b981'],
                series: [{
                    name: 'Reports',
                    data: [
                        Number(statusBreakdown.pending || 0),
                        Number(statusBreakdown.in_progress || 0),
                        Number(statusBreakdown.resolved || 0),
                    ],
                }],
                xaxis: {
                    categories: ['Pending', 'In Progress', 'Resolved'],
                    labels: { style: { colors: '#64748b' } },
                },
                dataLabels: { enabled: true },
                grid: { borderColor: '#e2e8f0' },
                tooltip: { theme: 'light' },
            };

            statusBarChart = new ApexCharts(document.querySelector('#statusBarChart'), options);
            statusBarChart.render();
        }

        function renderAnimalTypeChart() {
            const labels = Object.keys(animalTypeDistribution);
            const values = labels.map(label => Number(animalTypeDistribution[label] || 0));
            const hasData = labels.length > 0;

            const options = {
                chart: {
                    type: 'donut',
                    height: 320,
                    fontFamily: 'Inter, system-ui, -apple-system, Segoe UI, sans-serif',
                },
                labels: hasData ? labels : ['No data'],
                series: hasData ? values : [1],
                colors: ['#0f766e', '#0284c7', '#8b5cf6', '#f59e0b', '#ef4444', '#14b8a6', '#64748b'],
                legend: { position: 'bottom' },
                dataLabels: { enabled: true },
                tooltip: { theme: 'light' },
                plotOptions: {
                    pie: {
                        donut: {
                            size: '68%',
                            labels: {
                                show: true,
                                total: {
                                    show: true,
                                    label: 'Total',
                                    formatter: () => values.reduce((sum, value) => sum + value, 0).toString(),
                                },
                            },
                        },
                    },
                },
                responsive: [{
                    breakpoint: 768,
                    options: { legend: { position: 'bottom' } },
                }],
            };

            animalTypeChart = new ApexCharts(document.querySelector('#animalTypeChart'), options);
            animalTypeChart.render();
        }

        function renderVaccinationChart() {
            const options = {
                chart: {
                    type: 'bar',
                    height: 320,
                    toolbar: { show: false },
                    fontFamily: 'Inter, system-ui, -apple-system, Segoe UI, sans-serif',
                },
                plotOptions: {
                    bar: {
                        horizontal: false,
                        columnWidth: '55%',
                        borderRadius: 8,
                    },
                },
                colors: ['#22c55e', '#ef4444'],
                series: [{
                    name: 'Pets',
                    data: [
                        Number(petVaccinationDistribution.vaccinated || 0),
                        Number(petVaccinationDistribution.unvaccinated || 0),
                    ],
                }],
                xaxis: {
                    categories: ['Vaccinated', 'Unvaccinated'],
                    labels: { style: { colors: '#64748b' } },
                },
                dataLabels: { enabled: true },
                grid: { borderColor: '#e2e8f0' },
                tooltip: { theme: 'light' },
            };

            vaccinationChart = new ApexCharts(document.querySelector('#vaccinationChart'), options);
            vaccinationChart.render();
        }

        function renderRegisteredPetTypeChart() {
            const labels = Object.keys(registeredPetTypeDistribution);
            const values = labels.map(label => Number(registeredPetTypeDistribution[label] || 0));
            const hasData = labels.length > 0;

            const options = {
                chart: {
                    type: 'donut',
                    height: 320,
                    fontFamily: 'Inter, system-ui, -apple-system, Segoe UI, sans-serif',
                },
                labels: hasData ? labels : ['No data'],
                series: hasData ? values : [1],
                colors: ['#0891b2', '#4f46e5', '#16a34a', '#f59e0b', '#ef4444', '#9333ea', '#0f766e'],
                legend: { position: 'bottom' },
                dataLabels: { enabled: true },
                tooltip: { theme: 'light' },
                plotOptions: {
                    pie: {
                        donut: {
                            size: '68%',
                            labels: {
                                show: true,
                                total: {
                                    show: true,
                                    label: 'Total',
                                    formatter: () => values.reduce((sum, value) => sum + value, 0).toString(),
                                },
                            },
                        },
                    },
                },
            };

            registeredPetTypeChart = new ApexCharts(document.querySelector('#registeredPetTypeChart'), options);
            registeredPetTypeChart.render();
        }

        function reportLabel(status) {
            return status ? status.replace('_', ' ') : 'unknown';
        }

        function nextStatus(status) {
            if (status === 'pending') {
                return 'in_progress';
            }

            if (status === 'in_progress') {
                return 'resolved';
            }

            return null;
        }

        function updateReportModalAction(status) {
            const actionButton = document.getElementById('reportStatusAction');
            if (!actionButton) {
                return;
            }

            const next = nextStatus(status);
            if (!next) {
                actionButton.textContent = 'Resolved';
                actionButton.disabled = true;
                actionButton.dataset.nextStatus = '';
                return;
            }

            actionButton.disabled = false;
            actionButton.textContent = next === 'in_progress' ? 'Mark In Progress' : 'Mark Resolved';
            actionButton.dataset.nextStatus = next;
        }

        function syncReportRow(id, status) {
            const row = document.querySelector(`[data-report-id="${id}"]`);
            if (!row) {
                return;
            }

            const statusPill = row.querySelector('.report-status-pill');
            if (statusPill) {
                statusPill.className = `report-status-pill ${status}`;
                statusPill.textContent = reportLabel(status);
            }

            const button = row.querySelector('.report-status-row-action');
            if (button) {
                const next = nextStatus(status);
                if (!next) {
                    button.textContent = 'Resolved';
                    button.disabled = true;
                    button.dataset.nextStatus = '';
                } else {
                    button.disabled = false;
                    button.textContent = next === 'in_progress' ? 'Mark In Progress' : 'Mark Resolved';
                    button.dataset.nextStatus = next;
                }
            }
        }

        function submitReportStatusUpdate(reportId, status) {
            return fetch(`{{ url('/admin/reports') }}/${reportId}/status`, {
                method: 'PATCH',
                headers: {
                    'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]')?.content || '',
                    'X-Requested-With': 'XMLHttpRequest',
                    'Content-Type': 'application/json',
                    'Accept': 'application/json',
                },
                body: JSON.stringify({ status }),
            }).then(async response => {
                const payload = await response.json();
                if (!response.ok) {
                    throw new Error(payload.message || 'Unable to update report status');
                }
                return payload.data;
            });
        }

        function changeReportStatus(reportId, status) {
            if (!status) {
                return;
            }

            submitReportStatusUpdate(reportId, status)
                .then(data => {
                    const report = reportData.find(item => item.id === reportId);
                    if (report) {
                        report.status = data.status;
                    }
                    syncReportRow(reportId, data.status);
                    updateReportModalAction(data.status);
                    const subtitle = document.getElementById('reportModalSubtitle');
                    if (subtitle) {
                        subtitle.textContent = `${report?.created_at || ''} • ${reportLabel(data.status)}`;
                    }
                })
                .catch(error => {
                    alert(error.message || 'Unable to update report status');
                });
        }

        document.addEventListener('DOMContentLoaded', () => {
            // Only render charts if they exist on the page
            if (document.getElementById('trendChart')) renderTrendChart('today');
            if (document.getElementById('statusChart')) renderStatusBarChart();
            if (document.getElementById('animalTypeChart')) renderAnimalTypeChart();
            if (document.getElementById('vaccinationChart')) renderVaccinationChart();
            if (document.getElementById('registeredPetTypeChart')) renderRegisteredPetTypeChart();

            const trendRange = document.getElementById('trendRange');
            if (trendRange) {
                trendRange.addEventListener('change', (event) => {
                    renderTrendChart(event.target.value);
                });
            }
        });

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
            document.getElementById('reportModalSubtitle').textContent = `${report.created_at} • ${reportLabel(report.status)}`;

            let mediaHtml = '';
            if (Array.isArray(report.image_paths) && report.image_paths.length) {
                mediaHtml += '<div class="report-media">' + report.image_paths.map(path => `<img src="/storage/${path}" alt="Report image">`).join('') + '</div>';
            }
            if (report.video_path) {
                mediaHtml += `<div class="report-media"><video controls><source src="/storage/${report.video_path}" type="video/mp4"></video></div>`;
            }

            document.getElementById('reportDetails').innerHTML = `
                <div class="report-card">
                    <div class="report-meta"><strong>Submitted by:</strong> ${report.user_name || '-'}<br><strong>Email:</strong> ${report.user_email || '-'}<br><strong>Contact:</strong> ${report.user_contact || '-'}<br><strong>Location:</strong> ${report.location_text || '-'}<br><strong>Coordinates:</strong> ${report.latitude || '-'}, ${report.longitude || '-'}<br><strong>Status:</strong> ${reportLabel(report.status)}</div>
                    <div class="report-meta" style="margin-top:12px"><strong>Description:</strong> ${report.description || '-'}</div>
                    ${mediaHtml || '<div class="muted">No media attached.</div>'}
                </div>
            `;

            updateReportModalAction(report.status);

            const statusActionButton = document.getElementById('reportStatusAction');
            if (statusActionButton) {
                statusActionButton.onclick = () => changeReportStatus(report.id, statusActionButton.dataset.nextStatus);
            }

            document.getElementById('reportModal').classList.add('show');
        }

        function closeModal() { document.getElementById('userModal').classList.remove('show'); }
        function closeReportModal() { document.getElementById('reportModal').classList.remove('show'); }

        function filterPets(status) {
            // Hide all tabs
            ['all', 'vaccinated', 'not_vaccinated', 'unknown'].forEach(s => {
                const panel = document.getElementById('pets-' + s);
                if (panel) panel.classList.add('hidden');
                const tab = document.getElementById('tab-' + s.replace('_', '-'));
                if (tab) tab.classList.remove('active');
            });

            // Show selected tab
            const selectedPanel = document.getElementById('pets-' + status);
            if (selectedPanel) selectedPanel.classList.remove('hidden');
            const selectedTab = document.getElementById('tab-' + status.replace('_', '-'));
            if (selectedTab) selectedTab.classList.add('active');
        }

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
