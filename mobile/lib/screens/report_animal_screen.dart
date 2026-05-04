import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:video_player/video_player.dart';

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

class _PickedPhoto {
  const _PickedPhoto({required this.bytes, required this.fileName});

  final Uint8List bytes;
  final String fileName;
}

class _PickedVideo {
  const _PickedVideo({required this.bytes, required this.fileName});

  final Uint8List bytes;
  final String fileName;
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

  static const LatLng _defaultMapCenter = LatLng(15.1337, 120.5924);

  final _formKey = GlobalKey<FormState>();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _mapController = MapController();
  final ImagePicker _imagePicker = ImagePicker();

  TextEditingController? _animalController;
  String _reportType = _reportTypes.first;
  bool _isSubmitting = false;
  bool _isGettingLocation = false;
  bool _isResolvingAddress = false;
  String? _errorMessage;
  double? _latitude;
  double? _longitude;
  LatLng _pinPoint = _defaultMapCenter;
  final List<_PickedPhoto> _photos = [];
  _PickedVideo? _video;
  String? _videoErrorMessage;

  late final TextEditingController _expandedMapSearchController;
  late final MapController _expandedMapController;

  @override
  void initState() {
    super.initState();
    _expandedMapSearchController = TextEditingController();
    _expandedMapController = MapController();
    _setPinLocation(_defaultMapCenter, resolveAddress: false);
  }

  @override
  void dispose() {
    _locationController.dispose();
    _descriptionController.dispose();
    _expandedMapSearchController.dispose();
    super.dispose();
  }

  Future<void> _pickFromGallery() async {
    if (_photos.length >= 5) {
      setState(() {
        _errorMessage = 'Maximum of 5 photos only.';
      });
      return;
    }

    final remaining = 5 - _photos.length;
    final picked = await _imagePicker.pickMultiImage(imageQuality: 90);

    if (!mounted || picked.isEmpty) {
      return;
    }

    final toAdd = picked.take(remaining).toList();
    final newPhotos = <_PickedPhoto>[];

    for (final image in toAdd) {
      final bytes = await image.readAsBytes();
      newPhotos.add(
        _PickedPhoto(
          bytes: bytes,
          fileName: image.name.isNotEmpty
              ? image.name
              : 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      );
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _photos.addAll(newPhotos);
      _errorMessage = null;
      if (picked.length > remaining) {
        _errorMessage = 'Only 5 photos are allowed. Extra photos were skipped.';
      }
    });
  }

  Future<void> _capturePhoto() async {
    if (_photos.length >= 5) {
      setState(() {
        _errorMessage = 'Maximum of 5 photos only.';
      });
      return;
    }

    final captured = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
    );

    if (!mounted || captured == null) {
      return;
    }

    final bytes = await captured.readAsBytes();

    setState(() {
      _photos.add(
        _PickedPhoto(
          bytes: bytes,
          fileName: captured.name.isNotEmpty
              ? captured.name
              : 'capture_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      );
      _errorMessage = null;
    });
  }

  Future<void> _pickVideo(ImageSource source) async {
    if (_video != null) {
      setState(() {
        _errorMessage = 'Only one optional video is allowed.';
      });
      return;
    }

    final pickedVideo = await _imagePicker.pickVideo(source: source);

    if (!mounted || pickedVideo == null) {
      return;
    }

    final bytes = await pickedVideo.readAsBytes();

    if (!mounted) {
      return;
    }

    // Validate file size: max 100MB
    const maxSize = 100 * 1024 * 1024; // 100MB
    if (bytes.length > maxSize) {
      setState(() {
        _videoErrorMessage = 'Video must be under 100MB and 100 seconds long.';
      });
      return;
    }

    // Validate video duration: max 100 seconds
    final controller = VideoPlayerController.file(File(pickedVideo.path));
    await controller.initialize();
    final duration = controller.value.duration;
    await controller.dispose();

    if (duration.inSeconds > 100) {
      setState(() {
        _videoErrorMessage = 'Video must be under 100MB and 100 seconds long.';
      });
      return;
    }

    setState(() {
      _video = _PickedVideo(
        bytes: bytes,
        fileName: pickedVideo.name.isNotEmpty
            ? pickedVideo.name
            : 'video_${DateTime.now().millisecondsSinceEpoch}.mp4',
      );
      _errorMessage = null;
      _videoErrorMessage = null;
    });
  }

  void _removeVideo() {
    setState(() {
      _video = null;
      _videoErrorMessage = null;
    });
  }

  void _removePhoto(int index) {
    setState(() {
      _photos.removeAt(index);
    });
  }

  String _buildSearchQuery(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return trimmed;
    }

    return trimmed;
  }

