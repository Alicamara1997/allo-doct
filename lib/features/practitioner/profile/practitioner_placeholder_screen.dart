import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';

class PractitionerPlaceholderScreen extends StatelessWidget {
  final String title;
  const PractitionerPlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Text('Écran $title (En cours de développement)'),
      ),
    );
  }
}
