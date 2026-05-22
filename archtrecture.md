Sahhti — Back Office UI Specification

Back Office UI specification document for medical staff

Practical implementation guide for building Flutter Desktop on macOS and Windows

 

Scope

Back Office only: physicians, medical administration, security, and clinical workflows

Objective

Lock in the UI architecture before building the backend, with strict commitment to security and clarity

Platform

Flutter Desktop

Usage

Daily operational screens for physicians, supervisors, and authorized users only

 

This document does not cover patient-facing interfaces. Everything below is dedicated to the Back Office only, especially physician and medical administration interfaces.

 

1) Back Office design principles

The interface here is not decorative; it is a high-density medical work UI. The physician needs to see status, make decisions, and navigate quickly between records without distraction.

• Reduce the number of clicks on critical paths.
• Show medical warnings before any secondary content.
• Use a consistent structure across all screens so the physician does not feel like they are learning a new system on every page.
• Avoid decorative elements that consume attention.
• Adopt strict semantic colors: green for normal status, orange for warning, red for critical status.

2) Overall UI structure in Flutter Desktop

The interface must not be built with a mobile-first mindset. Desktop requires a fixed layout readable at higher information density.

• Fixed Sidebar on the left or right depending on display language direction.
• Top Bar containing quick search, alerts, session status, and user name.
• Main Content Area for primary content.
• Right Context Panel for critical patient data or supporting details.
• Professional tables instead of long lists where appropriate.

3) Main module structure

| Module | Purpose | Design notes |
|---|---|---|
| Authentication & Security | Login, MFA, trusted devices, sessions | Strictest screens, least clutter |
| Dashboard | Daily summary and clinic operations | Must be readable in two seconds |
| Patient Access | Open a temporary patient session | Linked to QR / PIN / access reason |
| Medical Record | Medical file, diagnoses, prescriptions, labs | Based on a clear information hierarchy |
| Appointments & Queue | Appointments and waiting list | Important for daily workflow |
| Messaging | Controlled medical messaging | Encrypted and archived |
| Administration | Permissions, devices, users | Restricted to a limited set of roles |
| Audit & Security | Logs, alerts, investigation | No deletion, no silent modification |

4) Required Back Office screens

The recommended starting count for a professional baseline is 18 core screens, with room to expand later. Each screen must serve one clear function.

| # | Screen | Core content |
|---|---|---|
| 1 | Secure login | Doctor ID, password, MFA, device status, login button, trust alert |
| 2 | Device trust verification | Device approval request, system info, admin approval, trust status |
| 3 | Dashboard | Today's appointments, patient count, critical alerts, messages, daily activity |
| 4 | Patient search | Search by name, NNI, or record number; filters; instant results |
| 5 | Open patient session | QR / PIN / access reason / session duration / physician name |
| 6 | Comprehensive medical record | Basic data, allergies, diagnoses, medications, vitals, last visit |
| 7 | Timeline | Medical events in chronological order with filtering by type |
| 8 | Diagnoses | Current and past status, severity, notes, dates |
| 9 | Prescriptions | Medications, doses, interaction warnings, allergy alerts, prescription status |
| 10 | Labs | Results, reference values, alert colors, comparison with prior history |
| 11 | Imaging & files | View, zoom, compare, secure download, exam metadata |
| 12 | Vaccines | Doses, completed, missing, alerts, upcoming appointments |
| 13 | Vitals | Weight, blood pressure, glucose, temperature, pulse, oxygen, charts |
| 14 | Appointments | Appointment list, day/week/month views, confirmation and cancellation states |
| 15 | Queue | Patient order, priority, wait time, critical statuses |
| 16 | Medical messaging | Physician conversations with patient or team, attachments, archiving |
| 17 | Administration & permissions | Roles, restrictions, approvals, devices, policies |
| 18 | Access logs & alerts | Who opened what, when, from which device, and security errors |

5) Screen details

5.1 Secure login screen

