import 'package:flutter/material.dart';

import '../models/pet_model.dart';
import '../services/auth_service.dart';
import '../widgets/full_screen_image_viewer.dart';
import 'vaccination_form_screen.dart';

class PetDetailsScreen extends StatefulWidget {
  const PetDetailsScreen({
    super.key,
    required this.pet,
    required this.authService,
    required this.onUpdated,
  });

  final Pet pet;
  final AuthService authService;
  final Future<void> Function() onUpdated;

  @override
  State<PetDetailsScreen> createState() => _PetDetailsScreenState();
}

class _PetDetailsScreenState extends State<PetDetailsScreen> {
  late Pet _pet;

  @override
  void initState() {
    super.initState();
    _pet = widget.pet;
  }

  @override
  Widget build(BuildContext context) {
    final pet = _pet;
    final petPhotoPath = pet.petPhotoPath;
    final photoUrl = (petPhotoPath != null && petPhotoPath.isNotEmpty)
        ? widget.authService.apiService.mediaUrl(petPhotoPath)
        : null;
    final vaccinationCardPath = pet.vaccinationCardPath;
    final vaccinationCardUrl =
        (vaccinationCardPath != null && vaccinationCardPath.isNotEmpty)
        ? widget.authService.apiService.mediaUrl(vaccinationCardPath)
        : null;

    void openImageViewer({
      required String title,
      required ImageProvider imageProvider,
    }) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              FullScreenImageViewer(title: title, imageProvider: imageProvider),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Pet Details')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (photoUrl != null)
                GestureDetector(
                  onTap: () => openImageViewer(
                    title: 'Pet Photo',
                    imageProvider: NetworkImage(photoUrl),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Image.network(
                        photoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: const Color(0xFFF2F4F7),
                          alignment: Alignment.center,
                          child: const Icon(Icons.pets, size: 40),
                        ),
                      ),
                    ),
                  ),
                ),
              if (photoUrl != null) const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFD9E2EC)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pet.name,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _detail('Animal Type', _titleCase(pet.animalType)),
                    _detail(
                      'Breed',
                      (pet.breed == null || pet.breed!.isEmpty)
                          ? 'Not specified'
                          : pet.breed!,
                    ),
                    _detail('Age', '${pet.age} years old'),
                    _detail('Gender', _titleCase(pet.gender)),
                    _detail(
                      'Rabies Status',
                      pet.rabiesStatus == 'not_vaccinated'
                          ? 'Not Vaccinated'
                          : _titleCase(pet.rabiesStatus.replaceAll('_', ' ')),
                    ),
                    _detail(
                      'Last Vaccination Date',
                      pet.lastVaccinationDate == null
                          ? 'Not available'
                          : pet.lastVaccinationDate!
                                .toLocal()
                                .toString()
                                .split(' ')
                                .first,
                    ),
                    _detail(
                      'Vaccine Name',
                      (pet.lastVaccineName == null ||
                              pet.lastVaccineName!.isEmpty)
                          ? 'Not specified'
                          : pet.lastVaccineName!,
                    ),
                    _detail(
                      'Vaccination Card',
                      (vaccinationCardUrl == null)
                          ? 'Not uploaded'
                          : 'Uploaded',
                    ),
                  ],
                ),
              ),
              if (vaccinationCardUrl != null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFD9E2EC)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Vaccination Card Photo',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () => openImageViewer(
                          title: 'Vaccination Card Photo',
                          imageProvider: NetworkImage(vaccinationCardUrl),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: AspectRatio(
                            aspectRatio: 16 / 9,
                            child: Image.network(
                              vaccinationCardUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    color: const Color(0xFFF2F4F7),
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      Icons.receipt_long_outlined,
                                      size: 40,
                                    ),
                                  ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (pet.vaccinationRecords.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Vaccination History',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                ...pet.vaccinationRecords.map((record) {
                  final recordCardPath = record.vaccinationCardPath;
                  final recordCardUrl =
                      (recordCardPath != null && recordCardPath.isNotEmpty)
                      ? widget.authService.apiService.mediaUrl(recordCardPath)
                      : null;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFD9E2EC)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.vaccinationDate == null
                              ? 'Date not available'
                              : record.vaccinationDate!
                                    .toLocal()
                                    .toString()
                                    .split(' ')
                                    .first,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        if (record.vaccineName != null &&
                            record.vaccineName!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text('Vaccine: ${record.vaccineName!}'),
                        ],
                        if (recordCardUrl != null) ...[
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: () => openImageViewer(
                              title: 'Vaccination Card Photo',
                              imageProvider: NetworkImage(recordCardUrl),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: AspectRatio(
                                aspectRatio: 16 / 9,
                                child: Image.network(
                                  recordCardUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                        color: const Color(0xFFF2F4F7),
                                        alignment: Alignment.center,
                                        child: const Icon(
                                          Icons.receipt_long_outlined,
                                          size: 40,
                                        ),
                                      ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _openVaccinationUpdate,
                  icon: const Icon(Icons.medical_services_outlined),
                  label: const Text('Add Vaccination'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _titleCase(String value) {
    if (value.isEmpty) {
      return value;
    }

    return value
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  Future<void> _openVaccinationUpdate() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => VaccinationFormScreen(
          authService: widget.authService,
          pet: _pet,
          onUpdated: (pet) async {
            if (!mounted) {
              return;
            }
            setState(() => _pet = pet);
            await widget.onUpdated();
          },
        ),
      ),
    );
  }
}
