import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'core/utils/logger_utils.dart';
import 'services/model_service.dart';
import 'features/language_packs/screens/pack_management_screen.dart';

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
  final initialized = await modelService.initialize();

  if (initialized) {
    Logger.success('MAIN', 'All services initialized');
  } else {
    Logger.warning('MAIN', 'Some services failed to initialize');
  }

  // Run app
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

      // Home screen (placeholder for now)
      home: const HomeScreen(),
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
      body: Container(
        decoration: AppTheme.getGradientBackground(),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Logo (placeholder)
                Icon(
                  Icons.translate_rounded,
                  size: 100,
                  color: Theme.of(context).colorScheme.primary,
                ),

                const SizedBox(height: 32),

                // App Name
                Text(
                  AppConstants.appName,
                  style: Theme.of(context).textTheme.displaySmall,
                ),

                const SizedBox(height: 8),

                // App Description
                Text(
                  AppConstants.appDescription,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 48),

                // Status Card
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        _buildStatusRow(
                          context,
                          icon: Icons.check_circle,
                          label: 'Core System',
                          status: 'Ready',
                          isReady: true,
                        ),
                        const SizedBox(height: 16),
                        _buildStatusRow(
                          context,
                          icon: Icons.downloading,
                          label: 'Language Packs',
                          status: '0 installed',
                          isReady: false,
                        ),
                        const SizedBox(height: 16),
                        _buildStatusRow(
                          context,
                          icon: Icons.mic,
                          label: 'Voice System',
                          status: 'Pending',
                          isReady: false,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Action Button
                ElevatedButton.icon(
                  onPressed: () {
                    // Navigate to pack management screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PackManagementScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.download),
                  label: const Text('Download Language Packs'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Version Info
                Text(
                  'Version ${AppConstants.appVersion}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
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
          color: isReady
              ? Theme.of(context).colorScheme.secondary
              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          size: 24,
        ),
        const SizedBox(width: 16),
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
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isReady
                ? Theme.of(context).colorScheme.secondary
                : Theme.of(context).colorScheme.error.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}