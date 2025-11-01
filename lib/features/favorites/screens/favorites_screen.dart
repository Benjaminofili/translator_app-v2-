// lib/features/favorites/screens/favorites_screen.dart
import 'package:flutter/material.dart';
import 'package:prototype_ai_core/core/constants/app_colors.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.star_border, size: 80, color: AppColors.textTertiary),
          SizedBox(height: 16),
          Text(
            'Favorites Screen',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 20),
          ),
          Text(
            'Saved translations will appear here.',
            style: TextStyle(color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }
}

