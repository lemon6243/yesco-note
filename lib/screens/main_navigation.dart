// ============================================================
// MainNavigation (하단 탭 네비게이션)
// ------------------------------------------------------------
// 앱의 주요 화면들을 하단 탭으로 전환하는 뼈대 화면입니다.
// 오른쪽 위에 캘린더·프로젝트·검색·다크모드·성장캐릭터 버튼을 둡니다.
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import 'today_screen.dart';
import 'morning_screen.dart';
import 'matrix_screen.dart';
import 'notes_screen.dart';
import 'reflection_screen.dart';
import 'habits_screen.dart';
import 'search_screen.dart';
import 'project_list_screen.dart';
import 'calendar_screen.dart';
import 'dashboard_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  // 탭마다 보여줄 화면들
  final List<Widget> _screens = const [
    TodayScreen(),
    MorningScreen(),
    MatrixScreen(),
    HabitsScreen(),
    NotesScreen(),
    ReflectionScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // [추가된 부분] 화면 렌더링이 끝난 직후 콜백을 실행하여 이월 알림을 띄웁니다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = context.read<AppState>();
      final carriedCount = appState.justCarriedOverCount;
      
      if (carriedCount > 0 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('어제 끝내지 못한 할 일 $carriedCount개가 오늘로 이월되었습니다.'),
            behavior: SnackBarBehavior.floating, // 화면 아래에 둥둥 뜨는 스타일
            backgroundColor: Theme.of(context).colorScheme.primary, // 테마 색상 적용
            duration: const Duration(seconds: 4), // 사용자가 읽을 수 있도록 4초간 유지
            action: SnackBarAction(
              label: '확인',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
        // 알림을 띄웠으니 다시 안 뜨도록 리셋
        appState.clearCarriedOverCount(); 
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(index: _currentIndex, children: _screens),
          // 상단 우측 버튼들 (겹쳐서 표시)
          Positioned(
            top: 8,
            right: 8,
            child: SafeArea(
              child: Row(
                children: [
                  // 성장 캐릭터: 맨 왼쪽 배치 (눌러서 통계 대시보드로 이동)
                  _circleImageButton(
                    imagePath: appState.growthImagePath,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const DashboardScreen()),
                    ),
                  ),
                  const SizedBox(width: 6),
                  _circleIconButton(
                    icon: Icons.calendar_month,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CalendarScreen()),
                    ),
                  ),
                  const SizedBox(width: 6),
                  _circleIconButton(
                    icon: Icons.folder_outlined,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProjectListScreen()),
                    ),
                  ),
                  const SizedBox(width: 6),
                  _circleIconButton(
                    icon: Icons.search_rounded,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SearchScreen()),
                    ),
                  ),
                  const SizedBox(width: 6),
                  _circleIconButton(
                    icon: appState.isDarkMode
                        ? Icons.light_mode_rounded
                        : Icons.dark_mode_rounded,
                    onTap: () => appState.toggleDarkMode(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.today_outlined),
            selectedIcon: Icon(Icons.today_rounded),
            label: '오늘',
          ),
          NavigationDestination(
            icon: Icon(Icons.wb_twilight_outlined),
            selectedIcon: Icon(Icons.wb_twilight_rounded),
            label: '아침',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view_rounded),
            label: '매트릭스',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_fire_department_outlined),
            selectedIcon: Icon(Icons.local_fire_department_rounded),
            label: '습관',
          ),
          NavigationDestination(
            icon: Icon(Icons.edit_note_outlined),
            selectedIcon: Icon(Icons.edit_note_rounded),
            label: '생각노트',
          ),
          NavigationDestination(
            icon: Icon(Icons.nights_stay_outlined),
            selectedIcon: Icon(Icons.nights_stay_rounded),
            label: '회고',
          ),
        ],
      ),
    );
  }

  // 원형 아이콘 버튼 (배경에 살짝 반투명한 원)
  Widget _circleIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final isTodayTab = _currentIndex == 0; // 오늘 탭은 헤더가 그라디언트라 버튼 배경 조정
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isTodayTab
            ? Colors.white.withValues(alpha: 0.25)
            : Colors.black.withValues(alpha: 0.05),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, color: isTodayTab ? Colors.white : null, size: 20),
        onPressed: onTap,
      ),
    );
  }

  // 성장 캐릭터용 원형 버튼 (아이콘 대신 이미지를 원 안에 표시)
  Widget _circleImageButton({
    required String imagePath,
    required VoidCallback onTap,
  }) {
    final isTodayTab = _currentIndex == 0;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isTodayTab
            ? Colors.white.withValues(alpha: 0.25)
            : Colors.black.withValues(alpha: 0.05),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: ClipOval(
          child: Image.asset(
            imagePath,
            width: 26,
            height: 26,
            fit: BoxFit.cover,
          ),
        ),
        onPressed: onTap,
      ),
    );
  }
}
