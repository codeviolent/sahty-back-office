import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/l10n/app_localizations.dart';
import '../core/services/session_service.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/data/datasource/auth_datasource.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/auth/presentation/screens/device_trust_screen.dart';
import '../features/auth/presentation/screens/secure_login_screen.dart';
import 'router/app_route.dart';
import 'router/app_router.dart';
import 'shell/presentation/screens/back_office_shell.dart';
import 'startup_splash_screen.dart';

class SahhtiBackOfficeApp extends StatefulWidget {
  const SahhtiBackOfficeApp({super.key});

  @override
  State<SahhtiBackOfficeApp> createState() => _SahhtiBackOfficeAppState();
}

class _SahhtiBackOfficeAppState extends State<SahhtiBackOfficeApp> {
  // ValueNotifier for route: navigation changes update only the
  // ValueListenableBuilder scope, not the entire MaterialApp tree.
  final _routeNotifier = ValueNotifier<AppRoute>(AppRoute.secureLogin);

  AppLocale _locale = AppLocale.fr;
  bool _showStartupSplash = true;
  bool _loginVerified = false;
  bool _deviceTrusted = false;

  // Memoized visible routes — computed once per auth state change,
  // never on every build call.
  List<AppRoute> _visibleRoutes = const [];

  // Shell routes start only after the device is trusted.
  static final List<AppRoute> _shellRoutes = AppRoute.values
      .where((r) => r != AppRoute.secureLogin && r != AppRoute.deviceTrust)
      .toList(growable: false);

  // Built once on first login — each screen wrapped in its own
  // RepaintBoundary + SingleChildScrollView so the IndexedStack
  // keeps every screen alive while isolating scroll and repaint.
  List<Widget>? _allScreens;

  void _initScreens() {
    _allScreens ??= _shellRoutes
        .map(
          (route) => RepaintBoundary(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: AppRouter.buildScreen(
                route,
                onLoginVerified: _verifyLogin,
                onDeviceApproved: _approveDevice,
              ),
            ),
          ),
        )
        .toList(growable: false);
  }

  @override
  void dispose() {
    _routeNotifier.dispose();
    super.dispose();
  }

  void _selectRoute(AppRoute route) {
    // Guard: if device not trusted yet, redirect to trust screen
    if (!_deviceTrusted &&
        route != AppRoute.secureLogin &&
        route != AppRoute.deviceTrust) {
      _routeNotifier.value = AppRoute.deviceTrust;
      return;
    }
    // Update notifier only — no setState, no MaterialApp rebuild
    _routeNotifier.value = route;
  }

  void _verifyLogin() {
    setState(() {
      _loginVerified = true;
      _visibleRoutes = const [AppRoute.deviceTrust];
    });
    _routeNotifier.value = AppRoute.deviceTrust;
  }

  void _approveDevice() {
    _initScreens();
    final role = SessionService.role ?? 'medecin';
    final routesForRole = _shellRoutes
        .where((route) => route.isAllowedFor(role))
        .toList(growable: false);
    setState(() {
      _deviceTrusted = true;
      _visibleRoutes = routesForRole;
    });
    _routeNotifier.value = AppRoute.dashboard;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthBloc(const AuthDatasource()),
      child: AppLocalizationScope(
        locale: _locale,
        onLocaleChanged: (locale) => setState(() => _locale = locale),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Sahty Back Office',
          theme: AppTheme.light,
          locale: _locale.locale,
          supportedLocales: AppLocale.values.map((locale) => locale.locale),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Builder(
            builder: (context) {
              if (_showStartupSplash) {
                return Directionality(
                  textDirection: TextDirection.ltr,
                  child: StartupSplashScreen(
                    onFinished: () {
                      if (!mounted) return;
                      setState(() => _showStartupSplash = false);
                    },
                  ),
                );
              }

              if (!_loginVerified) {
                return Directionality(
                  textDirection: context.appDirection,
                  child: Scaffold(
                    body: ColoredBox(
                      color: AppColors.canvas,
                      child: SafeArea(
                        child: SecureLoginScreen(onLoginVerified: _verifyLogin),
                      ),
                    ),
                  ),
                );
              }

              if (!_deviceTrusted) {
                return Directionality(
                  textDirection: context.appDirection,
                  child: Scaffold(
                    body: SafeArea(
                      child: DeviceTrustScreen(
                        onDeviceApproved: _approveDevice,
                      ),
                    ),
                  ),
                );
              }

              // ValueListenableBuilder: only BackOfficeShell rebuilds on
              // route change. The IndexedStack keeps every screen alive —
              // navigation is instant (no screen destroy / recreate).
              return Directionality(
                textDirection: context.appDirection,
                child: ValueListenableBuilder<AppRoute>(
                  valueListenable: _routeNotifier,
                  builder: (context, route, _) {
                    final index = _shellRoutes.indexOf(route);
                    return BackOfficeShell(
                      selectedRoute: route,
                      onRouteSelected: _selectRoute,
                      visibleRoutes: _visibleRoutes,
                      child: IndexedStack(
                        index: index < 0 ? 0 : index,
                        children: _allScreens!,
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
