<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\AnimalReport;
use App\Models\Pet;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\View\View;

class DashboardController extends Controller
{
    public function index(): View
    {
        $hasReportsTable = Schema::hasTable('animal_reports');
        $hasPetsTable = Schema::hasTable('pets');
        $reportSearch = trim((string) request('report_search', ''));
        $reportStatusFilter = trim((string) request('report_status', ''));

        $users = User::query()->latest()->get();

        foreach ($users as $user) {
            $user->reports_count = $hasReportsTable
                ? DB::table('animal_reports')->where('user_id', $user->id)->count()
                : 0;
            $user->status = $user->email_verified_at ? 'active' : 'inactive';
        }

        $reportsQuery = $hasReportsTable ? AnimalReport::query()->with('user') : null;

        if ($reportsQuery) {
            if ($reportStatusFilter !== '' && in_array($reportStatusFilter, ['pending', 'in_progress', 'resolved'], true)) {
                $reportsQuery->where('status', $reportStatusFilter);
            }

            if ($reportSearch !== '') {
                $reportsQuery->where(function ($query) use ($reportSearch) {
                    $query->where('report_type', 'like', '%' . $reportSearch . '%')
                        ->orWhere('animal_type', 'like', '%' . $reportSearch . '%')
                        ->orWhere('location_text', 'like', '%' . $reportSearch . '%')
                        ->orWhere('description', 'like', '%' . $reportSearch . '%')
                        ->orWhereHas('user', function ($userQuery) use ($reportSearch) {
                            $userQuery->where('full_name', 'like', '%' . $reportSearch . '%')
                                ->orWhere('name', 'like', '%' . $reportSearch . '%')
                                ->orWhere('email', 'like', '%' . $reportSearch . '%');
                        });
                });
            }
        }

        $reports = $reportsQuery
            ? $reportsQuery->latest('id')->get()
            : collect();

        $todayStatusCounts = [
            'pending' => 0,
            'in_progress' => 0,
            'resolved' => 0,
        ];

        $statusBreakdown = [
            'pending' => 0,
            'in_progress' => 0,
            'resolved' => 0,
        ];

        $trendData = [
            'today' => ['labels' => [], 'data' => []],
            'seven_days' => ['labels' => [], 'data' => []],
            'month' => ['labels' => [], 'data' => []],
        ];

        $animalTypeDistribution = [];
        $petVaccinationDistribution = [
            'vaccinated' => 0,
            'unvaccinated' => 0,
        ];
        $registeredPetTypeDistribution = [];

        if ($hasReportsTable) {
            $totalReports = AnimalReport::query()->count();

            $todayRows = DB::table('animal_reports')
                ->select('status', DB::raw('count(*) as total'))
                ->whereDate('created_at', Carbon::today())
                ->groupBy('status')
                ->pluck('total', 'status')
                ->all();

            foreach ($todayStatusCounts as $status => $defaultCount) {
                $todayStatusCounts[$status] = (int) ($todayRows[$status] ?? $defaultCount);
            }

            $statusRows = DB::table('animal_reports')
                ->select('status', DB::raw('count(*) as total'))
                ->groupBy('status')
                ->pluck('total', 'status')
                ->all();

            foreach ($statusBreakdown as $status => $defaultCount) {
                $statusBreakdown[$status] = (int) ($statusRows[$status] ?? $defaultCount);
            }

            $todayHourRows = DB::table('animal_reports')
                ->select(DB::raw('HOUR(created_at) as report_hour'), DB::raw('count(*) as total'))
                ->whereBetween('created_at', [Carbon::today()->startOfDay(), Carbon::today()->endOfDay()])
                ->groupBy(DB::raw('HOUR(created_at)'))
                ->pluck('total', 'report_hour')
                ->all();

            for ($hour = 0; $hour < 24; $hour++) {
                $trendData['today']['labels'][] = Carbon::today()->startOfDay()->addHours($hour)->format('g A');
                $trendData['today']['data'][] = (int) ($todayHourRows[$hour] ?? 0);
            }

            $sevenDaysStart = Carbon::today()->subDays(6);
            $sevenDayRows = DB::table('animal_reports')
                ->select(DB::raw('DATE(created_at) as report_date'), DB::raw('count(*) as total'))
                ->whereBetween('created_at', [$sevenDaysStart->copy()->startOfDay(), Carbon::today()->endOfDay()])
                ->groupBy(DB::raw('DATE(created_at)'))
                ->pluck('total', 'report_date')
                ->all();

            for ($index = 0; $index < 7; $index++) {
                $date = $sevenDaysStart->copy()->addDays($index);
                $trendData['seven_days']['labels'][] = $date->format('D');
                $trendData['seven_days']['data'][] = (int) ($sevenDayRows[$date->toDateString()] ?? 0);
            }

            $monthStart = Carbon::now()->startOfMonth();
            $monthRows = DB::table('animal_reports')
                ->select(DB::raw('DATE(created_at) as report_date'), DB::raw('count(*) as total'))
                ->whereBetween('created_at', [$monthStart->copy()->startOfDay(), Carbon::now()->endOfMonth()])
                ->groupBy(DB::raw('DATE(created_at)'))
                ->pluck('total', 'report_date')
                ->all();

            for ($date = $monthStart->copy(); $date->lte(Carbon::today()); $date->addDay()) {
                $trendData['month']['labels'][] = (string) $date->day;
                $trendData['month']['data'][] = (int) ($monthRows[$date->toDateString()] ?? 0);
            }

            $animalTypeDistribution = DB::table('animal_reports')
                ->select('animal_type', DB::raw('count(*) as total'))
                ->groupBy('animal_type')
                ->orderByDesc('total')
                ->pluck('total', 'animal_type')
                ->all();
        } else {
            $totalReports = 0;
        }

        if ($hasPetsTable) {
            $petVaccinationRows = DB::table('pets')
                ->select('rabies_status', DB::raw('count(*) as total'))
                ->groupBy('rabies_status')
                ->pluck('total', 'rabies_status')
                ->all();

            $petVaccinationDistribution['vaccinated'] = (int) ($petVaccinationRows['vaccinated'] ?? 0);
            $petVaccinationDistribution['unvaccinated'] = (int) ($petVaccinationRows['not_vaccinated'] ?? 0);

            $registeredPetTypeDistribution = DB::table('pets')
                ->select('animal_type', DB::raw('count(*) as total'))
                ->groupBy('animal_type')
                ->orderByDesc('total')
                ->pluck('total', 'animal_type')
                ->all();
        }

        $totalPets = $hasPetsTable ? DB::table('pets')->count() : 0;

        // Fetch pets grouped by rabies vaccination status
        $petsByStatus = [
            'vaccinated' => [],
            'not_vaccinated' => [],
            'unknown' => [],
        ];

        if ($hasPetsTable) {
            $petsByStatus['vaccinated'] = Pet::where('rabies_status', 'vaccinated')->with('user')->get();
            $petsByStatus['not_vaccinated'] = Pet::where('rabies_status', 'not_vaccinated')->with('user')->get();
            $petsByStatus['unknown'] = Pet::where('rabies_status', 'unknown')->with('user')->get();
        }

        return view('admin.dashboard', [
            'users' => $users,
            'summary' => [
                'total_users' => User::query()->count(),
                'total_reports' => $totalReports,
                'total_pets' => $totalPets,
            ],
            'reports' => $reports,
            'report_filters' => [
                'search' => $reportSearch,
                'status' => $reportStatusFilter,
            ],
            'pets_by_status' => $petsByStatus,
            'analytics' => [
                'today_status_counts' => $todayStatusCounts,
                'status_breakdown' => $statusBreakdown,
                'trend_data' => $trendData,
                'animal_type_distribution' => $animalTypeDistribution,
                'pet_vaccination_distribution' => $petVaccinationDistribution,
                'registered_pet_type_distribution' => $registeredPetTypeDistribution,
            ],
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

    public function updateReportStatus(AnimalReport $report)
    {
        if ($report->status === 'resolved') {
            return response()->json([
                'message' => 'Resolved reports cannot be changed.',
                'status' => $report->status,
            ], 422);
        }

        $nextStatus = match ($report->status) {
            'pending' => 'in_progress',
            'in_progress' => 'resolved',
            default => 'pending',
        };

        $report->status = $nextStatus;
        if ($nextStatus === 'resolved' && !$report->resolved_at) {
            $report->resolved_at = now();
        }
        $report->save();

        return response()->json([
            'message' => 'Report status updated successfully.',
            'data' => [
                'id' => $report->id,
                'status' => $report->status,
                'resolved_at' => optional($report->resolved_at)->toIso8601String(),
            ],
        ]);
    }
}
