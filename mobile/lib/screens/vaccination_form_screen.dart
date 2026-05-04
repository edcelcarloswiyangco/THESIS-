import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/pet_model.dart';
import '../widgets/full_screen_image_viewer.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class VaccinationFormScreen extends StatefulWidget {
  const VaccinationFormScreen({
    super.key,
    required this.pet,
    required this.authService,
    required this.onUpdated,
  });

  final Pet pet;
  final AuthService authService;
  final Future<void> Function(Pet pet) onUpdated;

  @override
  State<VaccinationFormScreen> createState() => _VaccinationFormScreenState();
}

class _VaccinationFormScreenState extends State<VaccinationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _vaccineNameController;
  DateTime? _lastVaccinationDate;
  XFile? _vaccinationCardFile;
  Uint8List? _vaccinationCardPreviewBytes;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _vaccineNameController = TextEditingController();
    _lastVaccinationDate = widget.pet.lastVaccinationDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _vaccineNameController.dispose();
    super.dispose();
  }

  Future<void> _pickVaccinationCard() async {
    final picker = ImagePicker();
    try {
      final file = await picker.pickImage(source: ImageSource.gallery);
      if (file != null) {
        final bytes = await file.readAsBytes();
        setState(() {
          _vaccinationCardFile = file;
          _vaccinationCardPreviewBytes = bytes;
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

  void _openImageViewer({
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

    if (_lastVaccinationDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select last vaccination date')),
      );
      return;
    }

    if (_vaccinationCardFile == null || _vaccinationCardPreviewBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload vaccination card')),
      );
      return;
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

      final result = await widget.authService.apiService.addVaccinationRecord(
        token: token,
        petId: widget.pet.id,
        vaccinationDate: _lastVaccinationDate!,
        vaccinationCardBytes: _vaccinationCardPreviewBytes!,
        vaccinationCardName: _vaccinationCardFile!.name,
        vaccineName: _vaccineNameController.text.trim(),
      );

      final petData = result['data'] as Map<String, dynamic>?;
      if (petData != null) {
        final pet = Pet.fromJson(petData);
        await widget.onUpdated(pet);
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
    return Scaffold(
      appBar: AppBar(title: const Text('Vaccination')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Rabies Status: Vaccinated',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _lastVaccinationDate != null
                            ? _lastVaccinationDate!.toLocal().toString().split(
                                ' ',
                              )[0]
                            : 'Select last vaccination date',
                      ),
                    ),
                    TextButton(
                      onPressed: _selectVaccinationDate,
                      child: const Text('Select Date'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _vaccineNameController,
                  decoration: const InputDecoration(
                    labelText: 'Vaccine Name (optional)',
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () {
                    if (_vaccinationCardPreviewBytes != null) {
                      _openImageViewer(
                        title: 'Vaccination Card',
                        imageProvider: MemoryImage(
                          _vaccinationCardPreviewBytes!,
                        ),
                      );
                    }
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      color: const Color(0xFFE6FFFB),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AspectRatio(
                            aspectRatio: 16 / 9,
                            child: _vaccinationCardPreviewBytes != null
                                ? Image.memory(
                                    _vaccinationCardPreviewBytes!,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    color: const Color(0xFFF2F4F7),
                                    alignment: Alignment.center,
                                    child: const Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.receipt_long_outlined),
                                        SizedBox(height: 8),
                                        Text('No card selected yet'),
                                      ],
                                    ),
                                  ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.image,
                                  color: Color(0xFF0F766E),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _vaccinationCardFile?.name ??
                                        'No file selected',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                FilledButton.icon(
                                  onPressed: _pickVaccinationCard,
                                  icon: const Icon(Icons.upload_file),
                                  label: const Text('Upload Card Image'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Container(
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
                ],

                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isSubmitting ? null : _submit,
                    child: Text(
                      _isSubmitting ? 'Saving...' : 'Save Vaccination',
                    ),
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
