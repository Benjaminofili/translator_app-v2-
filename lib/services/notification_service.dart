// lib/services/notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../core/utils/logger_utils.dart';
import '../core/utils/format_utils.dart';
import 'package:permission_handler/permission_handler.dart';

/// 🔔 Notification Service
/// 
/// Manages download progress notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = 
      FlutterLocalNotificationsPlugin();
  
  bool _isInitialized = false;

  // Notification IDs
  static const int downloadNotificationId = 1000;

  // ═══════════════════════════════════════════════════════════════
  // INITIALIZATION
  // ═══════════════════════════════════════════════════════════════

  /// Initialize notification service
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      Logger.info('NOTIFICATION', 'Initializing...');

      // Android settings
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      
      // iOS settings
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      final initialized = await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      _isInitialized = initialized ?? false;

      if (_isInitialized) {
        // Create notification channel for Android
        await _createNotificationChannel();
        Logger.success('NOTIFICATION', 'Service initialized');
      }

      return _isInitialized;

    } catch (e, stackTrace) {
      Logger.error('NOTIFICATION', 'Initialization failed', e, stackTrace);
      return false;
    }
  }

  /// Create Android notification channel
  Future<void> _createNotificationChannel() async {
    const channel = AndroidNotificationChannel(
      'download_channel',
      'Downloads',
      description: 'Language pack download notifications',
      importance: Importance.low,
      playSound: false,
      enableVibration: false,
      showBadge: false,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    Logger.info('NOTIFICATION', 'Channel created');
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    Logger.info('NOTIFICATION', 'Tapped: ${response.payload}');
    // TODO: Navigate to downloads screen
  }

  // ═══════════════════════════════════════════════════════════════
  // DOWNLOAD NOTIFICATIONS
  // ═══════════════════════════════════════════════════════════════

  /// Show download progress notification
  Future<void> showDownloadProgress({
    required String packId,
    required String packName,
    required int progress, // 0-100
    required int downloadedBytes,
    required int totalBytes,
    String? speed,
  }) async {
    if (!_isInitialized) {
      Logger.warning('NOTIFICATION', 'Not initialized');
      return;
    }

    try {
      final androidDetails = AndroidNotificationDetails(
        'download_channel',
        'Downloads',
        channelDescription: 'Language pack downloads',
        importance: Importance.low,
        priority: Priority.low,
        ongoing: true, // Cannot be dismissed
        autoCancel: false,
        showProgress: true,
        maxProgress: 100,
        progress: progress,
        playSound: false,
        enableVibration: false,
        icon: 'ic_download',
        subText: speed,
        styleInformation: BigTextStyleInformation(
          '${FormatUtils.formatBytes(downloadedBytes)} / ${FormatUtils.formatBytes(totalBytes)}',
        ),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: false,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        downloadNotificationId,
        'Downloading $packName',
        '$progress% - ${FormatUtils.formatBytes(downloadedBytes)} / ${FormatUtils.formatBytes(totalBytes)}',
        details,
        payload: 'download:$packId',
      );

    } catch (e, stackTrace) {
      Logger.error('NOTIFICATION', 'Show progress failed', e, stackTrace);
    }
  }

  /// Show download paused notification
  Future<void> showDownloadPaused({
    required String packId,
    required String packName,
    required int progress,
  }) async {
    if (!_isInitialized) return;

    try {
      const androidDetails = AndroidNotificationDetails(
        'download_channel',
        'Downloads',
        importance: Importance.low,
        priority: Priority.low,
        ongoing: false,
        autoCancel: true,
        playSound: false,
        icon: 'ic_pause',
      );

      const iosDetails = DarwinNotificationDetails();

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        downloadNotificationId,
        'Download Paused',
        '$packName - $progress%',
        details,
        payload: 'paused:$packId',
      );

    } catch (e) {
      Logger.error('NOTIFICATION', 'Show paused failed', e);
    }
  }

  /// Show download completed notification
  Future<void> showDownloadCompleted({
    required String packId,
    required String packName,
  }) async {
    if (!_isInitialized) return;

    try {
      const androidDetails = AndroidNotificationDetails(
        'download_channel',
        'Downloads',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        icon: 'ic_check',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        downloadNotificationId,
        'Download Complete',
        '$packName is ready to use!',
        details,
        payload: 'complete:$packId',
      );

    } catch (e) {
      Logger.error('NOTIFICATION', 'Show completed failed', e);
    }
  }

  /// Show download failed notification
  Future<void> showDownloadFailed({
    required String packId,
    required String packName,
    String? error,
  }) async {
    if (!_isInitialized) return;

    try {
      const androidDetails = AndroidNotificationDetails(
        'download_channel',
        'Downloads',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        icon: 'ic_error',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        downloadNotificationId,
        'Download Failed',
        '$packName - ${error ?? "Unknown error"}',
        details,
        payload: 'failed:$packId',
      );

    } catch (e) {
      Logger.error('NOTIFICATION', 'Show failed failed', e);
    }
  }

  /// Cancel/hide download notification
  Future<void> cancelDownloadNotification() async {
    if (!_isInitialized) return;

    try {
      await _notifications.cancel(downloadNotificationId);
    } catch (e) {
      Logger.error('NOTIFICATION', 'Cancel failed', e);
    }
  }

  /// Cancel all notifications
  Future<void> cancelAll() async {
    if (!_isInitialized) return;

    try {
      await _notifications.cancelAll();
    } catch (e) {
      Logger.error('NOTIFICATION', 'Cancel all failed', e);
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // PERMISSIONS
  // ═══════════════════════════════════════════════════════════════

  /// Request notification permissions (iOS mainly)
  Future<bool> requestPermissions() async {
    try {
      // Use permission_handler for cross-platform request
      final status = await Permission.notification.request();
      Logger.info('NOTIFICATION', 'Permission Status: $status');

      if (status.isGranted) {
        Logger.success('NOTIFICATION', 'Notification permission granted.');
        return true;
      } else if (status.isDenied) {
        Logger.warning('NOTIFICATION', 'Notification permission denied.');
        return false;
      } else if (status.isPermanentlyDenied) {
        Logger.error('NOTIFICATION', 'Notification permission permanently denied.');
        // Optionally: Trigger UI to guide user to settings (e.g., openAppSettings())
        return false;
      }
      // Handle other statuses if necessary (e.g., restricted)
      return false; // Assume failure for other statuses
    } catch (e, stackTrace) {
      Logger.error('NOTIFICATION', 'Permission request failed', e, stackTrace);
      return false;
    }
  }
}
