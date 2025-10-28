// lib/services/background_download_service.dart
import 'dart:async';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../core/utils/logger_utils.dart';
import 'pack_downloader.dart';
import 'notification_service.dart';

/// 🔄 Background Download Service
/// 
/// Manages downloads when app is in background or closed
class BackgroundDownloadService {
  static final BackgroundDownloadService _instance = BackgroundDownloadService._internal();
  factory BackgroundDownloadService() => _instance;
  BackgroundDownloadService._internal();

  static const String _taskName = 'background_download_task';
  static const String _periodicTaskName = 'periodic_download_check';

  bool _isInitialized = false;
  final Battery _battery = Battery();
  final Connectivity _connectivity = Connectivity();

  // Settings
  bool _wifiOnlyMode = false;
  bool _batteryAwareMode = true;
  int _lowBatteryThreshold = 20; // Pause downloads below 20%

  // ═══════════════════════════════════════════════════════════════
  // INITIALIZATION
  // ═══════════════════════════════════════════════════════════════

  /// Initialize background service
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      Logger.info('BACKGROUND', 'Initializing WorkManager...');

      await Workmanager().initialize(
        callbackDispatcher,
      );

      // Load settings
      await _loadSettings();

      _isInitialized = true;
      Logger.success('BACKGROUND', 'WorkManager initialized');
      return true;

    } catch (e, stackTrace) {
      Logger.error('BACKGROUND', 'Initialization failed', e, stackTrace);
      return false;
    }
  }

  /// Load settings from SharedPreferences
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _wifiOnlyMode = prefs.getBool('wifi_only_mode') ?? false;
      _batteryAwareMode = prefs.getBool('battery_aware_mode') ?? true;
      _lowBatteryThreshold = prefs.getInt('low_battery_threshold') ?? 20;

      Logger.info('BACKGROUND', 'Settings loaded - WiFi Only: $_wifiOnlyMode, Battery Aware: $_batteryAwareMode');
    } catch (e) {
      Logger.error('BACKGROUND', 'Failed to load settings', e);
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // DOWNLOAD MANAGEMENT
  // ═══════════════════════════════════════════════════════════════

  /// Start background download
  Future<bool> startBackgroundDownload(String packId) async {
    if (!_isInitialized) {
      Logger.warning('BACKGROUND', 'Service not initialized');
      return false;
    }

    try {
      // Check conditions before starting
      if (!await _checkDownloadConditions()) {
        Logger.warning('BACKGROUND', 'Download conditions not met');
        return false;
      }

      Logger.info('BACKGROUND', 'Starting background download: $packId');

      await Workmanager().registerOneOffTask(
        '$_taskName-$packId',
        _taskName,
        inputData: {
          'packId': packId,
          'action': 'download',
        },
        constraints: Constraints(
          networkType: _wifiOnlyMode ? NetworkType.unmetered : NetworkType.connected,
          requiresBatteryNotLow: _batteryAwareMode,
          requiresCharging: false,
        ),
        backoffPolicy: BackoffPolicy.exponential,
        backoffPolicyDelay: Duration(seconds: 30),
      );

      Logger.success('BACKGROUND', 'Background task registered: $packId');
      return true;

    } catch (e, stackTrace) {
      Logger.error('BACKGROUND', 'Failed to start background download', e, stackTrace);
      return false;
    }
  }

  /// Resume background download
  Future<bool> resumeBackgroundDownload(String packId) async {
    if (!_isInitialized) return false;

    try {
      Logger.info('BACKGROUND', 'Resuming background download: $packId');

      await Workmanager().registerOneOffTask(
        '$_taskName-$packId',
        _taskName,
        inputData: {
          'packId': packId,
          'action': 'resume',
        },
        constraints: Constraints(
          networkType: _wifiOnlyMode ? NetworkType.unmetered : NetworkType.connected,
          requiresBatteryNotLow: _batteryAwareMode,
        ),
      );

      return true;
    } catch (e) {
      Logger.error('BACKGROUND', 'Failed to resume', e);
      return false;
    }
  }

  /// Cancel background download
  Future<bool> cancelBackgroundDownload(String packId) async {
    if (!_isInitialized) return false;

    try {
      Logger.info('BACKGROUND', 'Cancelling background download: $packId');
      await Workmanager().cancelByUniqueName('$_taskName-$packId');
      return true;
    } catch (e) {
      Logger.error('BACKGROUND', 'Failed to cancel', e);
      return false;
    }
  }

  /// Check if download conditions are met
  Future<bool> _checkDownloadConditions() async {
    try {
      // Check WiFi if required
      if (_wifiOnlyMode) {
        final List<ConnectivityResult> connectivityResults = await _connectivity.checkConnectivity();
        final isWifi = connectivityResults.contains(ConnectivityResult.wifi);

        if (!isWifi) {
          Logger.warning('BACKGROUND', 'WiFi only mode enabled, but not on WiFi');
          return false;
        }
      }

      // Check battery if battery-aware mode is enabled
      if (_batteryAwareMode) {
        final batteryLevel = await _battery.batteryLevel;
        if (batteryLevel < _lowBatteryThreshold) {
          Logger.warning('BACKGROUND', 'Battery too low: $batteryLevel%');
          return false;
        }
      }

      return true;

    } catch (e) {
      Logger.error('BACKGROUND', 'Failed to check conditions', e);
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // SETTINGS
  // ═══════════════════════════════════════════════════════════════

  /// Enable/disable WiFi only mode
  Future<void> setWifiOnlyMode(bool enabled) async {
    _wifiOnlyMode = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('wifi_only_mode', enabled);
    Logger.info('BACKGROUND', 'WiFi only mode: $enabled');
  }

  /// Enable/disable battery aware mode
  Future<void> setBatteryAwareMode(bool enabled) async {
    _batteryAwareMode = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('battery_aware_mode', enabled);
    Logger.info('BACKGROUND', 'Battery aware mode: $enabled');
  }

  /// Set low battery threshold
  Future<void> setLowBatteryThreshold(int threshold) async {
    _lowBatteryThreshold = threshold;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('low_battery_threshold', threshold);
    Logger.info('BACKGROUND', 'Low battery threshold: $threshold%');
  }

  // Getters
  bool get isWifiOnlyMode => _wifiOnlyMode;
  bool get isBatteryAwareMode => _batteryAwareMode;
  int get lowBatteryThreshold => _lowBatteryThreshold;

  // ═══════════════════════════════════════════════════════════════
  // MONITORING
  // ═══════════════════════════════════════════════════════════════

  /// Start periodic check for paused downloads
  Future<void> startPeriodicCheck() async {
    if (!_isInitialized) return;

    try {
      await Workmanager().registerPeriodicTask(
        _periodicTaskName,
        _periodicTaskName,
        frequency: Duration(minutes: 15), // Minimum allowed
        constraints: Constraints(
          networkType: _wifiOnlyMode ? NetworkType.unmetered : NetworkType.connected,
        ),
      );

      Logger.info('BACKGROUND', 'Periodic check registered');
    } catch (e) {
      Logger.error('BACKGROUND', 'Failed to register periodic check', e);
    }
  }

  /// Stop periodic check
  Future<void> stopPeriodicCheck() async {
    if (!_isInitialized) return;

    try {
      await Workmanager().cancelByUniqueName(_periodicTaskName);
      Logger.info('BACKGROUND', 'Periodic check cancelled');
    } catch (e) {
      Logger.error('BACKGROUND', 'Failed to stop periodic check', e);
    }
  }

  /// Cancel all background tasks
  Future<void> cancelAll() async {
    if (!_isInitialized) return;

    try {
      await Workmanager().cancelAll();
      Logger.info('BACKGROUND', 'All background tasks cancelled');
    } catch (e) {
      Logger.error('BACKGROUND', 'Failed to cancel all', e);
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// WORKMANAGER CALLBACK (Top-level function)
// ═══════════════════════════════════════════════════════════════

/// Background task callback - MUST be top-level function
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      Logger.info('BACKGROUND', 'Task started: $task');

      if (task == BackgroundDownloadService._taskName) {
        return await _handleDownloadTask(inputData);
      } else if (task == BackgroundDownloadService._periodicTaskName) {
        return await _handlePeriodicCheck();
      }

      return Future.value(true);

    } catch (e, stackTrace) {
      Logger.error('BACKGROUND', 'Task failed: $task', e, stackTrace);
      return Future.value(false);
    }
  });
}

/// Handle download task
Future<bool> _handleDownloadTask(Map<String, dynamic>? inputData) async {
  try {
    if (inputData == null || !inputData.containsKey('packId')) {
      Logger.error('BACKGROUND', 'Invalid input data');
      return false;
    }

    final packId = inputData['packId'] as String;
    final action = inputData['action'] as String? ?? 'download';

    Logger.info('BACKGROUND', 'Handling $action for pack: $packId');

    // Initialize services
    final downloader = PackDownloader();
    await downloader.init();

    final notificationService = NotificationService();
    await notificationService.initialize();

    // Perform action
    DownloadResult result;
    if (action == 'resume') {
      result = await downloader.resumeDownload(packId);
    } else {
      result = await downloader.downloadPack(packId);
    }

    if (result.success) {
      Logger.success('BACKGROUND', 'Download completed: $packId');
      return true;
    } else {
      Logger.error('BACKGROUND', 'Download failed: ${result.error}');
      return false;
    }

  } catch (e, stackTrace) {
    Logger.error('BACKGROUND', 'Task execution failed', e, stackTrace);
    return false;
  }
}

/// Handle periodic check for paused downloads
Future<bool> _handlePeriodicCheck() async {
  try {
    Logger.info('BACKGROUND', 'Running periodic check...');

    final prefs = await SharedPreferences.getInstance();
    final pausedKeys = prefs.getKeys().where((key) => key.startsWith('download_'));

    if (pausedKeys.isEmpty) {
      Logger.info('BACKGROUND', 'No paused downloads found');
      return true;
    }

    Logger.info('BACKGROUND', 'Found ${pausedKeys.length} paused downloads');

    // Check if conditions are met to resume
    final backgroundService = BackgroundDownloadService();
    await backgroundService.initialize();

    for (var key in pausedKeys) {
      final packId = key.replaceFirst('download_', '');

      // Try to resume
      await backgroundService.resumeBackgroundDownload(packId);
    }

    return true;

  } catch (e, stackTrace) {
    Logger.error('BACKGROUND', 'Periodic check failed', e, stackTrace);
    return false;
  }
}