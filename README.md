# Sahhti Back Office

A **Flutter Desktop** application for medical staff — physicians, clinic supervisors, and authorized administrators. It provides a secure, high-density clinical workspace for daily operations: patient access, medical records, appointments, messaging, and audit trails.

This repository is **Back Office only**. It does not include patient-facing interfaces.

---

## Table of contents

- [Overview](#overview)
- [Features](#features)
- [Screens](#screens)
- [Tech stack](#tech-stack)
- [Requirements](#requirements)
- [Getting started](#getting-started)
- [Demo flow](#demo-flow)
- [Project structure](#project-structure)
- [Architecture](#architecture)
- [Localization](#localization)
- [Development](#development)
- [Testing](#testing)
- [Building for production](#building-for-production)
- [Current status](#current-status)
- [Related documentation](#related-documentation)

---

## Overview

Sahhti Back Office is built as a **UI-first desktop client** with a strict security and clarity mindset:

- Fixed desktop layout (sidebar, top bar, main content, right context panel)
- Three-gate access flow: **Secure Login → Device Trust → Shell**
- Semantic medical colors (green / orange / red)
- French and Arabic support with RTL
- Mock data today; ready for a secure backend later without a full redesign

**Target platforms:** macOS and Windows  
**Minimum window size (macOS):** 1280 × 800

For the full product specification, see [`archtrecture.md`](archtrecture.md).

---

## Features

| Area | Capabilities |
|---|---|
| **Authentication** | Secure login, MFA/OTP fields, device trust gate, session indicators |
| **Dashboard** | KPI strip, critical alert stack, appointments table, activity feed |
| **Patients** | Search with filters, temporary session access (QR / PIN / reason / countdown) |
| **Medical record** | Overview, timeline, diagnoses, prescriptions, labs, imaging, vaccines, vitals |
| **Operations** | Appointments and clinical queue |
| **Communication** | Controlled medical messaging UI |
| **Administration** | Roles, permissions, devices, policies |
| **Audit & security** | Access logs and security alerts (read-only audit posture) |
| **UI states** | Loading, empty, no-permission, session expired, network degraded, read-only |

---

## Screens

The app defines **18 core routes** grouped by sidebar section:

| # | Route | Section |
|---|---|---|
| 1 | Secure Login | Security |
| 2 | Device Trust | Security |
| 3 | Dashboard | Operations |
| 4 | Patient Search | Patients |
| 5 | Patient Access | Patients |
| 6 | Medical Overview | Clinical |
| 7 | Timeline | Clinical |
| 8 | Diagnoses | Clinical |
| 9 | Prescriptions | Clinical |
| 10 | Labs | Clinical |
| 11 | Imaging & Files | Clinical |
| 12 | Vaccines | Clinical |
| 13 | Vitals | Clinical |
| 14 | Appointments | Operations |
| 15 | Queue | Operations |
| 16 | Medical Messaging | Communication |
| 17 | Administration | Administration |
| 18 | Audit Logs | Administration |

Routes are declared in `lib/app/router/app_route.dart` and mapped in `lib/app/router/app_router.dart`.

---

## Tech stack

| Layer | Choice |
|---|---|
| Framework | [Flutter](https://flutter.dev) 3.x (Desktop) |
| Language | Dart ^3.11.5 |
| UI | Material 3, custom design tokens |
| Localization | Custom `AppLocalizationScope` + `AppTextKey` (FR / AR) |
| Assets | SVG (`flutter_svg`), QR codes (`qr_flutter`) |
| Linting | `flutter_lints` ^6.0.0 |

---

## Requirements

- **Flutter SDK** with desktop support enabled  
  ```bash
  flutter doctor
  ```
- **macOS:** Xcode + CocoaPods (for macOS builds)
- **Windows:** Visual Studio 2022 with Desktop development with C++

Enable desktop if needed:

```bash
flutter config --enable-macos-desktop
flutter config --enable-windows-desktop
```

---

## Getting started

### 1. Clone and install dependencies

```bash
git clone <repository-url>
cd sahty_back_office
flutter pub get
```

### 2. Run on macOS

```bash
flutter run -d macos
```

### 3. Run on Windows

```bash
flutter run -d windows
```

### 4. Analyze the codebase

```bash
dart analyze lib test
```

---

## Demo flow

The app uses **mock authentication** for UI development. No real backend is connected yet.

1. **Startup splash** — brief branded animation, then login.
2. **Secure login** — pre-filled demo credentials:
   - Doctor ID: `dr.nichols@sahty.local`
   - Password: `Demo1234`
   - OTP: `123456`
3. Tap **login** → **Device Trust** screen (standalone, no shell).
4. Approve the device → **Dashboard** inside the full shell (sidebar + top bar + right panel).

Switch language from the locale control in the top bar (French ↔ Arabic, LTR ↔ RTL).

---

## Project structure

``` Old structure
lib/
├── main.dart                          # App entry point
├── app/
│   ├── sahhti_back_office_app.dart    # Root app, auth gates, IndexedStack navigation
│   ├── startup_splash_screen.dart
│   ├── router/
│   │   ├── app_route.dart             # Route enum + sidebar sections
│   │   └── app_router.dart            # Route → screen mapping
│   ├── shell/
│   │   └── back_office_shell.dart     # Sidebar, top bar, right context panel
│   └── implementation/
│       └── implementation_phase.dart  # Roadmap phases for placeholder screens
├── core/
│   ├── l10n/                          # Localization keys + FR/AR strings
│   ├── theme/                         # Colors, spacing, Material theme
│   └── widgets/                       # Shared UI (alerts, metrics, async states, …)
├── features/
│   ├── auth/                          # Login + device trust
│   ├── dashboard/
│   ├── patients/
│   ├── medical_record/
│   ├── operations/
│   ├── communication/
│   ├── administration/
│   └── shared/
└── shared/
    └── mock_data/                     # Centralized mock datasets

assets/
├── images/                            # SVG illustrations and branding
└── data_images/                       # Imaging mock assets

test/
└── widget_test.dart                   # Login → device trust → dashboard flow

``` Updated structure
lib/
├── main.dart
│
├── app/
│   ├── sahhti_back_office_app.dart    ← Root app + gates auth
│   ├── startup_splash_screen.dart
│   ├── router/
│   │   ├── app_route.dart             ← Enum routes + sections sidebar
│   │   └── app_router.dart            ← Route → Screen mapping
│   └── shell/
│       └── back_office_shell.dart     ← Layout: Sidebar + TopBar + Content
│
├── core/
│   ├── api/
│   │   ├── api_client.dart            ← Client HTTP centralisé (invoke functions)
│   │   ├── api_endpoints.dart         ← Toutes les URLs des Edge Functions
│   │   └── api_error.dart             ← Gestion erreurs API
│   ├── l10n/
│   │   ├── app_text_key.dart          ← Enum toutes les clés de traduction
│   │   └── app_localizations.dart     ← Strings FR + AR
│   ├── services/
│   │   ├── session_service.dart       ← JWT + rôle + patient_session actuel
│   │   └── notification_service.dart  ← FCM token registration
│   ├── theme/
│   │   ├── app_colors.dart            ← Couleurs médicales sémantiques
│   │   ├── app_spacing.dart           ← Espacements + dimensions sidebar
│   │   └── app_theme.dart             ← ThemeData Material 3
│   └── widgets/
│       ├── async_state_widget.dart    ← Loading/Error/Empty/NoPermission
│       ├── section_card.dart          ← Card standard contenu
│       ├── metric_card.dart           ← KPI card (chiffre + label + trend)
│       ├── alert_stack.dart           ← Stack d'alertes médicales
│       └── confirmation_dialog.dart   ← Dialog confirmation actions sensibles
│
├── features/
│   │
│   ├── auth/
│   │   ├── data/
│   │   │   └── auth_datasource.dart      ← login email/password → JWT
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   ├── auth_bloc.dart
│   │       │   ├── auth_event.dart
│   │       │   └── auth_state.dart
│   │       └── screens/
│   │           ├── login_screen.dart     ← Email + Password + OTP
│   │           └── device_trust_screen.dart ← Vérification appareil
│   │
│   ├── dashboard/
│   │   ├── data/
│   │   │   └── dashboard_datasource.dart ← admin-get-stats
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   ├── dashboard_bloc.dart
│   │       │   ├── dashboard_event.dart
│   │       │   └── dashboard_state.dart
│   │       └── screens/
│   │           └── dashboard_screen.dart ← KPIs + alertes + RDV + activité
│   │
│   ├── patients/
│   │   ├── data/
│   │   │   └── patient_search_datasource.dart ← get-doctors-public (admin liste patients)
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   ├── patient_search_bloc.dart
│   │       │   ├── patient_search_event.dart
│   │       │   └── patient_search_state.dart
│   │       └── screens/
│   │           ├── patient_search_screen.dart  ← Recherche NNI/nom + filtres
│   │           └── patient_access_screen.dart  ← QR Scan + PIN + session countdown
│   │
│   ├── scanner/
│   │   ├── data/
│   │   │   └── scanner_datasource.dart   ← doctor-verify-patient-access
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   ├── scanner_bloc.dart
│   │       │   ├── scanner_event.dart
│   │       │   └── scanner_state.dart
│   │       └── widgets/
│   │           ├── qr_camera_widget.dart  ← Flux caméra + détection QR
│   │           └── pin_input_widget.dart  ← 4 cases PIN avec auto-focus
│   │
│   ├── medical_record/
│   │   ├── data/
│   │   │   └── dossier_datasource.dart   ← doctor-get-patient-dossier
│   │   │                                    doctor-add-medical-record
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   ├── dossier_bloc.dart
│   │       │   ├── dossier_event.dart
│   │       │   └── dossier_state.dart
│   │       └── screens/
│   │           ├── medical_overview_screen.dart  ← Vue générale consultation
│   │           ├── timeline_screen.dart          ← Historique chronologique
│   │           ├── allergies_screen.dart         ← Allergies + sévérité
│   │           ├── prescriptions_screen.dart     ← Ordonnances + ajout
│   │           ├── labs_screen.dart              ← Analyses
│   │           ├── imaging_screen.dart           ← Imagerie + fichiers
│   │           ├── vaccines_screen.dart          ← Carnet vaccination
│   │           └── vitals_screen.dart            ← Graphiques fl_chart
│   │
│   ├── operations/
│   │   ├── data/
│   │   │   └── agenda_datasource.dart    ← doctor-get-agenda
│   │   │                                    doctor-update-appointment
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   ├── agenda_bloc.dart
│   │       │   ├── agenda_event.dart
│   │       │   └── agenda_state.dart
│   │       └── screens/
│   │           ├── appointments_screen.dart ← Calendrier semaine/mois
│   │           └── queue_screen.dart        ← File d'attente du jour
│   │
│   ├── communication/
│   │   ├── data/
│   │   │   └── messaging_datasource.dart ← doctor-get-conversations (futur)
│   │   │                                    doctor-send-message (futur)
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   ├── messaging_bloc.dart
│   │       │   ├── messaging_event.dart
│   │       │   └── messaging_state.dart
│   │       └── screens/
│   │           └── messaging_screen.dart   ← Layout 3 colonnes: liste/chat/info
│   │
│   ├── administration/
│   │   ├── data/
│   │   │   └── admin_datasource.dart     ← admin-create-user
│   │   │                                    admin-get-stats
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   ├── admin_bloc.dart
│   │       │   ├── admin_event.dart
│   │       │   └── admin_state.dart
│   │       └── screens/
│   │           ├── administration_screen.dart ← Gestion rôles + utilisateurs
│   │           └── audit_logs_screen.dart     ← Journal accès dossiers
│   │
│   └── pharmacien/
│       ├── data/
│       │   └── pharmacien_datasource.dart ← pharmacist-get-prescription
│       │                                     pharmacist-dispense (futur)
│       └── presentation/
│           ├── bloc/
│           │   ├── pharmacien_bloc.dart
│           │   ├── pharmacien_event.dart
│           │   └── pharmacien_state.dart
│           └── screens/
│               ├── scanner_ordonnance_screen.dart ← QR ordonnance
│               └── dispensations_screen.dart      ← Historique dispensations
│
└── shared/
    └── mock_data/                         ← Données mockées (dev uniquement)
        ├── mock_patients.dart
        ├── mock_appointments.dart
        └── mock_vitals.dart
test/
├── unit/
│   ├── auth_bloc_test.dart
│   ├── scanner_bloc_test.dart
│   ├── dossier_bloc_test.dart
│   └── agenda_bloc_test.dart
└── widget/
    └── login_to_dashboard_test.dart       ← Flux Login → DeviceTrust → Shell
---

## Architecture

### Access gates

```
Startup Splash
      ↓
Secure Login  (no shell)
      ↓
Device Trust  (no shell)
      ↓
Back Office Shell  (sidebar + IndexedStack of all operational screens)
```

### Shell layout

```
┌──────────┬──────────────────────────────────────┬─────────────┐
│ Sidebar  │  Top Bar (search, alerts, session)   │             │
│ (nav)    ├──────────────────────────────────────┤  Right      │
│          │                                      │  Context    │
│          │  Main Content (selected screen)      │  Panel      │
│          │                                      │             │
└──────────┴──────────────────────────────────────┴─────────────┘
```

### Navigation performance

- `ValueNotifier<AppRoute>` — route changes rebuild only the shell scope, not the entire `MaterialApp`
- `IndexedStack` — screens stay alive; switching routes is instant
- Sidebar hover animation uses precomputed sections and `RepaintBoundary` isolation

### Design tokens

| Token file | Purpose |
|---|---|
| `app_colors.dart` | Brand, semantic medical colors, surfaces |
| `app_spacing.dart` | Spacing scale, sidebar dimensions |
| `app_theme.dart` | Typography, inputs, buttons, cards |

---

## Localization

| Locale | Code | Direction |
|---|---|---|
| French (default) | `fr` | LTR |
| Arabic | `ar` | RTL |

- Keys: `lib/core/l10n/app_text_key.dart`
- Strings: `lib/core/l10n/app_localizations.dart`
- Usage in widgets: `context.tr(AppTextKey.someKey)`

`tr()` falls back to French, then to the key name if a translation is missing.

---

## Development

### Code conventions

- **All code comments must be in English.**
- Follow existing patterns: `SectionCard`, `MetricCard`, `AlertStack`, `AsyncStateWidget`
- Prefer the shared theme tokens over hardcoded colors and spacing
- Keep mock data in `lib/shared/mock_data/` or feature-local mock classes

### Adding a new screen

1. Add an `AppRoute` entry in `app_route.dart`
2. Create the screen under `lib/features/<domain>/`
3. Register it in `AppRouter.buildScreen()` in `app_router.dart`
4. Add `AppTextKey` entries and FR/AR strings in `app_localizations.dart`

### Key dependencies

```yaml
dependencies:
  flutter_localizations: sdk
  cupertino_icons: ^1.0.8
  flutter_svg: ^2.2.4
  qr_flutter: ^4.1.0
```

---

## Testing

Run widget tests:

```bash
flutter test
```

The main test covers the three-screen flow: **Login → Device Trust → Dashboard** at desktop size (1600 × 1000).

> **Note:** Tests expect French UI strings by default. If login button labels change, update `test/widget_test.dart` accordingly.

---

## Building for production

### macOS (release)

```bash
flutter build macos --release
```

Output:

```
build/macos/Build/Products/Release/sahty_back_office.app
```

### macOS DMG installer (optional)

Requires [create-dmg](https://github.com/create-dmg/create-dmg):

```bash
create-dmg \
  --volname "app-install" \
  --window-pos 200 120 \
  --window-size 600 400 \
  --icon-size 100 \
  --icon "sahty_back_office.app" 150 175 \
  --app-drop-link 450 175 \
  --hide-extension "sahty_back_office.app.app" \
  "build/macos/Build/Products/Release/sahty_back_office.app-Installer.dmg" \
  "build/macos/Build/Products/Release/sahty_back_office.app.app"
```

### Windows (release)

```bash
flutter build windows --release
```

Output:

```
build/windows/x64/runner/Release/
```

---

## Current status

| Item | Status |
|---|---|
| UI shell & design system | Implemented |
| 18 screen routes | Implemented (mix of full screens + placeholders) |
| Auth / device trust flow | UI mock only |
| Backend API integration | Not started |
| Real MFA / biometrics | Not integrated (`local_auth` pending) |
| Persistent sessions | Not implemented |
| Dependency injection | Not implemented |

This is intentional: the UI architecture is locked first so a secure backend can be wired in later without a full redesign.

---

## Related documentation

| File | Description |
|---|---|
| [`archtrecture.md`](archtrecture.md) | Full Back Office UI specification (screens, security rules, implementation order) |

---

## Security notice

This repository contains **demo credentials and mock medical data** for development only. Do not use in production without:

- A real authentication and MFA backend
- Device trust and session management APIs
- Encrypted transport and audit logging
- Role-based access control enforced server-side

Sensitive actions (export, print, delete) should always require explicit confirmation — several screens already follow this pattern in the UI.

---

## License

Private / unpublished (`publish_to: 'none'` in `pubspec.yaml`). Contact the project owner for usage terms.
