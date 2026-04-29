import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../models/animal_report.dart';
import '../services/api_service.dart';

class ReportDetailScreen extends StatefulWidget {
  const ReportDetailScreen({
    super.key,
    required this.report,
    required this.apiService,
  });

  final AnimalReport report;
  final ApiService apiService;

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  VideoPlayerController? _videoController;
  Future<void>? _videoInitFuture;

  @override
  void initState() {
    super.initState();
    final videoPath = widget.report.videoPath;
    if (videoPath != null && videoPath.isNotEmpty) {
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(widget.apiService.mediaUrl(videoPath)),
      );
      _videoInitFuture = _videoController!.initialize().then((_) {
        _videoController!.setLooping(false);
        setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  String _formatDate(DateTime? dateTime) {
    if (dateTime == null) {
      return 'Unknown';
    }

    final local = dateTime.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.year}-$month-$day $hour:$minute';
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

  String _formatDuration(Duration duration) {
    if (duration.inDays >= 1) {
      final days = duration.inDays;
      final hours = duration.inHours.remainder(24);
      if (hours == 0) {
        return days == 1 ? '1 day' : '$days days';
      }
      return days == 1 ? '1 day $hours hours' : '$days days $hours hours';
    }

    if (duration.inHours >= 1) {
      final hours = duration.inHours;
      final minutes = duration.inMinutes.remainder(60);
      if (minutes == 0) {
        return hours == 1 ? '1 hour' : '$hours hours';
      }
      return hours == 1 ? '1 hour $minutes minutes' : '$hours hours $minutes minutes';
    }

    final minutes = duration.inMinutes;
    return minutes <= 1 ? '1 minute' : '$minutes minutes';
  }

  Widget _buildMediaTile({
    required String label,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD9E2EC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _buildPhotoGrid() {
    final imagePaths = widget.report.imagePaths;
    if (imagePaths.isEmpty) {
      return _buildMediaTile(
        label: 'Photos',
        child: const Text('No photos were attached to this report.'),
      );
    }

    return _buildMediaTile(
      label: 'Photos (${imagePaths.length})',
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: imagePaths.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1,
        ),
        itemBuilder: (context, index) {
          final imagePath = imagePaths[index];
          final imageUrl = widget.apiService.mediaUrl(imagePath);
          return ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: const Color(0xFFF8FAFC),
                  alignment: Alignment.center,
                  child: const Icon(Icons.broken_image_outlined),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildVideoPlayer() {
    final controller = _videoController;
    final videoPath = widget.report.videoPath;

    if (controller == null || videoPath == null || videoPath.isEmpty) {
      return _buildMediaTile(
        label: 'Video',
        child: const Text('No video was attached to this report.'),
      );
    }

    return _buildMediaTile(
      label: 'Video',
      child: FutureBuilder<void>(
        future: _videoInitFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              height: 220,
              child: Center(child: CircularProgressIndicator()),
            );
          }

          if (controller.value.hasError) {
            return SizedBox(
              height: 220,
              child: Center(
                child: Text(
                  'Unable to load video.',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: controller.value.aspectRatio == 0
                    ? 16 / 9
                    : controller.value.aspectRatio,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: VideoPlayer(controller),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  FilledButton.icon(
                    onPressed: () {
                      setState(() {
                        if (controller.value.isPlaying) {
                          controller.pause();
                        } else {
                          controller.play();
                        }
                      });
                    },
                    icon: Icon(
                      controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                    ),
                    label: Text(controller.value.isPlaying ? 'Pause' : 'Play'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      videoPath.split('/').last,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.report;
    final isResolved = report.resolvedAt != null;
    final reportedAgo = _formatRelativeTime(report.createdAt);
    final resolutionLabel = isResolved && report.createdAt != null
        ? _formatDuration(report.resolvedAt!.difference(report.createdAt!))
        : 'Still pending';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report details'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF102A43), Color(0xFF1F8A70)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report.reportType,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  report.status.toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFFD9E2EC),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Reported $reportedAgo',
                  style: const TextStyle(color: Color(0xFFF4F7F7)),
                ),
                if (isResolved) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Resolved in $resolutionLabel',
                    style: const TextStyle(color: Color(0xFFF4F7F7)),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildMediaTile(
            label: 'Report info',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Animal type: ${report.animalType}'),
                const SizedBox(height: 6),
                Text('Location / street: ${report.locationText}'),
                if (report.latitude != null && report.longitude != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Coordinates: ${report.latitude!.toStringAsFixed(6)}, ${report.longitude!.toStringAsFixed(6)}',
                  ),
                ],
                const SizedBox(height: 6),
                Text('Submitted: ${_formatDate(report.createdAt)}'),
                const SizedBox(height: 6),
                Text('Description: ${report.description}'),
                if (isResolved) ...[
                  const SizedBox(height: 6),
                  Text('Resolved at: ${_formatDate(report.resolvedAt)}'),
                ] else ...[
                  const SizedBox(height: 6),
                  const Text('Resolved at: Still pending'),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildPhotoGrid(),
          const SizedBox(height: 16),
          _buildVideoPlayer(),
        ],
      ),
    );
  }
}
