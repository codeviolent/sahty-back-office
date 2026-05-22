import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/l10n/app_text_key.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/section_card.dart';
import '../../core/widgets/status_badge.dart';

abstract final class _PatientAccessLayout {
  static const double sessionCardMinHeight = 430;
  static const double policyTileMinHeight = 96;
  static const double actionButtonHeight = 46;
  static const double qrSize = 246;
}

class PatientAccessScreen extends StatelessWidget {
  const PatientAccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(flex: 5, child: _SessionScanCard()),
            const SizedBox(width: AppSpacing.lg),
            Expanded(flex: 7, child: _AccessFormCard()),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        const _SessionPolicyStrip(),
      ],
    );
  }
}

class _SessionScanCard extends StatelessWidget {
  const _SessionScanCard();

  @override
  Widget build(BuildContext context) {
    final sessionId = context.tr(AppTextKey.patientAccessSessionIdHint);

    return SectionCard(
      title: context.tr(AppTextKey.patientAccessScanTitle),
      subtitle: context.tr(AppTextKey.patientAccessScanSubtitle),
      minHeight: _PatientAccessLayout.sessionCardMinHeight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.glassSurfaceStrong,
              borderRadius: BorderRadius.circular(AppSpacing.panelRadius),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.14),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: _PatientAccessLayout.qrSize,
                  height: _PatientAccessLayout.qrSize,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.borderFaint),
                  ),
                  child: QrImageView(
                    data: sessionId,
                    version: QrVersions.auto,
                    errorCorrectionLevel: QrErrorCorrectLevel.H,
                    padding: EdgeInsets.zero,
                    backgroundColor: Colors.white,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: AppColors.primary,
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(child: _SessionIdPanel(sessionId: sessionId)),
                    const SizedBox(width: AppSpacing.sm),
                    IconButton.filledTonal(
                      tooltip: context.tr(AppTextKey.patientAccessSessionId),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: sessionId));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              context.tr(AppTextKey.patientAccessSessionId),
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.content_copy_rounded, size: 18),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _SessionSignal(
                  icon: Icons.qr_code_scanner_rounded,
                  label: context.tr(AppTextKey.patientAccessScanTitle),
                  tone: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _SessionSignal(
                  icon: Icons.policy_outlined,
                  label: context.tr(AppTextKey.patientAccessAuditEnabled),
                  tone: AppColors.mutedInk,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SessionIdPanel extends StatelessWidget {
  const _SessionIdPanel({required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr(AppTextKey.patientAccessSessionId),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.mutedInk,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sessionId,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionSignal extends StatelessWidget {
  const _SessionSignal({
    required this.icon,
    required this.label,
    required this.tone,
  });

  final IconData icon;
  final String label;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tone.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Icon(icon, color: tone, size: 16),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccessFormCard extends StatefulWidget {
  @override
  State<_AccessFormCard> createState() => _AccessFormCardState();
}

class _AccessFormCardState extends State<_AccessFormCard> {
  static const int _pinLength = 6;
  static const int _sessionSeconds = 300; // 5 minutes

  final List<TextEditingController> _pinControllers = List.generate(
    _pinLength,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _pinFocusNodes = List.generate(
    _pinLength,
    (_) => FocusNode(),
  );

  late Timer _countdownTimer;

  // ValueNotifier: timer ticks update only the badge and canSubmit check —
  // the PIN inputs and other form elements are never rebuilt by the timer.
  late final ValueNotifier<int> _remainingSeconds;

  String _pin = '';

  @override
  void initState() {
    super.initState();
    _remainingSeconds = ValueNotifier(_sessionSeconds);
    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_remainingSeconds.value <= 0) {
        _countdownTimer.cancel();
      } else {
        _remainingSeconds.value--;
        // No setState — ValueListenableBuilder handles badge + canSubmit
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer.cancel();
    _remainingSeconds.dispose();
    for (final c in _pinControllers) {
      c.dispose();
    }
    for (final f in _pinFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String _formattedTimeFor(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  BadgeTone _timerToneFor(int seconds) {
    if (seconds <= 0) return BadgeTone.critical;
    if (seconds < 60) return BadgeTone.warning;
    return BadgeTone.neutral;
  }

  void _onPinDigitEntered(int index, String value) {
    if (value.isNotEmpty && index < _pinLength - 1) {
      _pinFocusNodes[index + 1].requestFocus();
    }
    setState(() {
      _pin = _pinControllers.map((c) => c.text).join();
    });
  }

  void _onPinBackspace(int index) {
    if (_pinControllers[index].text.isEmpty && index > 0) {
      _pinControllers[index - 1].clear();
      _pinFocusNodes[index - 1].requestFocus();
      setState(() {
        _pin = _pinControllers.map((c) => c.text).join();
      });
    }
  }

  void _openSession() {
    // Mock — in production this calls the PIN verification API
    if (_pin.length == _pinLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr(AppTextKey.patientAccessOpenSession)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // ValueListenableBuilder: only the trailing badge and submit button
    // depend on the countdown — PIN inputs and labels are never touched.
    return ValueListenableBuilder<int>(
      valueListenable: _remainingSeconds,
      builder: (context, remaining, child) {
        final canSubmit = _pin.length == _pinLength && remaining > 0;
        return SectionCard(
          title: context.tr(AppTextKey.patientAccessFormTitle),
          subtitle: context.tr(AppTextKey.patientAccessFormSubtitle),
          minHeight: _PatientAccessLayout.sessionCardMinHeight,
          trailing: StatusBadge(
            label: _formattedTimeFor(remaining),
            tone: _timerToneFor(remaining),
            icon: Icons.timer_outlined,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _FormStagePill(
                    icon: Icons.pin_outlined,
                    label: context.tr(AppTextKey.otp),
                    active: true,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _FormStagePill(
                    icon: Icons.schedule_outlined,
                    label: context.tr(AppTextKey.patientAccessDuration),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _FormStagePill(
                    icon: Icons.person_outline,
                    label: context.tr(AppTextKey.patientAccessDoctor),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(AppSpacing.panelRadius),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.10),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        for (int i = 0; i < _pinLength; i++) ...[
                          Expanded(
                            child: _PinBox(
                              controller: _pinControllers[i],
                              focusNode: _pinFocusNodes[i],
                              onChanged: (v) => _onPinDigitEntered(i, v),
                              onBackspace: () => _onPinBackspace(i),
                            ),
                          ),
                          if (i < _pinLength - 1)
                            const SizedBox(width: AppSpacing.sm),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        StatusBadge(
                          label: context.tr(
                            AppTextKey.patientAccessReasonConsultation,
                          ),
                          tone: BadgeTone.neutral,
                        ),
                        StatusBadge(
                          label: context.tr(
                            AppTextKey.patientAccessReasonEmergency,
                          ),
                          tone: BadgeTone.critical,
                        ),
                        StatusBadge(
                          label: context.tr(
                            AppTextKey.patientAccessReasonFollowUp,
                          ),
                          tone: BadgeTone.neutral,
                        ),
                        StatusBadge(
                          label: context.tr(
                            AppTextKey.patientAccessReasonRenewal,
                          ),
                          tone: BadgeTone.neutral,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        isDense: true,
                        labelText: context.tr(AppTextKey.patientAccessDuration),
                        hintText: context.tr(
                          AppTextKey.patientAccessDurationHint,
                        ),
                        prefixIcon: const Icon(Icons.schedule_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        isDense: true,
                        labelText: context.tr(AppTextKey.patientAccessDoctor),
                        hintText: context.tr(
                          AppTextKey.patientAccessDoctorHint,
                        ),
                        prefixIcon: const Icon(Icons.person_outline),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                height: _PatientAccessLayout.actionButtonHeight,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.mutedInk,
                    foregroundColor: AppColors.surface,
                    disabledBackgroundColor: AppColors.border.withValues(
                      alpha: 0.40,
                    ),
                    disabledForegroundColor: AppColors.mutedInk.withValues(
                      alpha: 0.45,
                    ),
                  ),
                  onPressed: canSubmit ? _openSession : null,
                  icon: const Icon(Icons.lock_open_rounded, size: 18),
                  label: Text(context.tr(AppTextKey.patientAccessOpenSession)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FormStagePill extends StatelessWidget {
  const _FormStagePill({
    required this.icon,
    required this.label,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final tone = active ? AppColors.primary : AppColors.mutedInk;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: tone.withValues(alpha: active ? 0.08 : 0.04),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: tone.withValues(alpha: active ? 0.18 : 0.10),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: tone, size: 14),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: tone,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PinBox extends StatefulWidget {
  const _PinBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onBackspace,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onBackspace;

  @override
  State<_PinBox> createState() => _PinBoxState();
}

class _PinBoxState extends State<_PinBox> {
  // Owned here — created once, properly disposed.
  late final FocusNode _kbFocusNode;

  @override
  void initState() {
    super.initState();
    _kbFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _kbFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _kbFocusNode,
      onKeyEvent: (e) {
        if (e is KeyDownEvent &&
            e.logicalKey == LogicalKeyboardKey.backspace &&
            widget.controller.text.isEmpty) {
          widget.onBackspace();
        }
      },
      child: TextFormField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        keyboardType: TextInputType.number,
        maxLength: 1,
        obscureText: true,
        textAlign: TextAlign.center,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: widget.onChanged,
        decoration: InputDecoration(
          counterText: '',
          contentPadding: EdgeInsets.zero,
          filled: true,
          fillColor: widget.controller.text.isNotEmpty
              ? AppColors.mutedInk.withValues(alpha: 0.08)
              : AppColors.canvas,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: widget.controller.text.isNotEmpty
                  ? AppColors.mutedInk.withValues(alpha: 0.22)
                  : AppColors.border,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          color: AppColors.mutedInk,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _SessionPolicyStrip extends StatelessWidget {
  const _SessionPolicyStrip();

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _PolicyTile(
            icon: Icons.history_toggle_off,
            titleKey: AppTextKey.patientAccessPolicyTemporaryTitle,
            bodyKey: AppTextKey.patientAccessPolicyTemporaryBody,
          ),
        ),
        SizedBox(width: AppSpacing.md),
        Expanded(
          child: _PolicyTile(
            icon: Icons.fact_check_outlined,
            titleKey: AppTextKey.patientAccessPolicyReasonTitle,
            bodyKey: AppTextKey.patientAccessPolicyReasonBody,
          ),
        ),
        SizedBox(width: AppSpacing.md),
        Expanded(
          child: _PolicyTile(
            icon: Icons.logout_rounded,
            titleKey: AppTextKey.patientAccessPolicyEndTitle,
            bodyKey: AppTextKey.patientAccessPolicyEndBody,
          ),
        ),
      ],
    );
  }
}

class _PolicyTile extends StatelessWidget {
  const _PolicyTile({
    required this.icon,
    required this.titleKey,
    required this.bodyKey,
  });

  final IconData icon;
  final AppTextKey titleKey;
  final AppTextKey bodyKey;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: _PatientAccessLayout.policyTileMinHeight,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.borderFaint),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.mutedInk.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.mutedInk, size: 16),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr(titleKey),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 3),
                Text(
                  context.tr(bodyKey),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
