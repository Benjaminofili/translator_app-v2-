// lib/features/history/screens/history_screen.dart
import 'package:flutter/material.dart';
import 'package:prototype_ai_core/core/constants/app_colors.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.history, size: 80, color: AppColors.textTertiary),
          SizedBox(height: 16),
          Text(
            'History Screen',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 20),
          ),
          Text(
            'Translation history will appear here.',
            style: TextStyle(color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }
}


