import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/models/schedule_model.dart';
import '../../../core/services/schedule_service.dart';
import '../../../core/constants/colors.dart';

class PractitionerScheduleScreen extends StatefulWidget {
  const PractitionerScheduleScreen({super.key});

  @override
  State<PractitionerScheduleScreen> createState() => _PractitionerScheduleScreenState();
}

class _PractitionerScheduleScreenState extends State<PractitionerScheduleScreen> {
  bool _isLoading = false;
  String? _scheduleId;
  
  // Lundi(1) à Dimanche(7)
  final Map<int, String> _days = {
    1: 'Lundi', 2: 'Mardi', 3: 'Mercredi', 4: 'Jeudi',
    5: 'Vendredi', 6: 'Samedi', 7: 'Dimanche'
  };
  
  // Stocke si le jour est travaillé. Pour simplifier, si actif on met 09:00 à 17:00 (intervalles de 30min).
  final Map<int, bool> _activeDays = {
    1: true, 2: true, 3: true, 4: true, 5: true, 6: false, 7: false
  };

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    final schedule = await ScheduleService().fetchPractitionerSchedule(user.uid);
    if (schedule != null && mounted) {
      setState(() {
        _scheduleId = schedule.id;
        for (int i = 1; i <= 7; i++) {
          _activeDays[i] = schedule.weeklySlots.containsKey(i) && schedule.weeklySlots[i]!.isNotEmpty;
        }
      });
    }
  }

  Future<void> _saveSchedule() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    // Génération automatique des créneaux
    Map<int, List<String>> newSlots = {};
    for (int i = 1; i <= 7; i++) {
      if (_activeDays[i] == true) {
        // Horaires de base 09:00 à 17:00 chaque 30min
        newSlots[i] = [
          '09:00', '09:30', '10:00', '10:30', '11:00', '11:30',
          '14:00', '14:30', '15:00', '15:30', '16:00', '16:30', '17:00'
        ];
      }
    }

    final schedule = ScheduleModel(
      id: _scheduleId,
      practitionerId: user.uid,
      weeklySlots: newSlots,
      isVacation: false,
    );

    final success = await ScheduleService().saveSchedule(schedule);

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Horaires mis à jour.'), backgroundColor: AppColors.success),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur de mise à jour.'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 60, 24, 30),
          decoration: const BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mon Planning',
                style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Définissez vos jours de disponibilité.',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
        
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: 7,
            itemBuilder: (context, index) {
              final dayIndex = index + 1;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(5),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: SwitchListTile(
                  activeColor: AppColors.primary,
                  title: Text(
                    _days[dayIndex]!,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(_activeDays[dayIndex]! ? '09:00 - 17:00' : 'Repos'),
                  value: _activeDays[dayIndex]!,
                  onChanged: (val) {
                    setState(() {
                      _activeDays[dayIndex] = val;
                    });
                  },
                ),
              );
            },
          ),
        ),
        
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveSchedule,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isLoading 
                ? const CircularProgressIndicator(color: Colors.white) 
                : const Text('Enregistrer le planning', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}
