import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/appointment_service.dart';
import '../../../core/models/appointment_model.dart';
import '../../../core/constants/colors.dart';
import '../schedule/practitioner_schedule_screen.dart';
import '../profile/practitioner_profile_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class PractitionerHomeScreen extends StatefulWidget {
  const PractitionerHomeScreen({super.key});

  @override
  State<PractitionerHomeScreen> createState() => _PractitionerHomeScreenState();
}

class _PractitionerHomeScreenState extends State<PractitionerHomeScreen> {
  int _currentBottomNavIndex = 0;

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(20),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textMain,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentItem(BuildContext context, AppointmentModel appt) {
    // Formater l'heure et la date
    final timeString = DateFormat('HH:mm').format(appt.dateTime);
    final dateString = DateFormat('dd/MM').format(appt.dateTime);
    
    Color statusColor = AppColors.warning;
    String statusText = 'En attente';
    if (appt.status == 'confirmed') {
      statusColor = AppColors.success;
      statusText = 'Confirmé';
    } else if (appt.status == 'cancelled') {
      statusColor = AppColors.error;
      statusText = 'Annulé';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      timeString,
                      style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      dateString,
                      style: const TextStyle(color: AppColors.primary, fontSize: 10),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appt.patientName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 8, height: 8,
                          decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          statusText,
                          style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          if (appt.status == 'pending') ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      await AppointmentService().updateAppointmentStatus(appt.id!, 'cancelled');
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Refuser'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await AppointmentService().updateAppointmentStatus(appt.id!, 'confirmed');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Accepter'),
                  ),
                ),
              ],
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildHomeContent(BuildContext context, String name, String? uid) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tableau de bord',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Dr. $name',
                    style: const TextStyle(
                      color: AppColors.primaryDark,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                   // Profile Photo
                  Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: context.watch<AuthProvider>().currentUser?.photoUrl != null
                        ? CachedNetworkImage(
                            imageUrl: context.watch<AuthProvider>().currentUser!.photoUrl!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const CircularProgressIndicator(),
                            errorWidget: (context, url, error) => const Icon(Icons.person, color: AppColors.primary),
                          )
                        : const Icon(Icons.person, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(10),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.logout, color: AppColors.error),
                      onPressed: () => context.read<AuthProvider>().signOut(),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Statistiques
          Row(
            children: [
              _buildStatCard(
                'RDV Aujourd\'hui',
                '8',
                Icons.calendar_today,
                AppColors.primary,
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                'Nouveaux Patients',
                '3',
                Icons.people_outline,
                AppColors.secondary,
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Section Agenda
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Vos prochains RDV',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMain,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('Tout voir'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Liste des RDV depuis Firestore
          StreamBuilder<List<AppointmentModel>>(
            stream: AppointmentService().getPractitionerAppointments(uid ?? ''),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                 return const Center(child: Text('Erreur de chargement des rendez-vous.'));
              }

              final appointments = snapshot.data ?? [];

              if (appointments.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      children: [
                        Icon(Icons.event_busy, size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          'Aucun rendez-vous prévu.',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: appointments.length,
                itemBuilder: (context, index) {
                  return _buildAppointmentItem(context, appointments[index]);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final name = user?.name ?? 'Docteur';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: IndexedStack(
          index: _currentBottomNavIndex,
          children: [
            _buildHomeContent(context, name, user?.uid),
            const PractitionerScheduleScreen(),
            const PractitionerProfileScreen(),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentBottomNavIndex,
            onTap: (index) {
              setState(() {
                _currentBottomNavIndex = index;
              });
            },
            backgroundColor: Colors.white,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: Colors.grey.shade400,
            showSelectedLabels: true,
            showUnselectedLabels: true,
            elevation: 0,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard),
                label: 'Dashboard',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.calendar_month),
                label: 'Planning',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profil',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
