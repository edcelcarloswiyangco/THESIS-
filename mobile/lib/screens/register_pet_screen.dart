import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/pet_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class RegisterPetScreen extends StatefulWidget {
  const RegisterPetScreen({
    super.key,
    required this.authService,
    required this.onPetRegistered,
    this.petToEdit,
  });

  final AuthService authService;
  final Future<void> Function(Pet pet) onPetRegistered;
  final Pet? petToEdit;

  @override
  State<RegisterPetScreen> createState() => _RegisterPetScreenState();
}

class _RegisterPetScreenState extends State<RegisterPetScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _breedController;
  late final TextEditingController _ageController;
  late final TextEditingController _vaccineNameController;

  String _animalType = '';
  String _gender = '';
  String _rabiesStatus = 'unknown';
  DateTime? _lastVaccinationDate;
  XFile? _petPhotoFile;
  XFile? _vaccinationCardFile;
  bool _isSubmitting = false;
  String? _errorMessage;

  final List<String> _animalTypes = [
    'dog',
    'cat',
    'bird',
    'rabbit',
    'hamster',
    'guinea pig',
    'other',
  ];
  final List<String> _genders = ['male', 'female'];
  final List<String> _rabiesStatuses = [
    'vaccinated',
    'not_vaccinated',
    'unknown',
  ];

  final Map<String, String> _animalTypeLabels = const {
    'dog': 'Dog',
    'cat': 'Cat',
    'bird': 'Bird',
    'rabbit': 'Rabbit',
    'hamster': 'Hamster',
    'guinea pig': 'Guinea Pig',
    'other': 'Other',
  };

  final Map<String, String> _genderLabels = const {
    'male': 'Male',
    'female': 'Female',
  };

  final Map<String, String> _rabiesStatusLabels = const {
    'vaccinated': 'Vaccinated',
    'not_vaccinated': 'Not Vaccinated',
    'unknown': 'Unknown',
  };

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.petToEdit?.name ?? '');
    _breedController = TextEditingController(
      text: widget.petToEdit?.breed ?? '',
    );
    _ageController = TextEditingController(
      text: widget.petToEdit?.age.toString() ?? '',
    );
    _vaccineNameController = TextEditingController(
      text: widget.petToEdit?.lastVaccineName ?? '',
    );

    _animalType = (widget.petToEdit?.animalType ?? '').toLowerCase();
    _gender = (widget.petToEdit?.gender ?? '').toLowerCase();
    _rabiesStatus = (widget.petToEdit?.rabiesStatus ?? 'unknown')
        .toLowerCase()
        .replaceAll(' ', '_');

    if (!_animalTypes.contains(_animalType)) {
      _animalType = '';
    }
    if (!_genders.contains(_gender)) {
      _gender = '';
    }
    if (!_rabiesStatuses.contains(_rabiesStatus)) {
      _rabiesStatus = 'unknown';
    }

    _lastVaccinationDate = widget.petToEdit?.lastVaccinationDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _ageController.dispose();
    _vaccineNameController.dispose();
    super.dispose();
  }

  Future<void> _pickVaccinationCard() async {
    final picker = ImagePicker();
    try {
      final file = await picker.pickImage(source: ImageSource.gallery);
      if (file != null) {
        setState(() {
          _vaccinationCardFile = file;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
      }
    }
  }

  Future<void> _pickPetPhoto() async {
    final picker = ImagePicker();
    try {
      final file = await picker.pickImage(source: ImageSource.gallery);
      if (file != null) {
        setState(() {
          _petPhotoFile = file;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to pick pet photo: $e')));
      }
    }
  }

  Future<void> _selectVaccinationDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _lastVaccinationDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _lastVaccinationDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (_animalType.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an animal type')),
      );
      return;
    }

    if (_gender.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a gender')));
      return;
    }

    if (_rabiesStatus == 'vaccinated') {
      if (_lastVaccinationDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select last vaccination date')),
        );
        return;
      }

      final hasExistingCard =
          widget.petToEdit?.vaccinationCardPath != null &&
          widget.petToEdit!.vaccinationCardPath!.isNotEmpty;

      if (_vaccinationCardFile == null && !hasExistingCard) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please upload vaccination card')),
        );
        return;
      }
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final token = widget.authService.token;
      if (token == null || token.isEmpty) {
        throw ApiException('Your session expired. Please login again.');
      }

      Uint8List? cardBytes;
      String? cardName;
      Uint8List? petPhotoBytes;
      String? petPhotoName;
      if (_vaccinationCardFile != null) {
        cardBytes = await _vaccinationCardFile!.readAsBytes();
        cardName = _vaccinationCardFile!.name;
      }
      if (_petPhotoFile != null) {
        petPhotoBytes = await _petPhotoFile!.readAsBytes();
        petPhotoName = _petPhotoFile!.name;
      }

      if (widget.petToEdit != null) {
        final result = await widget.authService.apiService.updatePet(
          token: token,
          petId: widget.petToEdit!.id,
          name: _nameController.text.trim(),
          animalType: _animalType.toLowerCase(),
          breed: _breedController.text.trim(),
          age: int.parse(_ageController.text.trim()),
          gender: _gender,
          rabiesStatus: _rabiesStatus,
          lastVaccinationDate: _rabiesStatus == 'vaccinated'
              ? _lastVaccinationDate
              : null,
          vaccineName: _rabiesStatus == 'vaccinated'
              ? _vaccineNameController.text.trim()
              : null,
          vaccinationCardBytes: cardBytes,
          vaccinationCardName: cardName,
          petPhotoBytes: petPhotoBytes,
          petPhotoName: petPhotoName,
        );
        final petData = result['data'] as Map<String, dynamic>?;
        if (petData != null) {
          final pet = Pet.fromJson(petData);
          await widget.onPetRegistered(pet);
        }
      } else {
        final result = await widget.authService.apiService.createPet(
          token: token,
          name: _nameController.text.trim(),
          animalType: _animalType,
          breed: _breedController.text.trim(),
          age: int.parse(_ageController.text.trim()),
          gender: _gender,
          rabiesStatus: _rabiesStatus,
          lastVaccinationDate: _rabiesStatus == 'vaccinated'
              ? _lastVaccinationDate
              : null,
          vaccineName: _rabiesStatus == 'vaccinated'
              ? _vaccineNameController.text.trim()
              : null,
          vaccinationCardBytes: cardBytes,
          vaccinationCardName: cardName,
          petPhotoBytes: petPhotoBytes,
          petPhotoName: petPhotoName,
        );

        final petData = result['data'] as Map<String, dynamic>?;
        if (petData != null) {
          final pet = Pet.fromJson(petData);
          await widget.onPetRegistered(pet);
        }
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } on ApiException catch (error) {
      setState(() {
        _errorMessage = error.message;
      });
    } catch (error) {
      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isVaccinated = _rabiesStatus == 'vaccinated';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.petToEdit != null ? 'Edit Pet' : 'Register Pet'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Pet Name *'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter pet name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Card(
                  color: const Color(0xFFF8FAFC),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pet Photo',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 10),
                        if (_petPhotoFile != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE6FFFB),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.image,
                                    color: Color(0xFF0F766E),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _petPhotoFile!.name,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        FilledButton.icon(
                          onPressed: _pickPetPhoto,
                          icon: const Icon(Icons.photo_library_outlined),
                          label: const Text('Upload Pet Photo'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _animalType.isEmpty ? null : _animalType,
                  decoration: const InputDecoration(labelText: 'Animal Type *'),
                  items: _animalTypes.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(_animalTypeLabels[type] ?? type),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _animalType = value ?? '';
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Select an animal type';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _breedController,
                  decoration: const InputDecoration(
                    labelText: 'Breed (optional)',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Age (years) *'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter age';
                    }
                    if (int.tryParse(value.trim()) == null) {
                      return 'Enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _gender.isEmpty ? null : _gender,
                  decoration: const InputDecoration(labelText: 'Gender *'),
                  items: _genders.map((g) {
                    return DropdownMenuItem(
                      value: g,
                      child: Text(_genderLabels[g] ?? g),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _gender = value ?? '';
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Select a gender';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _rabiesStatus,
                  decoration: const InputDecoration(
                    labelText: 'Rabies Vaccination Status *',
                  ),
                  items: _rabiesStatuses.map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Text(_rabiesStatusLabels[status] ?? status),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _rabiesStatus = value ?? 'unknown';
                      if (_rabiesStatus != 'vaccinated') {
                        _lastVaccinationDate = null;
                        _vaccinationCardFile = null;
                        _vaccineNameController.clear();
                      }
                    });
                  },
                ),
                if (isVaccinated) ...[
                  const SizedBox(height: 16),
                  Card(
                    color: const Color(0xFFF8FAFC),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Vaccination Details (Required)',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: _selectVaccinationDate,
                            icon: const Icon(Icons.calendar_today),
                            label: Text(
                              _lastVaccinationDate == null
                                  ? 'Select Date'
                                  : 'Date: ${_lastVaccinationDate!.toLocal().toString().split(' ')[0]}',
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _vaccineNameController,
                            decoration: const InputDecoration(
                              labelText: 'Vaccine Name (optional)',
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (_vaccinationCardFile != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE6FFFB),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.image,
                                      color: Color(0xFF0F766E),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _vaccinationCardFile!.name,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          FilledButton.icon(
                            onPressed: _pickVaccinationCard,
                            icon: const Icon(Icons.upload_file),
                            label: const Text('Upload Card Image'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEDEB),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFB42318)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Color(0xFFB42318),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Color(0xFFB42318)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isSubmitting ? null : _submit,
                    child: Text(_isSubmitting ? 'Saving...' : 'Save Pet'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
