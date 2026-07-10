# 📱 Priority Planner — 프로젝트 가이드

이케다 지에 「매일 아침 1시간이 나를 바꾼다」 방법론 기반 업무 계획관리 앱입니다.
이 문서는 5분 안에 프로젝트 전체를 이해할 수 있도록 만든 지도입니다.

---

## 1. 폴더/파일 구조

```
flutter_app/
├── lib/
│   ├── main.dart                     # 앱 시작점. Hive 초기화, Provider 연결, 첫 화면 실행
│   │
│   ├── models/                       # 데이터 구조 정의
│   │   ├── task.dart                 # 할 일/일정 모델 (Task)
│   │   ├── task.g.dart               # ↑의 Hive 저장용 자동 생성 코드 (직접 수정 금지)
│   │   ├── note.dart                 # 생각 노트 모델 (Note) + 상태(NoteStatus)
│   │   ├── note.g.dart               # ↑의 자동 생성 코드
│   │   ├── reflection.dart           # 저녁 회고 모델 (Reflection)
│   │   └── reflection.g.dart         # ↑의 자동 생성 코드
│   │
│   ├── services/                     # 데이터 저장/상태관리 로직
│   │   ├── storage_service.dart      # Hive 데이터베이스 초기화 및 CRUD(저장/조회/삭제) 함수
│   │   └── app_state.dart            # 앱 전체 상태 관리 (Provider). 화면들이 여기를 통해 데이터에 접근
│   │
│   ├── theme/
│   │   └── app_theme.dart            # 앱 색상, 라이트/다크 테마 정의 (코랄+틸 컬러 팔레트)
│   │
│   ├── widgets/                      # 여러 화면에서 재사용하는 UI 조각
│   │   └── task_tile.dart            # 할 일 한 줄을 보여주는 위젯 (체크박스+시간+제목+별)
│   │
│   └── screens/                      # 실제 화면들
│       ├── main_navigation.dart      # 하단 탭 네비게이션(오늘/매트릭스/노트/회고) + 검색·다크모드 버튼
│       ├── today_screen.dart         # 오늘 화면(홈): 날짜 이동, 오늘의 3가지, 시간순 일정
│       ├── task_edit_screen.dart     # 할 일 추가/수정 화면
│       ├── matrix_screen.dart        # 우선순위 매트릭스(2x2) 화면
│       ├── notes_screen.dart         # 생각 노트(브레인덤프) 화면
│       ├── reflection_screen.dart    # 저녁 회고 화면
│       └── search_screen.dart        # 검색 화면 (할 일 + 노트 통합 검색)
│
├── assets/
│   └── icons/app_icon.png            # 앱 아이콘 원본 이미지
│
├── pubspec.yaml                      # 패키지 의존성 목록 및 프로젝트 설정
└── PROJECT_GUIDE.md                  # 이 문서
```

---

## 2. 데이터 구조 상세

### 2-1. Task (할 일 / 일정) — `lib/models/task.dart`

| 필드 | 타입 | 설명 |
|---|---|---|
| id | String | 고유 식별자 |
| title | String | 제목 (필수) |
| memo | String? | 상세 메모 (선택) |
| startTime | DateTime? | 시작 시간. 있으면 "시간순 일정", 없으면 "시간 미정" |
| date | DateTime | 이 할 일이 속한 날짜 (날짜 이동의 기준) |
| isImportant | bool | 중요도 (true=높음) |
| isUrgent | bool | 긴급도 (true=높음) |
| isTop3 | bool | "오늘 집중할 3가지"에 포함 여부 |
| isDone | bool | 완료 여부 |
| createdAt | DateTime | 생성 시각 (자동 기록) |
| carriedOverFromId | String? | 미완료 이월로 생성된 경우, 원본 할 일의 id |

`quadrant` getter: isImportant/isUrgent 조합으로 0~3 사분면 번호를 계산합니다.
(0=긴급&중요, 1=중요만, 2=긴급만, 3=둘다낮음)

### 2-2. Note (생각 노트) — `lib/models/note.dart`

| 필드 | 타입 | 설명 |
|---|---|---|
| id | String | 고유 식별자 |
| content | String | 노트 내용(텍스트) |
| status | NoteStatus | unclassified(미분류) / archived(보관) / converted(전환됨) |
| createdAt | DateTime | 생성 시각 |
| penImagePath | String? | **[3단계용 예약 필드]** 펜 그림 이미지 경로. 현재는 항상 null |
| convertedText | String? | **[3단계용 예약 필드]** 손글씨 인식 텍스트. 현재는 항상 null |
| convertedTaskId | String? | 할 일로 전환됐다면, 생성된 Task의 id |

### 2-3. Reflection (저녁 회고) — `lib/models/reflection.dart`

| 필드 | 타입 | 설명 |
|---|---|---|
| id | String | 고유 식별자 |
| date | DateTime | 회고 대상 날짜 (하루에 1개) |
| memo | String? | 하루 소감 |
| updatedAt | DateTime | 마지막 수정 시각 |

---

## 3. 데이터 저장 방식

