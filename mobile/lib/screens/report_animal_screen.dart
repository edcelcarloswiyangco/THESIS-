import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../models/app_user.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class ReportAnimalScreen extends StatefulWidget {
  const ReportAnimalScreen({
    super.key,
    required this.user,
    required this.authService,
    required this.onSubmittedSuccessfully,
  });

  final AppUser user;
  final AuthService authService;
  final Future<void> Function() onSubmittedSuccessfully;

  @override
  State<ReportAnimalScreen> createState() => _ReportAnimalScreenState();
}

class _ReportAnimalScreenState extends State<ReportAnimalScreen> {
  static const List<String> _reportTypes = [
    'stray animal',
    'injured animal',
    'dead animal',
    'aggressive animal',
  ];

  static const List<String> _animalSuggestions = [
    'dog',
    'cat',
    'cow',
    'goat',
    'bird',
    'deer',
    'donkey',
    'duck',
    'chicken',
    'horse',
    'pig',
    'rabbit',
    'snake',
    'monkey',
    'carabao',
    'sheep',
    'turkey',
    'goose',
    'fish',
    'frog',
    'other animal',
  ];

  final _formKey = GlobalKey<FormState>();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  TextEditingController? _animalController;
  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;
  String _reportType = _reportTypes.first;
  bool _isSubmitting = false;
  bool _isGettingLocation = false;
  String? _errorMessage;
  double? _latitude;
  double? _longitude;

  @override
  void dispose() {
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedImage = await _imagePicker.pickImage(
      source: source,
      imageQuality: 85,
    );
    if (!mounted || pickedImage == null) {
      return;
    }

    final bytes = await pickedImage.readAsBytes();

    setState(() {
      _selectedImage = pickedImage;
      _selectedImageBytes = bytes;
      _errorMessage = null;
    });
  }

  Future<void> _useCurrentLocation() async {
    setState(() {
      _isGettingLocation = true;
      _errorMessage = null;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw ApiException(
          'Location services are disabled. Please turn on GPS.',
        );
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        throw ApiException('Location permission was denied.');
      }

      if (permission == LocationPermission.deniedForever) {
        throw ApiException('Location permission is permanently denied.');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _locationController.text =
            'Latitude: ${position.latitude.toStringAsFixed(6)}, Longitude: ${position.longitude.toStringAsFixed(6)}';
      });
    } on ApiException catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = error.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Unable to get the current location.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGettingLocation = false;
        });
      }
    }
  }

  Future<void> _submit() async {
    final animalType = _animalController?.text.trim() ?? '';

    if (!_formKey.currentState!.validate() || _isSubmitting) {
      return;
    }

    if (_selectedImage == null) {
      setState(() {
        _errorMessage = 'Please upload or capture an animal photo.';
      });
      return;
    }

    final authToken = widget.authService.token;

    if (authToken == null || authToken.isEmpty) {
      setState(() {
        _errorMessage = 'Your session expired. Please login again.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final imageBytes =
          _selectedImageBytes ?? await _selectedImage!.readAsBytes();
      final imageName = _selectedImage!.name.isNotEmpty
          ? _selectedImage!.name
          : 'animal.jpg';

      await widget.authService.apiService.submitAnimalReport(
        token: authToken,
        reportType: _reportType,
        animalType: animalType.isEmpty ? 'unknown' : animalType,
        locationText: _locationController.text.trim(),
        description: _descriptionController.text.trim(),
        imageBytes: imageBytes,
        imageName: imageName,
        latitude: _latitude,
        longitude: _longitude,
      );

      if (!mounted) {
        return;
      }

      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Success'),
          content: const Text('Report submitted successfully.'),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );

      if (!mounted) {
        return;
      }

      await widget.onSubmittedSuccessfully();
      _formKey.currentState?.reset();
      setState(() {
        _selectedImage = null;
        _latitude = null;
        _longitude = null;
        _locationController.clear();
        _descriptionController.clear();
        _reportType = _reportTypes.first;
        _errorMessage = null;
      });
    } on ApiException catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = error.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Unable to submit the report right now.';
        });
      }
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
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Report stray animal',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'Fill out the report and attach a photo or capture one with the camera.',
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFD9E2EC)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Upload or Capture',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _isSubmitting
                                ? null
                                : () => _pickImage(ImageSource.gallery),
                            icon: const Icon(Icons.upload_file),
                            label: const Text('Upload'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _isSubmitting
                                ? null
                                : () => _pickImage(ImageSource.camera),
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Capture'),
                          ),
                        ),
                      ],
                    ),
                    if (_selectedImage != null) ...[
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: _selectedImageBytes != null
                            ? Image.memory(
                                _selectedImageBytes!,
                                height: 180,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                height: 180,
                                width: double.infinity,
                                color: const Color(0xFFF8FAFC),
                                alignment: Alignment.center,
                                child: Text(_selectedImage!.name),
                              ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                child: DropdownButtonFormField<String>(
                  initialValue: _reportType,
                  decoration: const InputDecoration(labelText: 'Report Type'),
                  items: _reportTypes
                      .map(
                        (type) => DropdownMenuItem<String>(
                          value: type,
                          child: Text(type),
                        ),
                      )
                      .toList(),
                  onChanged: _isSubmitting
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() {
                              _reportType = value;
                            });
                          }
                        },
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                child: Autocomplete<String>(
                  optionsBuilder: (textEditingValue) {
                    if (textEditingValue.text.trim().isEmpty) {
                      return const Iterable<String>.empty();
                    }

                    final query = textEditingValue.text.trim().toLowerCase();
                    return _animalSuggestions.where(
                      (animal) => animal.toLowerCase().startsWith(query),
                    );
                  },
                  onSelected: (value) {
                    _animalController?.text = value;
                  },
                  fieldViewBuilder:
                      (context, controller, focusNode, onFieldSubmitted) {
                        _animalController = controller;
                        return TextFormField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: const InputDecoration(
                            labelText: 'Animal Type',
                            hintText: 'dog, cat, goat, cow, bird, or other',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Enter the animal type';
                            }
                            return null;
                          },
                        );
                      },
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        labelText: 'Location',
                        hintText: 'Type the address or use GPS',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Enter the location';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isGettingLocation || _isSubmitting
                            ? null
                            : _useCurrentLocation,
                        icon: _isGettingLocation
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.gps_fixed),
                        label: const Text('Use Current Location'),
                      ),
                    ),
                    if (_latitude != null && _longitude != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        'GPS: ${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}',
                        style: const TextStyle(color: Color(0xFF0F766E)),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                child: TextFormField(
                  controller: _descriptionController,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Tell what happened to the animal.',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter the description';
                    }
                    return null;
                  },
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F0),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Color(0xFFB42318)),
                  ),
                ),
              ],
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: Text(_isSubmitting ? 'Submitting...' : 'Submit'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD9E2EC)),
      ),
      child: child,
    );
  }
}
