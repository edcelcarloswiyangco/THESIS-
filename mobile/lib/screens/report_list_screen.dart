import 'package:flutter/material.dart';

import '../models/animal_report.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'report_detail_screen.dart';

class ReportListScreen extends StatefulWidget {
  const ReportListScreen({super.key, required this.authService});

  final AuthService authService;

  @override
  State<ReportListScreen> createState() => _ReportListScreenState();
}

class _ReportListScreenState extends State<ReportListScreen> {
  Future<List<AnimalReport>>? _reportsFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    final token = widget.authService.token;
    if (token == null || token.isEmpty) {
      setState(() {
        _reportsFuture = Future.error(
          ApiException('Your session expired. Please login again.'),
        );
      });
      return;
    }

    setState(() {
      _reportsFuture = widget.authService.apiService.fetchReports(token);
    });
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return const Color(0xFF027A48);
      case 'rejected':
        return const Color(0xFFB42318);
      default:
        return const Color(0xFFB54708);
    }
  }

  String _formatRelativeTime(DateTime? dateTime) {
    if (dateTime == null) {
      return 'Unknown time';
    }

    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays >= 1) {
      final days = difference.inDays;
      return days == 1 ? '1 day ago' : '$days days ago';
    }

    if (difference.inHours >= 1) {
      final hours = difference.inHours;
      return hours == 1 ? '1 hour ago' : '$hours hours ago';
    }

    final minutes = difference.inMinutes;
    if (minutes <= 1) {
      return 'Just now';
    }

    return '$minutes minutes ago';
  }

  void _openDetails(AnimalReport report) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReportDetailScreen(
          report: report,
          apiService: widget.authService.apiService,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async => _reload(),
        child: FutureBuilder<List<AnimalReport>>(
          future: _reportsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const SizedBox(height: 60),
                  Icon(Icons.report_outlined, size: 72, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    snapshot.error.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _reload,
                    child: const Text('Retry'),
                  ),
                ],
              );
            }

            final reports = snapshot.data ?? const <AnimalReport>[];

            if (reports.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const SizedBox(height: 40),
                  const Text(
                    'Reports',
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFD9E2EC)),
                    ),
                    child: const Text('No reports submitted yet.'),
                  ),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: reports.length + 1,
              separatorBuilder: (_, separatorIndex) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return const Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Text(
                      'Reports',
                      style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
                    ),
                  );
                }

                final report = reports[index - 1];
                return InkWell(
                  onTap: () => _openDetails(report),
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFD9E2EC)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                report.reportType,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: _statusColor(report.status).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                report.status,
                                style: TextStyle(
                                  color: _statusColor(report.status),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('Animal: ${report.animalType}'),
                        const SizedBox(height: 4),
                        Text('Location: ${report.locationText}'),
                        const SizedBox(height: 4),
                        Text('Reported: ${_formatRelativeTime(report.createdAt)}'),
                        const SizedBox(height: 4),
                        Text('Photos: ${report.imagePaths.length}'),
                        const SizedBox(height: 4),
                        Text('Video: ${report.videoPath == null ? 'none' : 'attached'}'),
                        const SizedBox(height: 8),
                        Text(
                          report.description,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey.shade800),
                        ),
                        const SizedBox(height: 10),
                        const Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'Tap for full details',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
