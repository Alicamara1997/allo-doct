import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/constants/colors.dart';
import 'core/providers/auth_provider.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/patient/home/patient_home_screen.dart';
import 'features/patient/practitioner/practitioner_details_screen.dart';
import 'features/patient/profile/patient_edit_profile_screen.dart';
import 'features/patient/profile/medical_record_screen.dart';
import 'features/patient/profile/patient_address_screen.dart';
import 'features/patient/profile/patient_notification_settings_screen.dart';
import 'features/practitioner/home/practitioner_home_screen.dart';
import 'features/practitioner/profile/practitioner_edit_profile_screen.dart';
import 'features/practitioner/profile/practitioner_clinic_info_screen.dart';
import 'features/practitioner/profile/practitioner_billing_screen.dart';
import 'features/practitioner/profile/practitioner_support_screen.dart';

class AlloDoctApp extends StatelessWidget {
  const AlloDoctApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Watch auth state changes for go_router
    final authProvider = context.watch<AuthProvider>();

    final router = GoRouter(
      initialLocation: '/login',
      refreshListenable: authProvider,
      redirect: (context, state) {
        final isLoggedIn = authProvider.isAuthenticated;
        final isAuthRoute = state.uri.path == '/login' || state.uri.path == '/register';

        if (!isLoggedIn && !isAuthRoute) {
          return '/login';
        }

        if (isLoggedIn && isAuthRoute) {
          final user = authProvider.currentUser;
          if (user?.role == 'practitioner') {
            return '/practitioner_home';
          }
          return '/patient_home';
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/patient_home',
          builder: (context, state) => const PatientHomeScreen(),
        ),
        GoRoute(
          path: '/patient_edit_profile',
          builder: (context, state) => const PatientEditProfileScreen(),
        ),
        GoRoute(
          path: '/medical_record',
          builder: (context, state) => const MedicalRecordScreen(),
        ),
        GoRoute(
          path: '/patient_address',
          builder: (context, state) => const PatientAddressScreen(),
        ),
        GoRoute(
          path: '/patient_notifications',
          builder: (context, state) => const PatientNotificationSettingsScreen(),
        ),
        GoRoute(
          path: '/practitioner_home',
          builder: (context, state) => const PractitionerHomeScreen(),
        ),
        GoRoute(
          path: '/practitioner_details/:id',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            final data = state.extra as Map<String, dynamic>? ?? {};
            return PractitionerDetailsScreen(practitionerId: id, practitionerData: data);
          },
        ),
        GoRoute(
          path: '/practitioner_edit_profile',
          builder: (context, state) => const PractitionerEditProfileScreen(),
        ),
        GoRoute(
          path: '/practitioner_clinic_info',
          builder: (context, state) => const PractitionerClinicInfoScreen(),
        ),
        GoRoute(
          path: '/practitioner_billing',
          builder: (context, state) => const PractitionerBillingScreen(),
        ),
        GoRoute(
          path: '/practitioner_support',
          builder: (context, state) => const PractitionerSupportScreen(),
        ),
      ],
    );

    return MaterialApp.router(
      title: 'Allô-Doct',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          surface: AppColors.background,
        ),
        scaffoldBackgroundColor: AppColors.background,
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      routerConfig: router,
    );
  }
}
