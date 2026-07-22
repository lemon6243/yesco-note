package com.priorityplanner.flutter_app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class HomeScreenWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            // 방금 만든 레이아웃 파일을 연결
            val views = RemoteViews(context.packageName, R.layout.widget_layout)

            // 플러터(Dart)에서 'widget_task_list'라는 키로 저장한 글자를 불러옴
            val tasksText = widgetData.getString("widget_task_list", "오늘의 할 일이 없습니다! 🎉")
            
            // 레이아웃의 widget_task_text 아이디를 가진 텍스트뷰에 글자를 입력
            views.setTextViewText(R.id.widget_task_text, tasksText)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
