import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../l10n/app_text_key.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'app_state_panel.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Async state model — used with any data loaded from an API or database.
// Eliminates repetitive loading/error/empty handling code in every screen.
// ─────────────────────────────────────────────────────────────────────────────

sealed class AsyncState<T> {
  const AsyncState();
}

final class AsyncLoading<T> extends AsyncState<T> {
  const AsyncLoading();
}

final class AsyncError<T> extends AsyncState<T> {
  const AsyncError(this.error, {this.retry});

  final Object error;
  final VoidCallback? retry;
}

final class AsyncEmpty<T> extends AsyncState<T> {
  const AsyncEmpty();
}

final class AsyncNoPermission<T> extends AsyncState<T> {
  const AsyncNoPermission();
}

final class AsyncSessionExpired<T> extends AsyncState<T> {
  const AsyncSessionExpired({this.onReLogin});

  final VoidCallback? onReLogin;
}

final class AsyncData<T> extends AsyncState<T> {
  const AsyncData(this.value);

  final T value;
}

// ─────────────────────────────────────────────────────────────────────────────

/// Unified architectural widget that renders app states per spec §8:
/// loading — empty — no-permission — session-expired — network-error — data.
class AsyncStateWidget<T> extends StatelessWidget {
  const AsyncStateWidget({
    super.key,
    required this.state,
    required this.builder,
    this.loadingWidget,
    this.errorBuilder,
  });

  final AsyncState<T> state;
  final Widget Function(T data) builder;
  final Widget? loadingWidget;
  final Widget Function(Object error, VoidCallback? retry)? errorBuilder;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      AsyncLoading() => loadingWidget ?? const _LoadingState(),
      AsyncEmpty() => _EmptyState(),
      AsyncNoPermission() => _NoPermissionState(),
      AsyncSessionExpired(:final onReLogin) =>
        _SessionExpiredState(onReLogin: onReLogin),
      AsyncError(:final error, :final retry) => errorBuilder != null
          ? errorBuilder!(error, retry)
          : _ErrorState(error: error, retry: retry),
      AsyncData(:final value) => builder(value),
    };
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            context.tr(AppTextKey.loadingState),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.mutedInk,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppStatePanel(
      icon: Icons.inbox_outlined,
      title: context.tr(AppTextKey.emptyState),
      message: '',
    );
  }
}

class _NoPermissionState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppStatePanel(
      icon: Icons.lock_outline,
      title: context.tr(AppTextKey.noPermissionState),
      message: '',
    );
  }
}

class _SessionExpiredState extends StatelessWidget {
  const _SessionExpiredState({this.onReLogin});

  final VoidCallback? onReLogin;

  @override
  Widget build(BuildContext context) {
    return AppStatePanel(
      icon: Icons.timer_off_outlined,
      title: context.tr(AppTextKey.sessionExpiredState),
      message: '',
      action: onReLogin != null
          ? FilledButton.icon(
              onPressed: onReLogin,
              icon: const Icon(Icons.login_rounded, size: 18),
              label: Text(context.tr(AppTextKey.loginAction)),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
            )
          : null,
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, this.retry});

  final Object error;
  final VoidCallback? retry;

  @override
  Widget build(BuildContext context) {
    final retryLabel = switch (context.appLocale) {
      AppLocale.ar => 'إعادة المحاولة',
      AppLocale.fr => 'Réessayer',
    };
    return AppStatePanel(
      icon: Icons.wifi_off_rounded,
      title: context.tr(AppTextKey.networkDegraded),
      message: error.toString(),
      action: retry != null
          ? OutlinedButton.icon(
              onPressed: retry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: Text(retryLabel),
            )
          : null,
    );
  }
}