• Username or Doctor ID.
• Password.
• Biometric Login button when available.
• MFA or OTP.
• Alert when the device is rejected.
• Account recovery link shown only with appropriate permission.

5.2 Device trust verification screen

• Device name, operating system, version, last login.
• Device status: trusted / pending approval / rejected.
• Re-request trust button.
• Brief log of rejection reason or review requirement.

5.3 Dashboard

• Summary cards: patient count, queues, appointments, messages, alerts.
• Critical alerts area at the top of the page.
• Session status indicator and physician name in the top bar.
• Activity Feed showing the latest operations.

5.4 Patient search

• Quick search by name, NNI, or record number.
• Advanced filters: age, sex, status, last visit, treating physician.
• Concise search result showing more than one key field without opening the record.
• Prevent opening many records without reason in the same context.

5.5 Temporary patient session

• Display QR / Session ID.
• PIN verification.
• Access reason: consultation / emergency / follow-up.
• Session validity duration and countdown.
• End session immediately button.

5.6 Comprehensive medical record

• Brief identifying data at the top.
• Allergies in a permanently visible warning strip.
• Active diagnoses, current medications, vitals, vaccines.
• Collapsible detail areas instead of many separate pages.

5.7 Timeline

• Temporal navigation by year / month / event type.
• Events highlighted by color according to type.
• Quick links to open a lab result, prescription, or diagnosis from the same record.

5.8 Prescriptions

• Medication name, dose, frequency, duration, status.
• Drug interaction and allergy warnings.
• Status: active / stopped / completed.
• Print or PDF generation button according to permission.

5.9 Labs

• Result, normal values, out-of-range values.
• Comparison with the most recent prior test.
• Clear severity markers that do not require long reading.

5.10 Imaging

• Exam thumbnails.
• Full-screen view.
• Comparison between two exams.
• Download conditioned on security policy.

5.11 Appointments and queue

• Daily, weekly, and monthly views.
• Appointment status: confirmed, rescheduled, cancelled, overdue.
• Queue ordering by clinical priority.

5.12 Medical messaging

• Individual and group conversations by role.
• Secure attachments.
• Read and pin status.
• Archiving according to legal policy.

5.13 Administration and permissions

• Role and fine-grained permission management.
• Trusted device assignment.
• Control over visibility and edit boundaries.

5.14 Logs and alerts

• Complete Audit Log with no silent modification.
• Suspicious behavior alerts.
• Login attempt and failure log.

6) Security rules within the UI itself

• Do not display the full NNI unless necessary; part of it may be masked in public views.
• Do not show sensitive records before verification is complete.
• Do not make actions such as delete and export a single step; they require explicit confirmation.
• Do not merge roles into one screen when their permissions differ fundamentally.
• Do not expose Session or Tokens in the UI.
• Do not rely on color alone for alerts; always add clear text.

7) Professional design rules

• Use a fixed Sidebar and a clear section system.
• Make fonts large enough for fast reading.
• Reduce heavy shadows and glass effects.
• Prefer simple cards and clear data tables.
• Place medical warnings at the top of the visual hierarchy.
• Use consistent spacing that does not change from screen to screen.

8) UI states that must be supported

• Loading state.
• Empty state.
• No permission state.
• Session expired state.
• Device not trusted state.
• Network degraded state.
• Critical alert state.
• Read-only state.

9) Correct implementation order

• Build the Design System.
• Build the Shell Layout.
• Build Authentication & Device Trust.
• Build the Dashboard.
• Build Patient Search and Patient Access.
• Build Patient Overview and Timeline.
• Build Prescriptions, Labs, and Imaging.
• Build Appointments and Queue.
• Build Messaging and Audit & Security.

10) Deliverables of this UI version

When this document is followed, you get a Back Office interface that looks like a real institutional medical system, not just a dashboard. It will later be ready to receive a strong secure backend without a full redesign.

Implementation note: This document is based on the idea that appeared in the previous wireframe file, but it now focuses exclusively on the Back Office and turns that idea into a structured, strict build plan for Flutter Desktop.


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
