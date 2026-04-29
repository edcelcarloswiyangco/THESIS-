class AnimalReport {
  AnimalReport({
    required this.id,
    required this.reportType,
    required this.animalType,
    required this.locationText,
    required this.description,
    required this.status,
    required this.createdAt,
    required this.imagePaths,
    required this.videoPath,
    required this.resolvedAt,
    required this.latitude,
    required this.longitude,
  });

  final int id;
  final String reportType;
  final String animalType;
  final String locationText;
  final String description;
  final String status;
  final DateTime? createdAt;
  final List<String> imagePaths;
  final String? videoPath;
  final DateTime? resolvedAt;
  final double? latitude;
  final double? longitude;

  factory AnimalReport.fromJson(Map<String, dynamic> json) {
    final rawPaths = json['image_paths'];
    final imagePaths = rawPaths is List
        ? rawPaths.whereType<String>().toList()
        : <String>[];

    double? parseDouble(dynamic value) {
      if (value is num) {
        return value.toDouble();
      }

      if (value is String) {
        return double.tryParse(value);
      }

      return null;
    }

    DateTime? parseDate(dynamic value) {
      if (value is String) {
        return DateTime.tryParse(value);
      }

      return null;
    }

    return AnimalReport(
      id: int.tryParse('${json['id']}') ?? 0,
      reportType: '${json['report_type'] ?? ''}',
      animalType: '${json['animal_type'] ?? ''}',
      locationText: '${json['location_text'] ?? ''}',
      description: '${json['description'] ?? ''}',
      status: '${json['status'] ?? ''}',
      createdAt: parseDate(json['created_at']),
      imagePaths: imagePaths,
      videoPath: json['video_path']?.toString(),
      resolvedAt: parseDate(json['resolved_at']),
      latitude: parseDouble(json['latitude']),
      longitude: parseDouble(json['longitude']),
    );
  }
}