// ============================================================
// WidgetService (홈 화면 위젯 연동 서비스)
// ------------------------------------------------------------
// 앱 내의 데이터를 스마트폰 바탕화면 위젯으로 전달합니다.
// ============================================================

import 'package:home_widget/home_widget.dart';
import '../models/task.dart';

class WidgetService {
  // 네이티브(Android/iOS) 쪽에 설정할 위젯의 고유 이름 (이후 네이티브 설정 시 사용됨)
  static const String androidWidgetName = 'HomeScreenWidgetProvider';
  static const String iosWidgetName = 'HomeScreenWidget';

  // 현재 남은 할 일 중 가장 중요한 3개를 추려서 위젯으로 보냅니다.
  static Future<void> sendTasksToWidget(List<Task> allTasks) async {
    final now = DateTime.now();
    
    // 1. 오늘 날짜이면서 아직 완료되지 않은 할 일만 필터링
    final todayTasks = allTasks.where((t) {
      return t.date.year == now.year &&
          t.date.month == now.month &&
          t.date.day == now.day &&
          !t.isDone;
    }).toList();

    // 2. 1사분면(중요+긴급)이거나 Top3로 지정된 핵심 할 일을 우선적으로 위로 올림
    todayTasks.sort((a, b) {
      final aPriority = (a.isImportant && a.isUrgent) || a.isTop3 ? 1 : 0;
      final bPriority = (b.isImportant && b.isUrgent) || b.isTop3 ? 1 : 0;
      return bPriority.compareTo(aPriority); // 내림차순 정렬
    });

    // 3. 위젯에 표시할 텍스트 만들기 (최대 3개)
    String widgetText = '';
    if (todayTasks.isEmpty) {
      widgetText = "모든 일정을 완료했습니다! 🎉";
    } else {
      final top3 = todayTasks.take(3).toList();
      widgetText = top3.map((t) {
        final prefix = ((t.isImportant && t.isUrgent) || t.isTop3) ? '🔥' : '✔️';
        return "$prefix ${t.title}";
      }).join('\n\n'); // 줄바꿈으로 연결
    }

    // 4. 네이티브 앱(바탕화면)에 'widget_task_list'라는 키값으로 텍스트 전달
    await HomeWidget.saveWidgetData<String>('widget_task_list', widgetText);

    // 5. 위젯 새로고침 명령 전송
    await HomeWidget.updateWidget(
      name: androidWidgetName,
      iOSName: iosWidgetName,
    );
  }
}
