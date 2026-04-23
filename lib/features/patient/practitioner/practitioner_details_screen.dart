import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/appointment_service.dart';
import '../../../core/models/schedule_model.dart';
import '../../../core/services/schedule_service.dart';

class PractitionerDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> practitionerData;
  final String practitionerId;

  const PractitionerDetailsScreen({
    super.key,
    required this.practitionerId,
    required this.practitionerData,
  });

  @override
  State<PractitionerDetailsScreen> createState() => _PractitionerDetailsScreenState();
}

class _PractitionerDetailsScreenState extends State<PractitionerDetailsScreen> {
  int _selectedDayIndex = 0;
  int _selectedTimeIndex = -1;
  ScheduleModel? _practitionerSchedule;
  bool _isLoadingSchedule = true;

  // Simulation de jours et créneaux pour le design
  final List<String> _days = ['Auj', 'Demain', 'Dans 2j', 'Dans 3j', 'Dans 4j'];
  final List<String> _dates = ['1', '2', '3', '4', '5'];
  List<String> _timeSlots = [];

  @override
  void initState() {
    super.initState();
    // Preparer les labels de jours dynamiquement
    final now = DateTime.now();
    for (int i = 0; i < 5; i++) {
       final d = now.add(Duration(days: i));
       _dates[i] = d.day.toString();
    }
    _fetchSchedule();
  }

  Future<void> _fetchSchedule() async {
    final schedule = await ScheduleService().fetchPractitionerSchedule(widget.practitionerId);
    if (mounted) {
      setState(() {
        _practitionerSchedule = schedule;
        _isLoadingSchedule = false;
        _updateTimeSlotsForDay();
      });
    }
  }

  void _updateTimeSlotsForDay() {
    final selectedDate = DateTime.now().add(Duration(days: _selectedDayIndex));
    final weekday = selectedDate.weekday; // 1 = Lundi, 7 = Dimanche

    if (_practitionerSchedule != null && _practitionerSchedule!.weeklySlots.containsKey(weekday)) {
      _timeSlots = _practitionerSchedule!.weeklySlots[weekday] ?? [];
    } else {
      _timeSlots = []; // Indisponible
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.practitionerData['name'] ?? 'Inconnu';
    final specialty = widget.practitionerData['specialty'] ?? 'Médecine Générale';
    final bio = widget.practitionerData['bio'] ?? 
      'Ce praticien n\'a pas encore ajouté de biographie. Il vous recevra avec professionnalisme pour tout type de consultation liée à sa spécialité.';
    final rating = (widget.practitionerData['rating'] ?? 4.5).toString();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // AppBar avec Image/Header
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.primaryDark),
              ),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  gradient: LinearGradient(
                    colors: [AppColors.primaryDark, AppColors.primaryLight],
                    begin: Alignment.bottomRight,
                    end: Alignment.topLeft,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.medical_services_outlined,
                    size: 100,
                    color: Colors.white.withAlpha(50),
                  ),
                ),
              ),
            ),
          ),
          
          // Contenu principal
          SliverToBoxAdapter(
            child: Container(
              transform: Matrix4.translationValues(0.0, -30.0, 0.0),
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info Basique
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Dr. $name',
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textMain,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                specialty,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withAlpha(30),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.star_rounded, color: AppColors.warning, size: 20),
                              const SizedBox(width: 4),
                              Text(
                                rating,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textMain,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Apropos / Bio
                    const Text(
                      'À propos',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMain,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      bio,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Agenda: Jours
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Disponibilités',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textMain,
                          ),
                        ),
                        Text(
                          'Voir tout',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 80,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _days.length,
                        itemBuilder: (context, index) {
                          bool isSelected = _selectedDayIndex == index;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedDayIndex = index;
                                _selectedTimeIndex = -1; // Reset le créneau si on change de jour
                                _updateTimeSlotsForDay();
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 60,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primary : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected ? AppColors.primary : Colors.grey.shade300,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _days[index],
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isSelected ? Colors.white70 : AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _dates[index],
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? Colors.white : AppColors.textMain,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Agenda: Heures
                    if (_isLoadingSchedule)
                      const Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_timeSlots.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Text(
                          'Aucun créneau disponible pour ce jour.',
                          style: TextStyle(color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                        ),
                      )
                    else
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: List.generate(_timeSlots.length, (index) {
                          bool isSelected = _selectedTimeIndex == index;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedTimeIndex = index;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: (MediaQuery.of(context).size.width - 48 - 24) / 3, // 3 par ligne
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.secondary : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? AppColors.secondary : Colors.grey.shade300,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  _timeSlots[index],
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.white : AppColors.textMain,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    
                    const SizedBox(height: 100), // Espace pour le bouton flottant au cas où
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      
      // Bottom Bar avec bouton Réserver
      bottomSheet: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _selectedTimeIndex != -1 ? () async {
            final user = context.read<AuthProvider>().currentUser;
            if (user == null) return;
            
            // Simulation de la vraie date
            final now = DateTime.now();
            final parseTime = _timeSlots[_selectedTimeIndex].split(':');
            final appointedDate = DateTime(
              now.year, now.month, now.day + _selectedDayIndex, 
              int.parse(parseTime[0]), int.parse(parseTime[1])
            );

            // Afficher loader (très basique pour l'UI, on peut l'améliorer)
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => const Center(child: CircularProgressIndicator()),
            );

            final appointmentService = AppointmentService();
            final success = await appointmentService.createAppointment(
              patient: user,
              practitionerId: widget.practitionerId,
              practitionerName: widget.practitionerData['name'] ?? 'Inconnu',
              dateTime: appointedDate,
            );

            // Pop le dialog
            if (context.mounted) context.pop();

            if (success) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Rendez-vous confirmé avec succès !'),
                    backgroundColor: AppColors.success,
                  ),
                );
                context.pop(); // Retour à l'accueil
              }
            } else {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Erreur lors de la réservation.'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            }
          } : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            disabledBackgroundColor: Colors.grey.shade300,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            minimumSize: const Size(double.infinity, 54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 2,
          ),
          child: const Text(
            'Prendre Rendez-vous',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
