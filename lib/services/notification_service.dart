// ============================================================
// NotificationService (로컬 푸시 알림 관리)
// ------------------------------------------------------------
// 앱 내에서 사용자에게 푸시 알림을 보내거나 특정 시간에
// 알림이 울리도록 예약(스케줄링)하는 역할을 담당합니다.
// ============================================================

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/task.dart';

class NotificationService {
  // 싱글톤 패턴: 앱 전체에서 하나의 인스턴스만 사용하도록 설정
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  // 알림 초기화 (앱 시작 시 main.dart에서 1회 호출)
  Future<void> init() async {
    if (_isInitialized) return;

    // 타임존 초기화 (스케줄링 알림을 위해 필수)
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Seoul')); // 한국 시간 기준

    // Android 알림 아이콘 설정 (기본 앱 아이콘 사용)
    const AndroidInitializationSettings androidInitSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS 알림 권한 설정
    const DarwinInitializationSettings iosInitSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidInitSettings,
      iOS: iosInitSettings,
    );

    await _notificationsPlugin.initialize(initSettings);
    _isInitialized = true;
  }

  // 할 일(Task) 시작 10분 전 알림 예약
  Future<void> scheduleTaskNotification(Task task) async {
    if (task.startTime == null || task.isDone) return;

    // 알림을 울릴 시간: 시작 시간(startTime)에서 10분 뺌
    final scheduledTime = task.startTime!.subtract(const Duration(minutes: 10));
    
    // 예약할 시간이 이미 과거라면 알림을 예약하지 않음
    if (scheduledTime.isBefore(DateTime.now())) return;

    // 알림 설정 (채널 ID, 이름, 중요도 등)
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'task_reminder_channel',
      '할 일 시작 알림',
      channelDescription: '할 일 시작 10분 전에 알려줍니다.',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    // 고유 ID는 task의 hashCode를 사용하여 기존 알림을 덮어씌울 수 있게 함
    final notificationId = task.id.hashCode;

    await _notificationsPlugin.zonedSchedule(
      notificationId,
      '예스코 할 일 알림',
      '10분 뒤에 [${task.title}] 시작할 시간입니다!',
      tz.TZDateTime.from(scheduledTime, tz.local),
      platformDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // 할 일이 삭제되거나 취소되었을 때 예약된 알림 취소
  Future<void> cancelTaskNotification(String taskId) async {
    await _notificationsPlugin.cancel(taskId.hashCode);
  }
}