- **Hive** (로컬 문서형 데이터베이스)를 사용해 기기 안에 저장합니다. (`lib/services/storage_service.dart`)
- 앱 실행 시 `main.dart`에서 `StorageService.init()`을 호출해 3개의 Box(테이블)를 엽니다: `tasks`, `notes`, `reflections`.
- 다크모드 여부처럼 단순한 값은 `shared_preferences`로 별도 저장합니다. (`lib/services/app_state.dart`)
- 인터넷 연결이 필요 없으며, 앱을 지우기 전까지 기기에 데이터가 유지됩니다.
- **주의**: `*.g.dart` 파일은 `build_runner`가 자동으로 만든 코드이므로 직접 수정하지 마세요.
  모델(`task.dart`, `note.dart`, `reflection.dart`)을 수정한 뒤에는 아래 명령으로 다시 생성해야 합니다.
  ```
  dart run build_runner build --delete-conflicting-outputs
  ```

---

## 4. 화면별 기능 설명

| 화면 | 파일 | 기능 |
|---|---|---|
| 오늘(홈) | today_screen.dart | 날짜를 앞뒤로 넘기며 그 날의 일정을 확인. 시간이 있는 일은 시간순, 없는 일은 "시간 미정" 묶음. 상단에 "오늘 집중할 3가지" 강조 카드. +버튼으로 할 일 추가 |
| 할 일 추가/수정 | task_edit_screen.dart | 제목, 메모, 날짜, 시작 시간, 중요도/긴급도 입력. 수정 모드에서는 삭제도 가능 |
| 우선순위 매트릭스 | matrix_screen.dart | 완료되지 않은 모든 할 일을 중요도×긴급도 2x2 칸에 나눠서 표시 |
| 생각 노트 | notes_screen.dart | 빈 종이 방식 입력창에 자유롭게 작성 → 카드로 쌓임 → 할 일로 전환/보관/삭제 |
| 저녁 회고 | reflection_screen.dart | 선택한 날짜의 "오늘의 3가지" 달성 현황 확인 + 하루 소감 메모 저장 |
| 검색 | search_screen.dart | 할 일 제목/메모, 노트 내용을 함께 검색 |

하단 탭(`main_navigation.dart`)에서 오늘/매트릭스/생각노트/회고 4개 화면을 전환하고,
오른쪽 위 아이콘으로 검색 화면 진입 및 다크모드 전환이 가능합니다.

**미완료 이월**: 앱을 실행할 때마다(`main.dart` → `AppState.initializeAndCarryOverTasks()`),
오늘보다 이전 날짜의 미완료 할 일을 찾아 오늘 날짜로 복사본을 자동 생성합니다.
원본 할 일은 그대로 과거 기록으로 남습니다.

---

## 5. 현재 구현 범위(1단계)와 다음 계획

### ✅ 1단계 (현재 구현 완료)
- 할 일·일정 관리 (시간순 표시, 날짜 이동)
- 중요도·긴급도 2x2 우선순위 매트릭스
- 오늘 집중할 3가지 선정
- 생각 노트 (빈 종이 방식, 할 일로 전환)
- 저녁 회고
- 미완료 이월
- 검색
- 다크모드
- 로컬 저장 (Hive)
- Note 데이터에 펜 그림/변환 텍스트 자리 예약 (값은 비어있음)

### 🔜 2단계 (다음에 추가할 예정)
아침 1시간 루틴 타이머, 자기투자 기록, 실천 연속일수·통계, 월간 캘린더 뷰, 반복 태스크, 프로젝트/고객별 분류, 엑셀·PDF 내보내기.

### 🔜 3단계 (코드 바깥이 얽혀 분리 — 계정/설정 결정 필요)
알림(아침 일정·마감 알림), 펜 캔버스(그림 저장), 손글씨→텍스트 변환(ML Kit Digital Ink, 한국어).

### 🔜 최종 단계 (코드 바깥이 얽혀 분리)
로그인·클라우드 동기화, 팀 공유·관리자 대시보드.

---

## 6. 앱 실행 방법

```bash
# 1) 프로젝트 폴더로 이동
cd flutter_app

# 2) 패키지 설치
flutter pub get

# 3) (모델을 수정했을 때만) Hive 자동 코드 재생성
dart run build_runner build --delete-conflicting-outputs

# 4) 앱 실행 (연결된 기기/에뮬레이터에서)
flutter run

# 5) 웹 미리보기로 빠르게 확인하고 싶다면
flutter build web --release
python3 -m http.server 5060 --directory build/web --bind 0.0.0.0
```

---

## 7. 사용한 주요 패키지 (pubspec.yaml)

| 패키지 | 용도 |
|---|---|
| provider | 앱 전체 상태 관리 |
| hive, hive_flutter | 로컬 데이터베이스 (Task, Note, Reflection 저장) |
| shared_preferences | 간단한 설정값 저장 (다크모드 여부) |
| intl | 날짜 형식 표시 (한국어) |
| uuid | 고유 ID 생성 |
| hive_generator, build_runner | Hive 모델의 저장용 코드 자동 생성 (dev용) |
