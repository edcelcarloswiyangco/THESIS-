import 'package:flutter/material.dart';

import '../models/pet_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'pet_details_screen.dart';

class MyPetsScreen extends StatefulWidget {
  const MyPetsScreen({
    super.key,
    required this.authService,
  });

  final AuthService authService;

  @override
  State<MyPetsScreen> createState() => _MyPetsScreenState();
}

class _MyPetsScreenState extends State<MyPetsScreen> {
  Future<List<Pet>>? _petsFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    final token = widget.authService.token;
    if (token == null || token.isEmpty) {
      setState(() {
        _petsFuture = Future.error(
          ApiException('Your session expired. Please login again.'),
        );
      });
      return;
    }

    setState(() {
      _petsFuture = widget.authService.apiService.fetchPets(token);
    });
  }


  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async => _reload(),
        child: FutureBuilder<List<Pet>>(
          future: _petsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const SizedBox(height: 60),
                  Icon(Icons.pets_outlined, size: 72, color: Colors.grey.shade400),
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

            final pets = snapshot.data ?? const <Pet>[];

            if (pets.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const SizedBox(height: 40),
                  const Text(
                    'My Pets',
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
                    child: Column(
                      children: [
                        const Text('No pets registered yet.'),
                      ],
                    ),
                  ),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: pets.length + 1,
              separatorBuilder: (_, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'My Pets',
                          style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  );
                }

                final pet = pets[index - 1];

                return InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () async {
                    await Navigator.of(context).push<void>(
                      MaterialPageRoute(
                        builder: (_) => PetDetailsScreen(
                          pet: pet,
                          authService: widget.authService,
                          onUpdated: () async => _reload(),
                        ),
                      ),
                    );
                    _reload();
                  },
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    pet.name,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${pet.animalType} • ${pet.age} years old',
                                    style: const TextStyle(
                                      color: Color(0xFF627D98),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _rabiesStatusColor(pet.rabiesStatus)
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                pet.rabiesStatus == 'vaccinated'
                                    ? 'Vaccinated'
                                    : pet.rabiesStatus == 'not_vaccinated'
                                        ? 'Not Vaccinated'
                                        : 'Unknown',
                                style: TextStyle(
                                  color: _rabiesStatusColor(pet.rabiesStatus),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (pet.breed != null && pet.breed!.isNotEmpty) ...[
                          Text('Breed: ${pet.breed}'),
                          const SizedBox(height: 4),
                        ],
                        Text('Gender: ${pet.gender[0].toUpperCase()}${pet.gender.substring(1)}'),
                        const SizedBox(height: 4),
                        if (pet.rabiesStatus == 'vaccinated' &&
                            pet.lastVaccinationDate != null) ...[
                          Text(
                            'Vaccinated: ${pet.lastVaccinationDate!.toLocal().toString().split(' ')[0]}',
                          ),
                          const SizedBox(height: 4),
                        ],
                        const SizedBox(height: 12),
                        const SizedBox(height: 2),
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

  Color _rabiesStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'vaccinated':
        return const Color(0xFF027A48);
      case 'not_vaccinated':
        return const Color(0xFFB42318);
      default:
        return const Color(0xFFB54708);
    }
  }
}
