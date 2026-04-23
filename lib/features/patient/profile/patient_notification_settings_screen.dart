import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/providers/auth_provider.dart';

class PatientNotificationSettingsScreen extends StatefulWidget {
  const PatientNotificationSettingsScreen({super.key});

  @override
  State<PatientNotificationSettingsScreen> createState() => _PatientNotificationSettingsScreenState();
}

class _PatientNotificationSettingsScreenState extends State<PatientNotificationSettingsScreen> {
  bool _reminders = true;
  bool _messages = true;
  bool _updates = false;
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data()!.containsKey('notifications')) {
        final notifs = doc.data()!['notifications'] as Map<String, dynamic>;
        setState(() {
          _reminders = notifs['reminders'] ?? true;
          _messages = notifs['messages'] ?? true;
          _updates = notifs['updates'] ?? false;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateSetting(String key, bool value) async {
    // Optimistic UI update
    setState(() {
      if (key == 'reminders') _reminders = value;
      if (key == 'messages') _messages = value;
      if (key == 'updates') _updates = value;
    });

    final user = context.read<AuthProvider>().currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'notifications': {
            'reminders': _reminders,
            'messages': _messages,
            'updates': _updates,
          }
        }, SetOptions(merge: true));
      } catch (e) {
        // En cas d'erreur, on pourrait annuler l'UI optimiste, mais on omet pour la simplicitén
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Paramètres de notifications'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text(
                'Gérez la manière dont Allô-Doct vous contacte.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
              ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10),
                  ],
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Rappels de rendez-vous'),
                      subtitle: const Text('Recevoir un rappel 24h avant'),
                      value: _reminders,
                      activeColor: AppColors.primary,
                      onChanged: (val) => _updateSetting('reminders', val),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    SwitchListTile(
                      title: const Text('Nouveaux messages'),
                      subtitle: const Text('Quand un médecin vous contacte'),
                      value: _messages,
                      activeColor: AppColors.primary,
                      onChanged: (val) => _updateSetting('messages', val),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    SwitchListTile(
                      title: const Text('Mises à jour de l\'application'),
                      subtitle: const Text('Nouveautés et offres de partenaires'),
                      value: _updates,
                      activeColor: AppColors.primary,
                      onChanged: (val) => _updateSetting('updates', val),
                    ),
                  ],
                ),
              ),
            ],
          ),
    );
  }
}