  Future<void> _findTypedLocationOnMap() async {
    final query = _locationController.text.trim();

    if (query.isEmpty) {
      setState(() {
        _errorMessage = 'Type a street or address first.';
      });
      return;
    }

    setState(() {
      _isResolvingAddress = true;
      _errorMessage = null;
    });

    try {
      final results = await locationFromAddress(_buildSearchQuery(query));
      if (results.isEmpty) {
        throw ApiException('No matching street or address was found.');
      }

      final point = LatLng(results.first.latitude, results.first.longitude);
      await _setPinLocation(point);
      _mapController.move(point, 17);
    } on ApiException catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = error.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Unable to find that street on the map.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResolvingAddress = false;
        });
      }
    }
  }

  Future<void> _openExpandedMapPicker() async {
    _expandedMapSearchController.text = _locationController.text;
    LatLng draftPoint = _pinPoint;
    final result = await showDialog<Map<String, dynamic>>(

        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          bool isSearching = false;
          String? dialogError;

          Future<void> searchLocation(
            void Function(void Function()) setModalState,
          ) async {
            final query = _expandedMapSearchController.text.trim();
            if (query.isEmpty) {
              setModalState(() {
                dialogError = 'Type a location first.';
              });
              return;
            }

            setModalState(() {
              isSearching = true;
              dialogError = null;
            });

            try {
              final results = await locationFromAddress(
                _buildSearchQuery(query),
              );
              if (results.isEmpty) {
                throw ApiException('No matching street or address was found.');
              }

              final point = LatLng(
                results.first.latitude,
                results.first.longitude,
              );
              draftPoint = point;
              _expandedMapController.move(point, 18);
            } on ApiException catch (error) {
              setModalState(() {
                dialogError = error.message;
              });
            } catch (_) {
              setModalState(() {
                dialogError = 'Unable to find that location.';
              });
            } finally {
              setModalState(() {
                isSearching = false;
              });
            }
          }

          return StatefulBuilder(
            builder: (context, setModalState) {
              return Dialog.fullscreen(
                child: Scaffold(
                  appBar: AppBar(
                    title: const Text('Pick exact location'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
                  body: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _expandedMapSearchController,
                                decoration: const InputDecoration(
                                  labelText: 'Search street or address',
                                  prefixIcon: Icon(Icons.search),
                                ),
                                onSubmitted: (_) =>
                                    searchLocation(setModalState),
                              ),
                            ),
                            const SizedBox(width: 12),
                            FilledButton(
                              onPressed: isSearching
                                  ? null
                                  : () => searchLocation(setModalState),
                              child: isSearching
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Find'),
                            ),
                          ],
                        ),
                      ),
                      if (dialogError != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF1F0),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              dialogError!,
                              style: const TextStyle(color: Color(0xFFB42318)),
                            ),
                          ),
                        ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: FlutterMap(
                              mapController: _expandedMapController,
                              options: MapOptions(
                                initialCenter: draftPoint,
                                initialZoom: 17,
                                minZoom: 14,
                                maxZoom: 19,
                                onTap: (_, point) {
                                  setModalState(() {
                                    draftPoint = point;
                                    dialogError = null;
                                  });
                                },
                                onPositionChanged: (camera, hasGesture) {
                                  if (!hasGesture) {
                                    return;
                                  }

                                  final point = camera.center;
                                  setModalState(() {
                                    draftPoint = point;
                                    dialogError = null;
                                  });
                                },
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate:
                                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName: 'com.thesis.mobile',
                                ),
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      point: draftPoint,
                                      width: 56,
                                      height: 56,
                                      child: const Icon(
                                        Icons.location_pin,
                                        color: Colors.red,
                                        size: 48,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Latitude: ${draftPoint.latitude.toStringAsFixed(6)}',
                            ),
                            Text(
                              'Longitude: ${draftPoint.longitude.toStringAsFixed(6)}',
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: () async {
                                  final navigator = Navigator.of(context);
                                  FocusManager.instance.primaryFocus?.unfocus();
                                  await Future<void>.delayed(const Duration(milliseconds: 100));

                                  if (!mounted) {
                                    return;
                                  }

                                  navigator.pop({
                                    'point': draftPoint,
                                    'searchQuery': _expandedMapSearchController.text.trim(),
                                  });
                                },
                                child: const Text('Use This Location'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );

      if (result != null && mounted) {
        final point = result['point'] as LatLng;
        final searchQuery = result['searchQuery'] as String?;
        await _setPinLocation(point, customAddress: searchQuery);
        _mapController.move(point, 17);
      }
  }

  Future<void> _openPhotoPreview(_PickedPhoto photo) async {
    await showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 4,
                child: Image.memory(photo.bytes, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
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

      final point = LatLng(position.latitude, position.longitude);
      await _setPinLocation(point);
      _mapController.move(point, 17);
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

  Future<void> _setPinLocation(
    LatLng point, {
    bool resolveAddress = true,
    String? customAddress,
  }) async {
    setState(() {
      _pinPoint = point;
      _latitude = point.latitude;
      _longitude = point.longitude;
      _errorMessage = null;
      if (resolveAddress) {
        _isResolvingAddress = true;
      }
    });

    if (!resolveAddress) {
      return;
    }

    try {
      final placemarks = await placemarkFromCoordinates(
        point.latitude,
        point.longitude,
      );
      final place = placemarks.isNotEmpty ? placemarks.first : null;
      final name = _firstNonEmpty([place?.name]);
      final street = _firstNonEmpty([
        [place?.subThoroughfare, place?.thoroughfare]
            .where((value) => value != null && value.trim().isNotEmpty)
            .map((value) => value!.trim())
            .join(' '),
      ]);
      final barangay = _firstNonEmpty([place?.subLocality]);
      final city = _firstNonEmpty([place?.locality, place?.administrativeArea]);

      final parts = <String>[];
      if (name != null) {
        parts.add(name);
      }
      if (street != null) {
        parts.add(street);
      }
      if (barangay != null) {
        parts.add('Brgy. $barangay');
      }
      if (city != null && city != barangay) {
        parts.add(city);
      }

      parts.add(
        '(${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)})',
      );

      _locationController.text = parts.join(', ');
    } catch (_) {
      _locationController.text =
          'Location (${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)})';
    } finally {
      if (mounted) {
        setState(() {
          _isResolvingAddress = false;
        });
      }
    }
  }

  String? _firstNonEmpty(Iterable<String?> values) {
    for (final value in values) {
      final trimmed = value?.trim();
      if (trimmed != null && trimmed.isNotEmpty) {
        return trimmed;
      }
    }

    return null;
  }

  Future<void> _submit() async {
    final animalType = _animalController?.text.trim() ?? '';

    if (!_formKey.currentState!.validate() || _isSubmitting) {
      return;
    }

    if (_photos.isEmpty) {
      setState(() {
        _errorMessage = 'Please add at least 1 photo.';
      });
      return;
    }

    if (_photos.length > 5) {
      setState(() {
        _errorMessage = 'Only up to 5 photos are allowed.';
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
      await widget.authService.apiService.submitAnimalReport(
        token: authToken,
        reportType: _reportType,
        animalType: animalType,
        locationText: _locationController.text.trim(),
        description: _descriptionController.text.trim(),
        images: _photos
            .map(
              (photo) =>
                  ReportUploadImage(bytes: photo.bytes, name: photo.fileName),
            )
            .toList(),
        video: _video == null
            ? null
            : ReportUploadVideo(bytes: _video!.bytes, name: _video!.fileName),
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
      if (!mounted) {
        return;
      }

      _formKey.currentState?.reset();
      setState(() {
        _photos.clear();
        _video = null;
        _latitude = null;
        _longitude = null;
        _locationController.clear();
        _descriptionController.clear();
        _reportType = _reportTypes.first;
        _errorMessage = null;
        _pinPoint = _defaultMapCenter;
      });
      _mapController.move(_defaultMapCenter, 16);
    } on ApiException catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = error.message;
        });
      }
    } catch (error, stackTrace) {
      if (mounted) {
        setState(() {
          _errorMessage = error.toString();
        });
      }
      // ignore: avoid_print
      print('Report submit failed: $error');
      // ignore: avoid_print
      print(stackTrace);
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
              Align(
                alignment: Alignment.topLeft,
                child: FilledButton.icon(
                  onPressed: () {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    }
                  },
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Report stray animal',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'Upload 1 to 5 photos, then set the exact pin on the map.',
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 20),
              _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Photos (${_photos.length}/5)',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _isSubmitting ? null : _pickFromGallery,
                            icon: const Icon(Icons.upload_file),
                            label: const Text('Upload'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _isSubmitting ? null : _capturePhoto,
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Capture'),
                          ),
                        ),
                      ],
                    ),
                    if (_photos.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 120,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _photos.length,
                          separatorBuilder: (_, index) =>
                              const SizedBox(width: 10),
                          itemBuilder: (context, index) {
                            final photo = _photos[index];
                            return SizedBox(
                              width: 120,
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: Material(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(14),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(14),
                                        onTap: () => _openPhotoPreview(photo),
                                        child: Padding(
                                          padding: const EdgeInsets.all(6),
                                          child: Image.memory(
                                            photo.bytes,
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: InkWell(
                                      onTap: _isSubmitting
                                          ? null
                                          : () => _removePhoto(index),
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        padding: const EdgeInsets.all(4),
                                        child: const Icon(
                                          Icons.close,
                                          size: 14,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Video (optional)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'You can upload or capture one video to add more proof.',
                      style: TextStyle(color: Color(0xFF486581)),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _isSubmitting
                                ? null
                                : () => _pickVideo(ImageSource.gallery),
                            icon: const Icon(Icons.video_library),
                            label: const Text('Upload'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _isSubmitting
                                ? null
                                : () => _pickVideo(ImageSource.camera),
                            icon: const Icon(Icons.videocam),
                            label: const Text('Capture'),
                          ),
                        ),
                      ],
                    ),
                    if (_video != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFD9E2EC)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: const Color(0xFF102A43),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.play_circle_fill,
                                color: Colors.white,
                                size: 34,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Video selected',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    _video!.fileName,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: _isSubmitting ? null : _removeVideo,
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (_videoErrorMessage != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.red.shade700,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _videoErrorMessage!,
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
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
                  onSelected: (value) => _animalController?.text = value,
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
                      textInputAction: TextInputAction.search,
                      onFieldSubmitted: _isSubmitting
                          ? null
                          : (_) => _findTypedLocationOnMap(),
                      decoration: InputDecoration(
                        labelText: 'Location',
                        hintText: 'Type street or address',
                        suffixIcon: _isResolvingAddress
                            ? const Padding(
                                padding: EdgeInsets.all(10),
                                child: SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : null,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Enter the location';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isSubmitting
                                ? null
                                : _findTypedLocationOnMap,
                            icon: const Icon(Icons.search),
                            label: const Text('Find on map'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
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
                            label: const Text('Use GPS'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SizedBox(
                        height: 180,
                        child: Stack(
                          children: [
                            FlutterMap(
                              mapController: _mapController,
                              options: MapOptions(
                                initialCenter: _pinPoint,
                                initialZoom: 16,
                                minZoom: 14,
                                maxZoom: 19,
                                interactionOptions: const InteractionOptions(
                                  flags: InteractiveFlag.none,
                                ),
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate:
                                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName: 'com.thesis.mobile',
                                ),
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      point: _pinPoint,
                                      width: 44,
                                      height: 44,
                                      child: const Icon(
                                        Icons.location_pin,
                                        color: Colors.red,
                                        size: 42,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Container(
                              color: const Color.fromRGBO(0, 0, 0, 0.12),
                            ),
                            const Positioned(
                              left: 12,
                              bottom: 12,
                              child: Chip(label: Text('Tap to enlarge map')),
                            ),
                            Positioned.fill(
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _isSubmitting ? null : _openExpandedMapPicker,
                                  splashColor: Colors.white24,
                                  highlightColor: Colors.transparent,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tap the map to enlarge it, then search or drag the pin.',
                      style: TextStyle(color: Color(0xFF486581)),
                    ),
                    if (_latitude != null && _longitude != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Pin: ${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}',
                        style: const TextStyle(
                          color: Color(0xFF0F766E),
                          fontWeight: FontWeight.w600,
                        ),
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
