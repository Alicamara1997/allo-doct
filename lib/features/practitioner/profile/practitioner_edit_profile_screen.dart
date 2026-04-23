import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/constants/colors.dart';
import 'package:cached_network_image/cached_network_image.dart';

class PractitionerEditProfileScreen extends StatefulWidget {
  const PractitionerEditProfileScreen({super.key});

  @override
  State<PractitionerEditProfileScreen> createState() => _PractitionerEditProfileScreenState();
}

class _PractitionerEditProfileScreenState extends State<PractitionerEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _specialtyController = TextEditingController();
  final _photoUrlController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().currentUser;
      if (user != null) {
        _nameController.text = user.name;
        _photoUrlController.text = user.photoUrl ?? '';
      }
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    try {
      final user = context.read<AuthProvider>().currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'specialty': _specialtyController.text.trim(),
          'photoUrl': _photoUrlController.text.trim(),
        });

        // Sync with practitioners collection for search results
        await FirebaseFirestore.instance.collection('practitioners').doc(user.uid).set({
          'name': _nameController.text.trim(),
          'specialty': _specialtyController.text.trim(),
          'photoUrl': _photoUrlController.text.trim(),
        }, SetOptions(merge: true));
        
         if (mounted) {
            // Rafraîchir les données locales de l'utilisateur
            await context.read<AuthProvider>().refreshUser();

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profil mis à jour'), backgroundColor: AppColors.success),
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

  Future<void> _pickAndUploadImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    
    if (image == null) return;
    
    setState(() => _isLoading = true);
    try {
      final user = context.read<AuthProvider>().currentUser;
      if (user == null) return;

      final storageRef = FirebaseStorage.instance.ref();
      final profilePicRef = storageRef.child("profiles/${user.uid}.jpg");

      // Upload bytes (web friendly)
      final bytes = await image.readAsBytes();
      await profilePicRef.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      
      final String downloadUrl = await profilePicRef.getDownloadURL();
      
      setState(() {
        _photoUrlController.text = downloadUrl;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo téléchargée avec succès !'), backgroundColor: AppColors.success),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Modifier mes informations'),
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
              Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 100, height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary, width: 2),
                      ),
                      child: ClipOval(
                        child: _photoUrlController.text.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: _photoUrlController.text,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const CircularProgressIndicator(),
                              errorWidget: (context, url, error) => const Icon(Icons.person, size: 50, color: AppColors.primary),
                            )
                          : const Icon(Icons.person, size: 50, color: AppColors.primary),
                      ),
                    ),
                    InkWell(
                      onTap: _isLoading ? null : _pickAndUploadImage,
                      child: const CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.secondary,
                        child: Icon(Icons.camera_alt, size: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nom Complet',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Numéro de téléphone',
                  prefixIcon: const Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _specialtyController,
                decoration: InputDecoration(
                  labelText: 'Spécialité (ex: Cardiologue)',
                  prefixIcon: const Icon(Icons.medical_services_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _photoUrlController,
                decoration: InputDecoration(
                  labelText: 'URL de la photo de profil',
                  prefixIcon: const Icon(Icons.image_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  hintText: 'https://...',
                ),
                keyboardType: TextInputType.url,
                onChanged: (val) => setState(() {}), // Refresh preview
              ),
              const SizedBox(height: 32),
              
              ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : const Text('Enregistrer les modifications', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
