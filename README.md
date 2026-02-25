# 🗣️ Speakera

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web%20%7C%20Desktop-lightgrey?style=for-the-badge)

**Speakera** is a cross-platform Flutter application designed to manage and monitor English language learning assessments. It features a robust role-based architecture, offering tailored dashboards for both administrators and students to track performance, visualize test results, and identify at-risk learners.

---

## ✨ Key Features

### 🔐 Authentication
* **Role-Based Access Control (RBAC):** Secure login routing for Admin and Student profiles.
* **Refined UI:** Animated fade-in transitions and password visibility toggles for better UX.

### 👨‍💻 Admin Dashboard
* **Analytics Overview:** KPI stat cards tracking total students, average scores, active tests, and high-risk learners.
* **Student Management:** Search by name/email, filter by risk level (Low / Medium / High), and dynamic risk badges.
* **Test Tracking:** Monitor Placement, Progress, and Mock tests with status filters (Active / Draft / Archived).
* **Granular Results:** Expandable result cards featuring per-skill score breakdowns and interactive bar charts.
* **Theming:** Seamless Light/Dark mode integration.

### 🎓 Student Dashboard
* **Personalized Overview:** Welcome screen displaying the average score and the strongest skill highlight.
* **Performance Visualizations:** Interactive bar charts breaking down skills (Listening, Reading, Writing, Speaking, Grammar).
* **Test History:** Comprehensive log of past tests with expandable, detailed result cards.

---

## 🛠️ Tech Stack

| Component | Technology / Package |
| :--- | :--- |
| **Framework** | Flutter (Dart SDK `>=3.11.0`) |
| **Data Visualization** | [`fl_chart ^0.68.0`](https://pub.dev/packages/fl_chart) |
| **Icons** | `cupertino_icons ^1.0.8` |
| **Code Quality** | `flutter_lints ^6.0.0` |

---

## 📂 Project Architecture

The application follows a modular directory structure for scalability and maintainability:

```text
lib/
├── data/
│   └── mock_data.dart         # Mock data for students, tests, and results
├── models/
│   └── models.dart            # Core entities (UserRole, Student, Test, TestResult)
├── screens/
│   ├── login_screen.dart      # Authentication UI
│   ├── admin_dashboard.dart   # Administrator interface
│   └── student_dashboard.dart # Learner interface
├── widgets/
│   ├── filter_chips.dart      # Reusable filter chip components
│   ├── kpi_chart.dart         # Wrapper for fl_chart bar charts
│   ├── risk_badge.dart        # Color-coded risk level indicators
│   └── stat_card.dart         # KPI summary components
└── main.dart                  # Application entry point, routing, and theme setup
```

---

## 🚀 Getting Started

Follow these steps to set up the project locally.

### Prerequisites
* [Flutter SDK](https://docs.flutter.dev/get-started/install) (Version 3.x or higher)
* Dart SDK `^3.11.0`

### 1. Clone the repository
```bash
git clone https://github.com/rxritet/Speakera.git
cd Speakera
```

### 2. Install dependencies
```bash
flutter pub get
```

### 3. Run the application
Start the app on your connected device or emulator:
```bash
flutter run
```

---

## 📦 Build & Deployment

Speakera is configured for multi-platform support (Android, iOS, Web, Windows, macOS, Linux). 

To build a production-ready Web release:
```bash
flutter build web
```

To build an APK for Android:
```bash
flutter build apk --release
```

---

## 📸 Screenshots
*(Coming soon — consider adding UI screenshots here to showcase the dashboards)*
