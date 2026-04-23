import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:math';

import '../../../core/providers/auth_provider.dart';
import '../../../core/constants/colors.dart';
import '../../../shared/widgets/practitioner_card.dart';
import '../appointments/patient_appointments_screen.dart';
import '../profile/patient_profile_screen.dart';

class PatientHomeScreen extends StatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _specialties = ['Tous', 'Généraliste', 'Dentiste', 'Cardiologue', 'Ophtalmo', 'Pédiatre'];
  int _selectedSpecialtyIndex = 0;
  int _currentBottomNavIndex = 0;
  
  bool _isMapView = false; // Bascule Liste / Carte
  final MapController _mapController = MapController();
  
  // Pour la simulation de coordonnées (Paris)
  final double _baseLat = 48.8566;
  final double _baseLng = 2.3522;
  final Random _random = Random();
  final Map<String, LatLng> _mockGeolocations = {};
  
  Position? _userPosition;
  double _maxDistance = 50.0; // Distance max en km

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
        Position position = await Geolocator.getCurrentPosition();
        if (mounted) {
          setState(() {
            _userPosition = position;
          });
        }
      }
    } catch (e) {}
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Header personnalisé
  Widget _buildHeader(String name) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bonjour,',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white),
                    onPressed: () => context.read<AuthProvider>().signOut(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Barre de recherche
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withAlpha(25), blurRadius: 10, offset: const Offset(0, 5)),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Rechercher un médecin, une spécialité...',
                  hintStyle: TextStyle(color: Colors.grey),
                  prefixIcon: Icon(Icons.search, color: AppColors.primary),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 16),
                ),
                onChanged: (value) => setState(() {}),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Liste des filtres
  Widget _buildCategories() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        scrollDirection: Axis.horizontal,
        itemCount: _specialties.length,
        itemBuilder: (context, index) {
          bool isSelected = _selectedSpecialtyIndex == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedSpecialtyIndex = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isSelected ? AppColors.primary : Colors.grey.shade300),
                boxShadow: isSelected
                    ? [BoxShadow(color: AppColors.primary.withAlpha(50), blurRadius: 8, offset: const Offset(0, 4))]
                    : [],
              ),
              child: Center(
                child: Text(
                  _specialties[index],
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  LatLng _getDoctorLatLng(String doctorId, Map<String, dynamic> data) {
    if (data.containsKey('latitude') && data.containsKey('longitude')) {
       return LatLng(data['latitude'] as double, data['longitude'] as double);
    }
    
    if (!_mockGeolocations.containsKey(doctorId)) {
      // Générer une position aléatoire autour de Paris (rayon de quelques km)
      double latOff = (_random.nextDouble() - 0.5) * 0.05; // Environ +- 3km
      double lngOff = (_random.nextDouble() - 0.5) * 0.05;
      _mockGeolocations[doctorId] = LatLng(_baseLat + latOff, _baseLng + lngOff);
    }
    return _mockGeolocations[doctorId]!;
  }

  Widget _buildMap(List<QueryDocumentSnapshot> docs) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _userPosition != null 
            ? LatLng(_userPosition!.latitude, _userPosition!.longitude)
            : LatLng(_baseLat, _baseLng),
        initialZoom: 13.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.allodoct.app',
        ),
        MarkerLayer(
          markers: [
            if (_userPosition != null)
              Marker(
                point: LatLng(_userPosition!.latitude, _userPosition!.longitude),
                width: 20,
                height: 20,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ...docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final coord = _getDoctorLatLng(doc.id, data);
              return Marker(
                point: coord,
                width: 50,
                height: 50,
                child: GestureDetector(
                  onTap: () => _showDoctorBottomSheet(context, doc.id, data),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                        ),
                        child: const Icon(Icons.medical_services, color: Colors.white, size: 20),
                      ),
                      const Icon(Icons.arrow_drop_down, color: AppColors.primary, size: 20),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ],
    );
  }

  Future<void> _centerOnUser() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition();
        _mapController.move(LatLng(position.latitude, position.longitude), 14.0);
      }
    } catch (e) {
      // Ignorer l'erreur ou afficher toast
    }
  }

  void _showDoctorBottomSheet(BuildContext context, String id, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (data['clinicPhotoUrl'] != null && data['clinicPhotoUrl'].toString().isNotEmpty)
                Container(
                  height: 120,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    image: DecorationImage(
                      image: NetworkImage(data['clinicPhotoUrl']),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              Row(
                children: [
                  ClipOval(
                    child: Container(
                      width: 60, height: 60,
                      color: AppColors.primaryLight,
                      child: data['photoUrl'] != null && data['photoUrl'].toString().isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: data['photoUrl'],
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const CircularProgressIndicator(),
                            errorWidget: (context, url, error) => const Icon(Icons.person, color: AppColors.primary),
                          )
                        : Center(
                            child: Text(
                              (data['name'] ?? 'P')[0].toUpperCase(),
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                          ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                         Text(
                          'Dr. ${data['name'] ?? 'Inconnu'}',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          data['specialty'] ?? 'Médecine Générale',
                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  context.pop();
                  context.push('/practitioner_details/$id', extra: data);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Voir le profil et réserver', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ],
          ),
        );
      },
    );
  }

  // Helper pour vérifier si un docteur appartient à une catégorie
  bool _doctorMatchesSpecialty(String doctorSpec, String category) {
    if (category == 'Tous') return true;
    if (category == 'Ophtalmo' && (doctorSpec == 'Ophtalmologue' || doctorSpec == 'Ophtalmo')) return true;
    return doctorSpec.toLowerCase() == category.toLowerCase();
  }

  Widget _buildHomeContent(BuildContext context, String userName) {
    return Column(
      children: [
        _buildHeader(userName),
        const SizedBox(height: 16),
        _buildCategories(),
        const SizedBox(height: 16),
        
        // Titre + Toggle Carte
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Praticiens recommandés',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMain,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _isMapView = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: !_isMapView ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: !_isMapView ? [const BoxShadow(color: Colors.black12, blurRadius: 4)] : null,
                        ),
                        child: const Icon(Icons.list, size: 20, color: AppColors.textMain),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _isMapView = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: _isMapView ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: _isMapView ? [const BoxShadow(color: Colors.black12, blurRadius: 4)] : null,
                        ),
                        child: const Icon(Icons.map_outlined, size: 20, color: AppColors.textMain),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Zone de recherche', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textMain)),
                  Text('${_maxDistance.toInt()} km', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                ],
              ),
              Slider(
                value: _maxDistance,
                min: 1.0,
                max: 100.0,
                divisions: 10,
                activeColor: AppColors.primary,
                label: '${_maxDistance.toInt()} km',
                onChanged: (val) => setState(() => _maxDistance = val),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),

        // Liste / Carte depuis Firestore
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('practitioners').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const Center(child: Text('Erreur de chargement des données.'));
              }

              final docs = snapshot.data?.docs ?? [];
              
              // Filtrer
              final searchQuery = _searchController.text.toLowerCase();
              final categoryFilter = _selectedSpecialtyIndex == 0 ? '' : _specialties[_selectedSpecialtyIndex];

              final filteredDocs = docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final name = (data['name'] ?? '').toString().toLowerCase();
                final spec = (data['specialty'] ?? '').toString();
                
                // Calcul distance
                double distance = 0;
                if (_userPosition != null) {
                  final docLatLng = _getDoctorLatLng(doc.id, data);
                  distance = Geolocator.distanceBetween(
                    _userPosition!.latitude, 
                    _userPosition!.longitude, 
                    docLatLng.latitude, 
                    docLatLng.longitude
                  ) / 1000; // En km
                }

                bool matchesSearch = name.contains(searchQuery) || spec.toLowerCase().contains(searchQuery);
                bool matchesCategory = _doctorMatchesSpecialty(spec, categoryFilter.isEmpty ? 'Tous' : categoryFilter);
                bool matchesDistance = _userPosition == null || distance <= _maxDistance;

                return matchesSearch && matchesCategory && matchesDistance;
              }).toList();

              if (filteredDocs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text('Aucun praticien trouvé.', style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                );
              }

              if (_isMapView) {
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                      child: _buildMap(filteredDocs),
                    ),
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: FloatingActionButton(
                        onPressed: _centerOnUser,
                        backgroundColor: Colors.white,
                        mini: true,
                        child: const Icon(Icons.my_location, color: AppColors.primary),
                      ),
                    ),
                  ],
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                itemCount: filteredDocs.length,
                itemBuilder: (context, index) {
                  final data = filteredDocs[index].data() as Map<String, dynamic>;
                  
                  // Distance string
                  String distanceStr = '';
                  if (_userPosition != null) {
                    final docLatLng = _getDoctorLatLng(filteredDocs[index].id, data);
                    final dist = Geolocator.distanceBetween(
                      _userPosition!.latitude, 
                      _userPosition!.longitude, 
                      docLatLng.latitude, 
                      docLatLng.longitude
                    ) / 1000;
                    distanceStr = '${dist.toStringAsFixed(1)} km';
                  }

                  return PractitionerCard(
                    id: filteredDocs[index].id,
                    name: data['name'] ?? 'Inconnu',
                    specialty: data['specialty'] ?? '',
                    photoUrl: data['photoUrl'],
                    distance: distanceStr,
                    rating: (data['rating'] ?? 4.5).toDouble(),
                    onTap: () {
                      context.push('/practitioner_details/${filteredDocs[index].id}', extra: data);
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentBottomNavIndex,
        children: [
          _buildHomeContent(context, user?.name ?? 'Patient'),
          const PatientAppointmentsScreen(),
          const PatientProfileScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 20, offset: const Offset(0, -5))],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
          child: BottomNavigationBar(
            currentIndex: _currentBottomNavIndex,
            onTap: (index) => setState(() => _currentBottomNavIndex = index),
            backgroundColor: Colors.white,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: Colors.grey.shade400,
            showSelectedLabels: true,
            showUnselectedLabels: true,
            elevation: 0,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Accueil'),
              BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Rendez-vous'),
              BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profil'),
            ],
          ),
        ),
      ),
    );
  }
}
