// ============================================================
// main.dart (앱 시작점)
// ------------------------------------------------------------
// 이 파일은 앱이 실행될 때 가장 먼저 동작하는 코드입니다.
// 1) Hive 로컬 데이터베이스를 초기화하고
// 2) Provider(AppState)를 앱 전체에 연결하고
// 3) 한국어 날짜 형식을 준비한 뒤
// 4) 첫 화면(MainNavigation)을 보여줍니다.
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'services/storage_service.dart';
import 'services/app_state.dart';
import 'theme/app_theme.dart';
import 'screens/main_navigation.dart';
import 'services/notification_service.dart'; // <--- 추가


void main() async {
  // Flutter 엔진과 위젯 바인딩을 먼저 준비합니다.
  WidgetsFlutterBinding.ensureInitialized();

  // 한국어 날짜 형식 준비
  await initializeDateFormatting('ko_KR');

  // [새로 추가된 부분] 로컬 알림 서비스 초기화
  final notificationService = NotificationService();
  await notificationService.init();

  // 로컬 데이터베이스(Hive) 초기화
  final storageService = StorageService();
  await storageService.init();

  // 앱 상태 객체 생성
  final appState = AppState(storageService);
  await appState.loadThemePreference();
  await appState.loadGrowthAnimal(); 
  await appState.initializeAndCarryOverTasks();
  await appState.generateRepeatingTasks(); 

  runApp(ChangeNotifierProvider.value(value: appState, child: const MyApp()));
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return MaterialApp(
      title: 'Priority Planner',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: appState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const MainNavigation(),
    );
  }
}
