import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:prototype_ai_core/core/transitions/transition_manager.dart';
import 'package:prototype_ai_core/features/main_navigation/screens/main_navigation_screen.dart';
import 'package:prototype_ai_core/services/notification_service.dart';
import 'package:prototype_ai_core/services/background_service.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'core/constants/app_colors.dart';
import 'core/utils/logger_utils.dart';
import 'services/model_service.dart';
import 'services/pack_downloader.dart';
import 'features/language_packs/screens/pack_management_screen.dart';
import 'package:prototype_ai_core/features/translator/screens/translation_screen.dart';
import 'package:prototype_ai_core/features/home/screens/home_screen.dart';
import 'core/transitions/liquid_page_transitions.dart';

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations (portrait only for now)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize services
  Logger.section('APP INITIALIZATION');
  Logger.info('MAIN', 'Starting ${AppConstants.appName} v${AppConstants.appVersion}');

  // Initialize model service
  final modelService = ModelService();
  final modelInitialized = await modelService.initialize();

  // Initialize notification service
  final notificationService = NotificationService();
  final notificationsInitialized = await notificationService.initialize();

  if (notificationsInitialized) {
    await notificationService.requestPermissions();
  }

  // Initialize background download service
  final backgroundService = BackgroundDownloadService();
  final backgroundInitialized = await backgroundService.initialize();

  if (backgroundInitialized) {
    // Start periodic check for paused downloads
    await backgroundService.startPeriodicCheck();
    Logger.success('MAIN', 'Background service initialized');
  }

  // Initialize pack downloader
  final downloader = PackDownloader();
  await downloader.init();

  if (modelInitialized && notificationsInitialized && backgroundInitialized) {
    Logger.success('MAIN', 'All services initialized');
  } else {
    Logger.warning('MAIN', 'Some services failed to initialize');
  }

  runApp(const VoiceTranslatorApp());
}

class VoiceTranslatorApp extends StatelessWidget {
  const VoiceTranslatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // App info
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,

      // Theme
      theme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,

      // Home screen
      home:
      MainNavigationScreen()
      // const HomeScreen(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// HOME SCREEN (Temporary - will be replaced with proper screens)
// ═══════════════════════════════════════════════════════════════

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo (placeholder)
              Icon(
                Icons.translate_rounded,
                size: 80,
                color: AppColors.accent,
              ),

              const SizedBox(height: 24),

              // App Name
              Text(
                AppConstants.appName,
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontSize: 32,
                ),
              ),

              const SizedBox(height: 8),

              // App Description
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: Text(
                  AppConstants.appDescription,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 48),

              // Status Card
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                  border: Border.all(
                    color: AppColors.divider,
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    _buildStatusRow(
                      context,
                      icon: Icons.check_circle_outline,
                      label: 'Core System',
                      status: 'Ready',
                      isReady: true,
                    ),
                    const SizedBox(height: 16),
                    _buildStatusRow(
                      context,
                      icon: Icons.download_outlined,
                      label: 'Language Packs',
                      status: '0 installed',
                      isReady: false,
                    ),
                    const SizedBox(height: 16),
                    _buildStatusRow(
                      context,
                      icon: Icons.mic_none,
                      label: 'Voice System',
                      status: 'Pending',
                      isReady: false,
                    ),
                    const SizedBox(height: 16),
                    _buildStatusRow(
                      context,
                      icon: Icons.cloud_download_outlined,
                      label: 'Background Service',
                      status: 'Active',
                      isReady: true,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Primary Action Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      TransitionManager.fadeScale(const TranslatorScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.mic_none, size: 20),
                      const SizedBox(width: 8),
                      const Text('Start Translating'),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Secondary Action Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      TransitionManager.fadeScale(const  PackManagementScreen()),
                    );
                  },
                  style: TextButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.download_outlined, size: 18),
                      const SizedBox(width: 8),
                      const Text('Manage Language Packs'),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Version Info
              Text(
                'Version ${AppConstants.appVersion}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusRow(
      BuildContext context, {
        required IconData icon,
        required String label,
        required String status,
        required bool isReady,
      }) {
    return Row(
      children: [
        Icon(
          icon,
          color: isReady ? AppColors.success : AppColors.textTertiary,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                status,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isReady ? AppColors.success : AppColors.textTertiary,
          ),
        ),
      ],
    );
  }
}