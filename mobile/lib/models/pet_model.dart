import 'vaccination_record.dart';

class Pet {
  const Pet({
    required this.id,
    required this.name,
    required this.animalType,
    this.breed,
    required this.age,
    required this.gender,
    required this.rabiesStatus,
    this.lastVaccinationDate,
    this.lastVaccineName,
    this.petPhotoPath,
    this.vaccinationCardPath,
    this.vaccinationRecords = const [],
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String name;
  final String animalType;
  final String? breed;
  final int age;
  final String gender;
  final String rabiesStatus;
  final DateTime? lastVaccinationDate;
  final String? lastVaccineName;
  final String? petPhotoPath;
  final String? vaccinationCardPath;
  final List<VaccinationRecord> vaccinationRecords;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Pet.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value is String) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    return Pet(
      id: int.tryParse('${json['id']}') ?? 0,
      name: '${json['name'] ?? ''}',
      animalType: '${json['animal_type'] ?? ''}',
      breed: json['breed'] as String?,
      age: int.tryParse('${json['age']}') ?? 0,
      gender: '${json['gender'] ?? 'unknown'}',
      rabiesStatus: '${json['rabies_status'] ?? 'unknown'}',
      lastVaccinationDate: parseDate(json['last_vaccination_date']),
      lastVaccineName: json['last_vaccine_name'] as String?,
      petPhotoPath: json['pet_photo_path'] as String?,
      vaccinationCardPath: json['vaccination_card_path'] as String?,
      vaccinationRecords:
          (json['vaccination_records'] as List<dynamic>? ?? const [])
              .whereType<Map<String, dynamic>>()
              .map(VaccinationRecord.fromJson)
              .toList(),
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'animal_type': animalType,
      'breed': breed,
      'age': age,
      'gender': gender,
      'rabies_status': rabiesStatus,
      'last_vaccination_date': lastVaccinationDate
          ?.toIso8601String()
          .split('T')
          .first,
      'last_vaccine_name': lastVaccineName,
    };
  }
}
