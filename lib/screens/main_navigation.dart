// ============================================================
// MainNavigation (하단 탭 네비게이션)
// ------------------------------------------------------------
// 앱의 4가지 주요 화면(오늘/매트릭스/노트/회고)을 하단 탭으로
// 전환할 수 있게 해주는 뼈대 화면입니다.
// 오른쪽 위에는 검색과 다크모드 전환 버튼을 둡니다.
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
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(index: _currentIndex, children: _screens),
          // 검색 / 다크모드 버튼을 오른쪽 위에 겹쳐서 표시
          Positioned(
            top: 8,
            right: 8,
            child: SafeArea(
              child: Row(
                children: [
                  _circleIconButton(
                    icon: Icons.search_rounded,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SearchScreen()),
                    ),
                  ),
                 const SizedBox(width: 6),
                  _circleIconButton(
                    icon: Icons.folder_outlined,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ProjectListScreen(),
                      ),
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

  // 검색/다크모드용 원형 아이콘 버튼 (배경에 살짝 반투명한 원)
  Widget _circleIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final isTodayTab = _currentIndex == 0; // 오늘 화면은 헤더가 그라디언트라 버튼 배경을 조정
    return Container(
      decoration: BoxDecoration(
        color: isTodayTab
            ? Colors.white.withValues(alpha: 0.25)
            : Colors.black.withValues(alpha: 0.05),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: isTodayTab ? Colors.white : null, size: 20),
        onPressed: onTap,
      ),
    );
  }
}
