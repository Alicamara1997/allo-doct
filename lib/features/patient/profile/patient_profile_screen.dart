import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/constants/colors.dart';

class PatientProfileScreen extends StatelessWidget {
  const PatientProfileScreen({super.key});

  Widget _buildProfileOption({required IconData icon, required String title, required VoidCallback onTap, bool isDestructive = false}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDestructive ? AppColors.error.withAlpha(20) : AppColors.primary.withAlpha(20),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: isDestructive ? AppColors.error : AppColors.primary),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDestructive ? AppColors.error : AppColors.textMain,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Cette fonctionnalité sera bientôt disponible.'),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    return SingleChildScrollView(
      child: Column(
        children: [
          // Header profil
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 60, bottom: 30),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 10),
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.person, size: 50, color: AppColors.primary),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: AppColors.secondary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.edit, size: 16, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  user?.name ?? 'Utilisateur',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  user?.email ?? 'email@exemple.com',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Contenu options
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              elevation: 5,
              shadowColor: Colors.black.withAlpha(20),
              child: Column(
                children: [
                  _buildProfileOption(
                    icon: Icons.person_outline,
                    title: 'Modifier mes informations',
                    onTap: () {
                      context.push('/patient_edit_profile');
                    },
                  ),
                  const Divider(height: 1, indent: 60),
                  _buildProfileOption(
                    icon: Icons.location_on_outlined,
                    title: 'Mon adresse',
                    onTap: () => context.push('/patient_address'),
                  ),
                  const Divider(height: 1, indent: 60),
                  _buildProfileOption(
                    icon: Icons.medical_information_outlined,
                    title: 'Dossier médical',
                    onTap: () {
                      context.push('/medical_record');
                    },
                  ),
                  const Divider(height: 1, indent: 60),
                  _buildProfileOption(
                    icon: Icons.notifications_none,
                    title: 'Paramètres de notifications',
                    onTap: () => context.push('/patient_notifications'),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              elevation: 5,
              shadowColor: Colors.black.withAlpha(20),
              child: Column(
                children: [
                  _buildProfileOption(
                    icon: Icons.help_outline,
                    title: 'Aide & Support',
                    onTap: () => _showComingSoon(context),
                  ),
                  const Divider(height: 1, indent: 60),
                  _buildProfileOption(
                    icon: Icons.logout,
                    title: 'Se déconnecter',
                    isDestructive: true,
                    onTap: () => context.read<AuthProvider>().signOut(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
