import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'api_service.dart';

class PushService {
  static const String _pushEnabledKey = 'push_enabled';
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final ApiService _apiService = ApiService();

  Future<void> init() async {
    tz.initializeTimeZones();

    // 初始化通知设置
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // 处理通知点击事件
      },
    );

    // 检查并设置定时推送
    await _setupDailyNotifications();
  }

  Future<void> _setupDailyNotifications() async {
    if (!await isPushEnabled()) return;

    // 取消所有现有的定时推送
    await _notifications.cancelAll();

    // 设置早上7点的推送
    await _scheduleDailyNotification(
      id: 1,
      hour: 7,
      minute: 0,
      title: '早安，新的一天开始啦！',
    );

    // 设置晚上20点的推送
    await _scheduleDailyNotification(
      id: 2,
      hour: 20,
      minute: 0,
      title: '晚安，来看看今天的佳句吧！',
    );
  }

  Future<void> _scheduleDailyNotification({
    required int id,
    required int hour,
    required int minute,
    required String title,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // 如果时间已经过了，设置为明天
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // 获取每日佳句
    try {
      final sentence = await _apiService.getDailySentence();
      final notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_notification',
          '每日推送',
          channelDescription: '每日佳句推送',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      await _notifications.zonedSchedule(
        id,
        title,
        '${sentence['en']}\n${sentence['cn']}',
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      print('获取每日佳句失败: $e');
    }
  }

  Future<bool> isPushEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_pushEnabledKey) ?? false;
  }

  Future<void> setPushEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_pushEnabledKey, enabled);
    
    if (enabled) {
      await _setupDailyNotifications();
    } else {
      await _notifications.cancelAll();
    }
  }
} 