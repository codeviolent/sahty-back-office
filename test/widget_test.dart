import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sahty_back_office/app/sahhti_back_office_app.dart';

void main() {
  Future<void> pumpDesktopApp(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1600, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const SahhtiBackOfficeApp());
    await tester.pump(const Duration(seconds: 5));
    await tester.pump();
  }

  testWidgets('Login screen is clean and standalone before shell', (
    WidgetTester tester,
  ) async {
    await pumpDesktopApp(tester);

    // Login screen renders with expected content
    expect(find.text('SAHTY BACK OFFICE'), findsOneWidget);
    expect(find.text('Entrer dans le back office'), findsOneWidget);

    // No Shell or Sidebar at this stage
    expect(find.text('Rechercher: nom, NNI, dossier ou session'), findsNothing);
    expect(find.byTooltip('Tableau de bord'), findsNothing);
  });

  testWidgets('Strict three-screen flow: Login → Device Trust → Dashboard', (
    WidgetTester tester,
  ) async {
    await pumpDesktopApp(tester);

    // Phase 1: login
    expect(find.text('SAHTY BACK OFFICE'), findsOneWidget);
    await tester.tap(find.text('Entrer dans le back office'));
    await tester.pump();

    // Phase 2: device trust — standalone screen without Shell or Sidebar
    expect(find.text('Vérification de l\u2019appareil'), findsOneWidget);
    expect(find.text('Rechercher: nom, NNI, dossier ou session'), findsNothing);
    expect(find.byIcon(Icons.local_hospital_rounded), findsNothing);
    expect(find.byTooltip('Tableau de bord'), findsNothing);

    // Approve device and navigate to Dashboard
    // pump x2: first handles navigation, second handles setState from AlertStack._measureFront
    await tester.tap(
      find.text('Approuver l\u2019appareil et ouvrir le tableau de bord'),
    );
    await tester.pump();
    await tester.pump();

    // Phase 3: Dashboard — PageHeader + Right Panel + KPI strip
    expect(find.text('Bonjour, Dr. Nichols!'), findsOneWidget);
    expect(find.text('Mon profil'), findsOneWidget);
    // KPI strip renders metric label as-is (no uppercase in the new design)
    expect(find.text('Alertes critiques'), findsOneWidget);
  });
}
