import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/providers/auth_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

class PractitionerClinicInfoScreen extends StatefulWidget {
  const PractitionerClinicInfoScreen({super.key});

  @override
  State<PractitionerClinicInfoScreen> createState() => _PractitionerClinicInfoScreenState();
}

class _PractitionerClinicInfoScreenState extends State<PractitionerClinicInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _clinicNameController = TextEditingController();
  final _clinicAddressController = TextEditingController();
  final _clinicBioController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  final _clinicPhotoUrlController = TextEditingController();
  
  bool _isLoading = false;
  bool _isGettingLocation = false;

  @override
  void initState() {
    super.initState();
    _loadClinicInfo();
  }

  Future<void> _loadClinicInfo() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data()!.containsKey('clinic')) {
        final clinic = doc.data()!['clinic'] as Map<String, dynamic>;
         setState(() {
          _clinicNameController.text = clinic['name'] ?? '';
          _clinicAddressController.text = clinic['address'] ?? '';
          _clinicBioController.text = clinic['bio'] ?? '';
          _latController.text = clinic['latitude']?.toString() ?? '';
          _lngController.text = clinic['longitude']?.toString() ?? '';
          _clinicPhotoUrlController.text = clinic['clinicPhotoUrl'] ?? '';
        });
      }
    }
  }

  Future<void> _pickAndUploadClinicImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    
    if (image == null) return;
    
    setState(() => _isLoading = true);
    try {
      final user = context.read<AuthProvider>().currentUser;
      if (user == null) return;

      final storageRef = FirebaseStorage.instance.ref();
      final clinicPicRef = storageRef.child("clinics/${user.uid}.jpg");

      final bytes = await image.readAsBytes();
      await clinicPicRef.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      
      final String downloadUrl = await clinicPicRef.getDownloadURL();
      
      setState(() {
        _clinicPhotoUrlController.text = downloadUrl;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo du bâtiment téléchargée !'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur upload: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isGettingLocation = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition();
        setState(() {
          _latController.text = position.latitude.toString();
          _lngController.text = position.longitude.toString();
        });

        // Inverse Geocoding with Nominatim (OSM)
        final response = await http.get(Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}'
        ));
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body) as Map<String, dynamic>;
          final addr = data['address'] as Map<String, dynamic>?;
          
          if (addr != null) {
            final houseNumber = addr['house_number']?.toString() ?? '';
            final road = addr['road']?.toString() ?? '';
            // On prend la ville la plus précise possible
            final city = (addr['city'] ?? addr['town'] ?? addr['village'] ?? addr['municipality'] ?? '').toString();
            final postcode = addr['postcode']?.toString() ?? '';
            final country = addr['country']?.toString() ?? '';
            
            // On s'assure que road ne contient pas de virgules (parfois Nominatim en met)
            final cleanRoad = road.split(',')[0].trim();
            final cleanCity = city.split(',')[0].trim();

            // Format final : "9 Rue Gustave Caillebotte Asnières-sur-Seine 92600 France"
            String formatted = "";
            if (houseNumber.isNotEmpty) formatted += "$houseNumber ";
            if (cleanRoad.isNotEmpty) formatted += "$cleanRoad ";
            if (cleanCity.isNotEmpty) formatted += "$cleanCity ";
            if (postcode.isNotEmpty) formatted += "$postcode ";
            if (country.isNotEmpty) formatted += "$country";
            
            final finalAddress = formatted.trim().replaceAll(RegExp(r'\s+'), ' ');
            
            setState(() {
              _clinicAddressController.text = finalAddress;
            });
          } else if (data.containsKey('display_name')) {
            setState(() {
              _clinicAddressController.text = data['display_name'].toString();
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur géolocalisation: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isGettingLocation = false);
    }
  }

  Future<void> _saveClinicInfo() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    try {
      final user = context.read<AuthProvider>().currentUser;
      if (user != null) {
        final data = {
          'clinic': {
            'name': _clinicNameController.text.trim(),
            'address': _clinicAddressController.text.trim(),
            'bio': _clinicBioController.text.trim(),
            'latitude': double.tryParse(_latController.text) ?? 48.8566,
            'longitude': double.tryParse(_lngController.text) ?? 2.3522,
            'clinicPhotoUrl': _clinicPhotoUrlController.text.trim(),
          }
        };

        await FirebaseFirestore.instance.collection('users').doc(user.uid).update(data);
        
        // Also update the practitioner collection for search/map
        await FirebaseFirestore.instance.collection('practitioners').doc(user.uid).set({
          'name': user.name,
          'latitude': double.tryParse(_latController.text) ?? 48.8566,
          'longitude': double.tryParse(_lngController.text) ?? 2.3522,
          'address': _clinicAddressController.text.trim(),
          'clinicPhotoUrl': _clinicPhotoUrlController.text.trim(),
        }, SetOptions(merge: true));
        
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Cabinet mis à jour'), backgroundColor: AppColors.success),
           );
           context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error),
         );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Informations du Cabinet'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.maps_home_work, size: 60, color: AppColors.primaryDark),
              const SizedBox(height: 16),
              const Text(
                'Où recevez-vous vos patients ?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textMain),
              ),
              const SizedBox(height: 24),
              
              // Photo du bâtiment
              InkWell(
                onTap: _isLoading ? null : _pickAndUploadClinicImage,
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: _clinicPhotoUrlController.text.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: CachedNetworkImage(
                          imageUrl: _clinicPhotoUrlController.text,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                          errorWidget: (context, url, error) => const Icon(Icons.error),
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo, size: 40, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          Text('Ajouter la photo du bâtiment', style: TextStyle(color: Colors.grey.shade600)),
                        ],
                      ),
                ),
              ),
              const SizedBox(height: 32),
              
              TextFormField(
                controller: _clinicNameController,
                decoration: InputDecoration(
                  labelText: 'Nom du Cabinet / Clinique',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _clinicAddressController,
                decoration: InputDecoration(
                  labelText: 'Adresse complète',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _clinicBioController,
                decoration: InputDecoration(
                  labelText: 'Présentation du lieu (Accès, parking...)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _latController,
                      decoration: InputDecoration(
                        labelText: 'Latitude',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _lngController,
                      decoration: InputDecoration(
                        labelText: 'Longitude',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _isGettingLocation ? null : _getCurrentLocation,
                icon: _isGettingLocation 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.my_location),
                label: const Text('Utiliser ma position actuelle'),
              ),
              const SizedBox(height: 24),
              
              ElevatedButton(
                onPressed: _isLoading ? null : _saveClinicInfo,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : const Text('Enregistrer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
