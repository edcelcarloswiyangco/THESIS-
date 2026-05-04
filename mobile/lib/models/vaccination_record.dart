class VaccinationRecord {
  const VaccinationRecord({
    required this.id,
    this.vaccinationDate,
    this.vaccineName,
    this.vaccinationCardPath,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final DateTime? vaccinationDate;
  final String? vaccineName;
  final String? vaccinationCardPath;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory VaccinationRecord.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value is String) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    return VaccinationRecord(
      id: int.tryParse('${json['id']}') ?? 0,
      vaccinationDate: parseDate(json['vaccination_date']),
      vaccineName: json['vaccine_name'] as String?,
      vaccinationCardPath: json['vaccination_card_path'] as String?,
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
    );
  }
}
