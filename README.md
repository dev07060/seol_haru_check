# seol_haru_check
# 설 하루 체크 (Seol Haru Check)

A new Flutter project.
> AI와 함께 매일의 건강을 기록하고, 매주 똑똑한 리포트를 받아보세요.

## Getting Started
"설 하루 체크"는 사용자의 운동 및 식단 기록을 AI가 분석하여 매주 개인화된 건강 리포트를 제공하는 Flutter 애플리케이션입니다. 단순한 기록을 넘어, 데이터 시각화와 추세 분석을 통해 사용자가 자신의 건강 상태를 직관적으로 이해하고 지속 가능한 건강 습관을 형성하도록 돕습니다.

This project is a starting point for a Flutter application.
## ✨ 주요 기능 (Key Features)

A few resources to get you started if this is your first Flutter project:
*   **🤖 AI 주간 리포트**: Google VertexAI (Gemini)를 활용하여 매주 사용자의 운동/식단 데이터를 심층 분석하고, 강점과 개선점을 포함한 맞춤형 리포트를 생성합니다.
*   **📊 인터랙티브 데이터 시각화**: `fl_chart`를 기반으로 구축된 자체 차트 모듈을 통해 활동 빈도, 카테고리 분포, 영양 균형 등 복잡한 데이터를 직관적인 차트로 시각화합니다.
*   **⚙️ 체계적인 상태 관리**: Riverpod를 활용하여 로딩, 생성, 에러, 타임아웃 등 상세한 UI 상태를 관리하여 사용자에게 안정적이고 부드러운 경험을 제공합니다.
*   **📈 과거 기록 조회 및 비교**: 과거 리포트를 손쉽게 조회하고, 주간 데이터 비교를 통해 자신의 성장 과정을 추적할 수 있습니다.
*   **✈️ 오프라인 지원**: 네트워크 연결이 없는 환경에서도 캐시된 데이터를 통해 앱의 핵심 기능을 사용할 수 있습니다.
*   **🔔 실시간 업데이트 및 알림**: Firebase를 통해 데이터 변경을 실시간으로 감지하고, 리포트가 생성되면 푸시 알림으로 알려줍니다.

- Lab: Write your first Flutter app
- Cookbook: Useful Flutter samples
## 🏗️ 아키텍처 (Architecture)

For help getting started with Flutter development, view the
online documentation, which offers tutorials,
samples, guidance on mobile development, and a full API reference.
이 프로젝트는 Flutter 프론트엔드와 Firebase 서버리스 백엔드로 구성된 확장 가능하고 유지보수가 용이한 아키텍처를 채택했습니다.

```mermaid
graph TD
    subgraph "Client (Flutter)"
        A[UI Layer: Pages & Widgets]
        B[State Management: Riverpod]
        C[Routing: GoRouter]
        D[Service Layer: Data Fetching & Caching]
        E[Models: Data Structures]
        
        A --> B
        B --> D
        D --> E
    end

    subgraph "Backend (Firebase Serverless)"
        F[Firebase Auth]
        G[Firestore Database]
        H[Cloud Functions]
        I[Cloud Scheduler]
        J[VertexAI (Gemini)]
        K[FCM]
    end

    A -- User Interaction --> B
    D -- API Calls --> G
    D -- API Calls --> H

    I -- Triggers (Weekly) --> H[AI Report Generation]
    H -- Fetches Data --> G
    H -- Sends Prompt --> J
    J -- Returns Analysis --> H
    H -- Saves Report --> G
    H -- Sends Notification --> K
    K -- Push Notification --> A

    F -- Manages Auth --> A
```

*   **Frontend (Flutter)**:
    *   **상태 관리**: `Riverpod` (`StateNotifierProvider`, `StreamProvider`)
    *   **라우팅**: `GoRouter`
    *   **UI**: `fl_chart` 기반의 커스텀 차트 시스템
    *   **구조**: 관심사 분리 원칙에 따른 체계적인 폴더 구조
*   **Backend (Firebase Serverless)**:
    *   **인증**: Firebase Authentication
    *   **데이터베이스**: Firestore
    *   **서버 로직**: Cloud Functions (TypeScript)
    *   **자동화**: Cloud Scheduler
    *   **AI**: Google VertexAI (Gemini Pro)
    *   **알림**: Firebase Cloud Messaging

## 🚀 기술적 강점 (Technical Highlights)

*   **견고한 상태 관리**: `isLoading`, `isGenerating`, `isProcessing`, `hasTimedOut` 등 세분화된 로딩 상태를 정의하고, `LoadingStateManager`를 통해 UI에 일관된 피드백을 제공합니다.
*   **지능형 캐싱 전략**: `OfflineManager`를 통한 영구 캐시와 `WeeklyReportService`의 인메모리 캐시를 결합한 이중 캐싱으로 온라인에서는 빠른 속도를, 오프라인에서는 끊김 없는 사용성을 보장합니다.
*   **모듈식 차트 시스템**: `BaseChartWidget`과 `ChartErrorHandler`를 통해 모든 차트의 공통 로직(테마, 애니메이션, 에러 핸들링)을 추상화하여 재사용성과 안정성을 높였습니다.
*   **관심사 분리 (SoC)**: UI(Page), 상태 로직(Provider), 비즈니스 로직(Service), 데이터 모델(Model)을 명확히 분리하여 코드의 가독성과 유지보수성을 극대화했습니다.
*   **체계적인 에러 핸들링**: `ErrorHandler`와 `AppException`을 통해 앱 전반의 예외를 중앙에서 관리하고, 사용자에게 명확한 피드백과 재시도 옵션을 제공합니다.

## 📂 프로젝트 구조 (Project Structure)

```
seol_haru_check/
├── lib/
│   ├── core/             # 에러 핸들링, 오프라인 관리 등 핵심 로직
│   ├── models/           # 데이터 모델
│   ├── pages/            # 화면(페이지) 위젯
│   ├── providers/        # Riverpod 상태 관리
│   ├── services/         # 외부 서비스 통신 (Firestore, AI 등)
│   ├── shared/           # 공통 상수, 색상, 폰트 등
│   └── widgets/          # 재사용 가능한 위젯
├── functions/            # (가상) Firebase Cloud Functions 소스 코드
└── .kiro/                # (가상) Kiro를 사용한 명세 문서
```

## 🏁 시작하기 (Getting Started)

### Prerequisites

*   Flutter SDK
*   Firebase CLI
*   Firebase 프로젝트 및 설정 (`google-services.json`, `GoogleService-Info.plist`)

### Installation & Run

1.  **Firebase 프로젝트 설정**:
    *   Firebase 프로젝트를 생성하고, `android/app/google-services.json` 및 `ios/Runner/GoogleService-Info.plist` 파일을 프로젝트에 추가합니다.
    *   Firestore, Firebase Authentication, Cloud Functions, Cloud Scheduler를 활성화합니다.

2.  **Flutter 종속성 설치**:
    ```bash
    flutter pub get
    ```

3.  **앱 실행**:
    ```bash
    flutter run
    ```

