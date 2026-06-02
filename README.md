# LMS Todo

한양대학교 Canvas LMS 과제를 자동으로 불러와 할 일 목록으로 관리하는 Flutter 앱입니다.
RPG 게임 요소(캐릭터, 전투, 장비)와 AI 자연어 입력, 집중 타이머 기능을 포함합니다.

---

## 주요 기능

- **LMS 연동** — Canvas API 토큰으로 미제출 과제·퀴즈를 자동 가져오기
- **할 일 관리** — 날짜별 할 일, 우선순위/난이도 설정, 인증 사진 등록으로 완료 처리
- **AI 자연어 입력** — Gemini API를 활용한 자연어 → 할 일 자동 파싱
- **RPG 시스템** — 캐릭터(전사/마법사/도적), 스탯, 장비, 몬스터 전투
- **캘린더 뷰** — 날짜별 완료율 시각화
- **집중 타이머** — 포모도로 타이머 + XP 획득

---

## 개발 환경 요구사항

| 항목 | 버전 |
|------|------|
| Flutter | 3.29.3 이상 |
| Dart | 3.7.2 이상 |
| Xcode | 15 이상 (iOS 빌드 시) |
| Android Studio | 최신 권장 (Android 빌드 시) |

Flutter 설치가 안 되어 있다면 → https://docs.flutter.dev/get-started/install

---

## 필요한 토큰 및 API 키

### 1. Gemini API Key (필수)
AI 자연어 입력 기능에 사용됩니다.

1. https://aistudio.google.com/app/apikey 접속
2. **Create API Key** 클릭 후 키 복사
3. 프로젝트 루트에 `.env` 파일 생성 후 아래 내용 입력

```
GEMINI_API_KEY=여기에_발급받은_키_입력
```

### 2. Canvas LMS 토큰 (선택 — LMS 연동 기능 사용 시)
한양대학교 LMS 과제 자동 가져오기에 사용됩니다. 앱 실행 후 설정에서 입력하므로 파일에 저장하지 않아도 됩니다.

발급 방법:
1. https://learning.hanyang.ac.kr 로그인
2. 우측 상단 계정 아이콘 → **설정(Settings)**
3. **Approved Integrations → New Access Token**
4. 생성된 토큰을 앱 내 LMS 연동 화면에서 입력

---

## 로컬 실행 방법

### 1. 저장소 클론

```bash
git clone <repository-url>
cd lms_todo
```

### 2. .env 파일 생성

프로젝트 루트(`pubspec.yaml`과 같은 위치)에 `.env` 파일을 직접 만들고 Gemini API 키를 입력합니다.

```
GEMINI_API_KEY=여기에_발급받은_키_입력
```

> `.env` 파일은 `.gitignore`에 등록되어 있어 git에 커밋되지 않습니다. **절대 GitHub에 올리지 마세요.**

### 3. 패키지 설치

```bash
flutter pub get
```

### 4. 앱 실행

```bash
# 연결된 기기/시뮬레이터에서 실행
flutter run

# 기기 목록 확인
flutter devices

# iOS 시뮬레이터 지정
flutter run -d ios

# macOS 앱으로 실행
flutter run -d macos
```

---

## 프로젝트 구조

```
lib/
├── core/
│   ├── models/          # Todo, Character, Category 모델
│   ├── providers/       # TodoProvider, CharacterProvider, TimerProvider
│   ├── services/        # LmsService, GeminiService, StorageService
│   └── theme/           # AppColors, appTheme
└── features/
    ├── todo/            # 할 일 목록, 캘린더, 상세, 타이머 화면
    ├── character/       # 캐릭터 화면, 캐릭터 생성, 스탯 다이얼로그
    ├── battle/          # 전투 화면
    └── lms/             # LMS 연동, 디버그 시트
```

---

## 데이터 저장

모든 데이터는 **기기 로컬(SharedPreferences)** 에만 저장됩니다. 서버/클라우드 연동 없음.

| 저장 키 | 내용 |
|---------|------|
| `todos_v1` | 할 일 목록 |
| `character_v1` | 캐릭터 데이터 |
| `lms_token` | Canvas API 토큰 |

---

## 주의사항

- `.env` 파일은 절대 커밋하지 마세요 (`.gitignore`에 등록되어 있음)
- Canvas API 토큰은 개인 정보이므로 타인과 공유하지 마세요
- Gemini API는 무료 티어(gemini-2.0-flash-lite) 기준으로 설정되어 있습니다
