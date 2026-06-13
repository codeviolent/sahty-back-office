import 'dart:async';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image/image.dart' as img;
import 'package:sahty_back_office/features/medical_record/presentation/bloc/dossier/dossier_event.dart'
    show DossierSessionClosed, DossierSessionStarted;
import 'package:zxing2/qrcode.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/app_text_key.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../medical_record/data/models/dossier_models.dart';
import '../../../medical_record/presentation/bloc/dossier/dossier_bloc.dart';
import '../../../medical_record/presentation/bloc/dossier/dossier_state.dart';
import '../../../medical_record/presentation/bloc/scanner/scanner_bloc.dart';
import '../../../medical_record/presentation/bloc/scanner/scanner_event.dart';
import '../../../medical_record/presentation/bloc/scanner/scanner_state.dart';

// ── Layout ─────────────────────────────────────────────────────────
abstract final class _Layout {
  static const double cardMinHeight = 430;
  static const double policyMinHeight = 96;
  static const double actionBtnHeight = 46;
  static const double cameraHeight = 286;
  static const int pinLength = 4;
}

// ── Screen ─────────────────────────────────────────────────────────
class PatientAccessScreen extends StatelessWidget {
  const PatientAccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ScannerBloc, ScannerState>(
      listener: (ctx, state) {
        if (state is ScannerGranted) {
          final dossier = ctx.read<DossierBloc>();
          if (!dossier.state.hasActiveSession) {
            dossier.add(DossierSessionStarted(state.session));
          }
        }
      },
      builder: (ctx, scannerState) {
        return BlocBuilder<DossierBloc, DossierState>(
          builder: (ctx, dossierState) {
            // Session dossier déjà ouverte
            if (dossierState.hasActiveSession) {
              return _SessionActiveView(
                session: dossierState.activeSession!,
                onClose: () =>
                    ctx.read<DossierBloc>().add(DossierSessionClosed()),
              );
            }

            return _ScannerPage(scannerState: scannerState);
          },
        );
      },
    );
  }
}

// ── Page scanner ───────────────────────────────────────────────────
class _ScannerPage extends StatelessWidget {
  final ScannerState scannerState;
  const _ScannerPage({required this.scannerState});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 5, child: _CameraCard(state: scannerState)),
            const SizedBox(width: AppSpacing.lg),
            Expanded(flex: 7, child: _PinCard(state: scannerState)),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        const _PolicyStrip(),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────
// CAMÉRA QR (Linux + Windows + macOS)
// ──────────────────────────────────────────────────────────────────
class _CameraCard extends StatelessWidget {
  final ScannerState state;
  const _CameraCard({required this.state});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: context.tr(AppTextKey.patientAccessScanTitle),
      subtitle: context.tr(AppTextKey.patientAccessScanSubtitle),
      minHeight: _Layout.cardMinHeight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: _Layout.cameraHeight,
            decoration: BoxDecoration(
              color: AppColors.ink,
              borderRadius: BorderRadius.circular(AppSpacing.panelRadius),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.18),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.panelRadius),
              child: _buildCameraContent(context),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _Signal(
                  icon: Icons.qr_code_scanner_rounded,
                  label: context.tr(AppTextKey.patientAccessScanTitle),
                  tone: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _Signal(
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

  Widget _buildCameraContent(BuildContext context) {
    if (state is ScannerAwaitingPin) {
      return _QrDetectedOverlay(
        qrToken: (state as ScannerAwaitingPin).qrToken,
        onRescan: () => context.read<ScannerBloc>().add(ScannerReset()),
      );
    }
    if (state is ScannerVerifying) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (state is ScannerBlocked) {
      return _BlockedOverlay(message: (state as ScannerBlocked).message);
    }

    // Caméra active
    return _DesktopQrCamera(
      active: state is ScannerScanning,
      onDetected: (token) =>
          context.read<ScannerBloc>().add(ScannerQrDetected(token)),
    );
  }
}

// ── Widget caméra desktop ─────────────────────────────────────────
class _DesktopQrCamera extends StatefulWidget {
  final bool active;
  final void Function(String token) onDetected;
  const _DesktopQrCamera({required this.active, required this.onDetected});
  @override
  State<_DesktopQrCamera> createState() => _DesktopQrCameraState();
}

class _DesktopQrCameraState extends State<_DesktopQrCamera> {
  CameraController? _ctrl;
  String? _error;
  bool _processing = false;
  int _frameSkip = 0;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  // ── Initialisation caméra ────────────────────────────────────
  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) setState(() => _error = 'Aucune caméra détectée');
        return;
      }

      _ctrl = CameraController(
        cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
        // Pas de imageFormatGroup → laisse le driver choisir
        // BGRA8888 sur Win/Mac, YUV420 sur Linux
      );

      await _ctrl!.initialize();
      if (!mounted) return;

      await _ctrl!.startImageStream(_onFrame);
      setState(() {});
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  // ── Traitement frames ─────────────────────────────────────────
  void _onFrame(CameraImage frame) {
    _frameSkip++;
    // Traiter 1 frame sur 15 (~2/s à 30fps)
    if (_frameSkip % 15 != 0 || _processing || !widget.active) return;
    _processing = true;

    _decodeFrame(frame)
        .then((token) {
          _processing = false;
          if (token != null && mounted && widget.active) {
            widget.onDetected(token);
          }
        })
        .catchError((_) => _processing = false);
  }

  // ── Décodage QR depuis une frame ──────────────────────────────
  Future<String?> _decodeFrame(CameraImage frame) async {
    try {
      img.Image? raw;

      // Windows / macOS → BGRA8888
      if (frame.format.group == ImageFormatGroup.bgra8888) {
        raw = img.Image.fromBytes(
          width: frame.width,
          height: frame.height,
          bytes: frame.planes[0].bytes.buffer,
          format: img.Format.uint8,
          numChannels: 4,
          order: img.ChannelOrder.bgra,
        );
      }
      // Linux → YUV420
      else if (frame.format.group == ImageFormatGroup.yuv420) {
        raw = _yuv420ToRgb(frame);
      }

      if (raw == null) return null;

      // Redimensionner pour accélérer le décodage
      final small = img.copyResize(raw, width: 400);
      return _decodeQr(small);
    } catch (_) {
      return null;
    }
  }

  // ── Conversion YUV420 → RGB (Linux) ───────────────────────────
  img.Image _yuv420ToRgb(CameraImage f) {
    final w = f.width, h = f.height;
    final out = img.Image(width: w, height: h);

    final yBytes = f.planes[0].bytes;
    final uBytes = f.planes[1].bytes;
    final vBytes = f.planes[2].bytes;
    final yRow = f.planes[0].bytesPerRow;
    final uvRow = f.planes[1].bytesPerRow;
    final uvPx = f.planes[1].bytesPerPixel ?? 1;

    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final yv = yBytes[y * yRow + x] & 0xFF;
        final idx = (y >> 1) * uvRow + (x >> 1) * uvPx;
        final uv = (uBytes[idx] & 0xFF) - 128;
        final vv = (vBytes[idx] & 0xFF) - 128;

        final r = (yv + 1.402 * vv).round().clamp(0, 255);
        final g = (yv - 0.344 * uv - 0.714 * vv).round().clamp(0, 255);
        final b = (yv + 1.772 * uv).round().clamp(0, 255);

        out.setPixelRgba(x, y, r, g, b, 255);
      }
    }
    return out;
  }

  // ── Décodage QR (zxing2 — pur Dart) ──────────────────────────
  String? _decodeQr(img.Image image) {
    final w = image.width, h = image.height;
    final rgb = Int32List(w * h);

    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final p = image.getPixel(x, y);
        // ARGB en Int32 signé — zxing2 traite comme unsigned
        rgb[y * w + x] =
            (0xFF << 24) |
            (p.r.toInt() << 16) |
            (p.g.toInt() << 8) |
            p.b.toInt();
      }
    }

    try {
      final src = RGBLuminanceSource(w, h, rgb);
      final bitmap = BinaryBitmap(HybridBinarizer(src));
      return QRCodeReader().decode(bitmap).text;
    } catch (_) {
      return null; // Pas de QR dans cette frame
    }
  }

  @override
  void dispose() {
    _ctrl?.stopImageStream().then((_) => _ctrl?.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Erreur caméra → saisie manuelle
    if (_error != null) {
      return _ManualTokenEntry(error: _error!, onConfirm: widget.onDetected);
    }
    // Chargement caméra
    if (_ctrl == null || !_ctrl!.value.isInitialized) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
          SizedBox(height: AppSpacing.lg),
          Text(
            'Initialisation caméra...',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      );
    }

    // Prévisualisation caméra + cadre QR
    return Stack(
      fit: StackFit.expand,
      children: [
        CameraPreview(_ctrl!),
        // Cadre de visée
        Center(
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primary, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        // Coins du cadre
        const _QrFrameCorners(),
        // Label bas
        Positioned(
          bottom: AppSpacing.lg,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Pointez vers le QR Code du patient',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Coins décoratifs du cadre QR ──────────────────────────────────
class _QrFrameCorners extends StatelessWidget {
  const _QrFrameCorners();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _CornerPainter());
  }
}

class _CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    const half = 100.0;
    const len = 20.0;
    const r = 12.0;

    final paint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // 4 coins
    for (final (sx, sy) in [
      (cx - half, cy - half),
      (cx + half, cy - half),
      (cx + half, cy + half),
      (cx - half, cy + half),
    ]) {
      final dx = sx < cx ? 1.0 : -1.0;
      final dy = sy < cy ? 1.0 : -1.0;
      canvas.drawLine(
        Offset(sx + dx * r, sy),
        Offset(sx + dx * len, sy),
        paint,
      );
      canvas.drawLine(
        Offset(sx, sy + dy * r),
        Offset(sx, sy + dy * len),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── Saisie manuelle (fallback si pas de caméra) ───────────────────
class _ManualTokenEntry extends StatefulWidget {
  final String error;
  final void Function(String) onConfirm;
  const _ManualTokenEntry({required this.error, required this.onConfirm});
  @override
  State<_ManualTokenEntry> createState() => _ManualTokenEntryState();
}

class _ManualTokenEntryState extends State<_ManualTokenEntry> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.no_photography_outlined,
            size: 40,
            color: Colors.white54,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Caméra indisponible',
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            widget.error,
            style: const TextStyle(color: Colors.white38, fontSize: 10),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.xl),
          // Saisie token manuel depuis l'app mobile du patient
          TextField(
            controller: _ctrl,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Token QR (copié depuis l\'app patient)',
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: Colors.white12,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.white24),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.white24),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                final v = _ctrl.text.trim();
                if (v.isNotEmpty) widget.onConfirm(v);
              },
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Valider le token'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Overlay QR détecté ─────────────────────────────────────────────
class _QrDetectedOverlay extends StatelessWidget {
  final String qrToken;
  final VoidCallback onRescan;
  const _QrDetectedOverlay({required this.qrToken, required this.onRescan});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black87,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: AppColors.normal,
            size: 64,
          ),
          const SizedBox(height: AppSpacing.lg),
          const Text(
            'QR Code détecté',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            qrToken.length > 12 ? '${qrToken.substring(0, 12)}...' : qrToken,
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
          const SizedBox(height: AppSpacing.xl),
          TextButton.icon(
            onPressed: onRescan,
            icon: const Icon(
              Icons.refresh_rounded,
              color: Colors.white70,
              size: 14,
            ),
            label: const Text(
              'Rescanner',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Overlay bloqué ─────────────────────────────────────────────────
class _BlockedOverlay extends StatelessWidget {
  final String message;
  const _BlockedOverlay({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black87,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.block_rounded, color: AppColors.critical, size: 48),
          const SizedBox(height: AppSpacing.lg),
          const Text(
            'Accès bloqué',
            style: TextStyle(
              color: AppColors.critical,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            style: const TextStyle(color: Colors.white60, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────
// PIN CARD
// ──────────────────────────────────────────────────────────────────
class _PinCard extends StatefulWidget {
  final ScannerState state;
  const _PinCard({required this.state});
  @override
  State<_PinCard> createState() => _PinCardState();
}

class _PinCardState extends State<_PinCard> {
  final _controllers = List.generate(
    _Layout.pinLength,
    (_) => TextEditingController(),
  );
  final _focusNodes = List.generate(_Layout.pinLength, (_) => FocusNode());
  String _pin = '';

  @override
  void didUpdateWidget(_PinCard old) {
    super.didUpdateWidget(old);
    if (widget.state is ScannerScanning || widget.state is ScannerDenied) {
      _clearPin();
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    super.dispose();
  }

  void _clearPin() {
    for (final c in _controllers) c.clear();
    if (mounted) setState(() => _pin = '');
  }

  void _onDigit(int i, String v) {
    if (v.isNotEmpty && i < _Layout.pinLength - 1) {
      _focusNodes[i + 1].requestFocus();
    }
    setState(() => _pin = _controllers.map((c) => c.text).join());
  }

  void _onBackspace(int i) {
    if (_controllers[i].text.isEmpty && i > 0) {
      _controllers[i - 1].clear();
      _focusNodes[i - 1].requestFocus();
      setState(() => _pin = _controllers.map((c) => c.text).join());
    }
  }

  void _submit(BuildContext ctx) {
    if (_pin.length == _Layout.pinLength) {
      ctx.read<ScannerBloc>().add(ScannerPinSubmitted(_pin));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final isAwaiting = state is ScannerAwaitingPin;
    final isVerify = state is ScannerVerifying;
    final isDenied = state is ScannerDenied;
    final canSubmit =
        isAwaiting && _pin.length == _Layout.pinLength && !isVerify;

    return SectionCard(
      title: context.tr(AppTextKey.patientAccessFormTitle),
      subtitle: context.tr(AppTextKey.patientAccessFormSubtitle),
      minHeight: _Layout.cardMinHeight,
      trailing: _statusBadge(state, context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Étapes
          Row(
            children: [
              _StagePill(
                icon: Icons.qr_code_rounded,
                label: 'QR Code',
                done: isAwaiting || isVerify || isDenied,
                active: false,
              ),
              const SizedBox(width: AppSpacing.sm),
              _StagePill(
                icon: Icons.pin_outlined,
                label: context.tr(AppTextKey.otp),
                active: isAwaiting,
              ),
              const SizedBox(width: AppSpacing.sm),
              _StagePill(
                icon: Icons.lock_open_rounded,
                label: '30 min',
                active: false,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Zone PIN
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
                // Placeholder si pas encore de QR
                if (!isAwaiting && !isVerify && !isDenied)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                    child: Center(
                      child: Text(
                        'Scannez d\'abord le QR Code',
                        style: TextStyle(
                          color: AppColors.mutedInk,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  )
                else ...[
                  // 4 cases PIN
                  Row(
                    children: [
                      for (int i = 0; i < _Layout.pinLength; i++) ...[
                        Expanded(
                          child: _PinBox(
                            controller: _controllers[i],
                            focusNode: _focusNodes[i],
                            onChanged: (v) => _onDigit(i, v),
                            onBackspace: () => _onBackspace(i),
                            enabled: isAwaiting && !isVerify,
                            autoFocus: i == 0,
                          ),
                        ),
                        if (i < _Layout.pinLength - 1)
                          const SizedBox(width: AppSpacing.sm),
                      ],
                    ],
                  ),
                ],

                // Erreur PIN incorrect
                if (isDenied) ...[
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.critical.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.critical.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.lock_outline,
                          color: AppColors.critical,
                          size: 14,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            '${(state as ScannerDenied).message}'
                            '${state.attemptsLeft > 0 ? "  —  ${state.attemptsLeft} tentative(s) restante(s)" : ""}',
                            style: const TextStyle(
                              color: AppColors.critical,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Motifs d'accès
                if (isAwaiting) ...[
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
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Info durée + audit
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.schedule_outlined,
                  size: 15,
                  color: AppColors.mutedInk,
                ),
                const SizedBox(width: AppSpacing.sm),
                const Expanded(
                  child: Text(
                    'Session de 30 minutes — fermeture automatique',
                    style: TextStyle(fontSize: 12, color: AppColors.mutedInk),
                  ),
                ),
                StatusBadge(
                  label: context.tr(AppTextKey.patientAccessAuditEnabled),
                  tone: BadgeTone.neutral,
                  icon: Icons.policy_outlined,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Bouton Ouvrir session
          SizedBox(
            width: double.infinity,
            height: _Layout.actionBtnHeight,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: canSubmit
                    ? AppColors.primary
                    : AppColors.mutedInk,
                foregroundColor: AppColors.surface,
                disabledBackgroundColor: AppColors.border.withValues(
                  alpha: 0.40,
                ),
                disabledForegroundColor: AppColors.mutedInk.withValues(
                  alpha: 0.45,
                ),
              ),
              onPressed: canSubmit ? () => _submit(context) : null,
              icon: isVerify
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.lock_open_rounded, size: 18),
              label: Text(
                isVerify
                    ? 'Vérification...'
                    : context.tr(AppTextKey.patientAccessOpenSession),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(ScannerState state, BuildContext ctx) {
    return switch (state) {
      ScannerScanning() => StatusBadge(
        label: 'En attente QR',
        tone: BadgeTone.neutral,
        icon: Icons.qr_code_scanner_rounded,
      ),
      ScannerAwaitingPin() => StatusBadge(
        label: 'QR Détecté ✓',
        tone: BadgeTone.normal,
        icon: Icons.check_circle_outline,
      ),
      ScannerVerifying() => StatusBadge(
        label: 'Vérification',
        tone: BadgeTone.neutral,
        icon: Icons.pending,
      ),
      ScannerDenied() => StatusBadge(
        label: 'PIN refusé',
        tone: BadgeTone.critical,
        icon: Icons.lock_outline,
      ),
      ScannerBlocked() => StatusBadge(
        label: 'Bloqué',
        tone: BadgeTone.critical,
        icon: Icons.block,
      ),
      _ => const SizedBox.shrink(),
    };
  }
}

// ── _PinBox ────────────────────────────────────────────────────────
class _PinBox extends StatefulWidget {
  const _PinBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onBackspace,
    required this.enabled,
    this.autoFocus = false,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onBackspace;
  final bool enabled;
  final bool autoFocus;

  @override
  State<_PinBox> createState() => _PinBoxState();
}

class _PinBoxState extends State<_PinBox> {
  late final FocusNode _kb;
  @override
  void initState() {
    super.initState();
    _kb = FocusNode();
  }

  @override
  void dispose() {
    _kb.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _kb,
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
        enabled: widget.enabled,
        autofocus: widget.autoFocus,
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
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: AppColors.border.withValues(alpha: 0.4),
            ),
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

// ── Session déjà active ────────────────────────────────────────────
class _SessionActiveView extends StatelessWidget {
  final PatientSession session;
  final VoidCallback onClose;
  const _SessionActiveView({required this.session, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Bannière verte
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.normal.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.normal.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.normal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.lock_open_rounded,
                  color: AppColors.normal,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Session active — ${session.displayName}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.normal,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Expire dans ${session.remainingLabel} '
                      '· ${session.durationLabel}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.normal,
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: onClose,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.critical,
                  side: const BorderSide(color: AppColors.critical),
                ),
                icon: const Icon(Icons.close_rounded, size: 14),
                label: const Text('Fermer'),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        // Guide d'utilisation
        SectionCard(
          title: 'Dossier ouvert',
          subtitle: 'Naviguez dans la barre latérale pour consulter le dossier',
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: Column(
              children: [
                const Icon(
                  Icons.folder_open_rounded,
                  size: 64,
                  color: AppColors.primary,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Dossier de ${session.displayName}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'Utilisez la barre latérale gauche pour accéder aux sections :\n'
                  'Aperçu médical, Diagnostics, Ordonnances, Constantes, Vaccins...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.mutedInk,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const _PolicyStrip(),
      ],
    );
  }
}

// ── Widgets utilitaires ────────────────────────────────────────────
class _StagePill extends StatelessWidget {
  const _StagePill({
    required this.icon,
    required this.label,
    this.active = false,
    this.done = false,
  });

  final IconData icon;
  final String label;
  final bool active;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final tone = done
        ? AppColors.normal
        : active
        ? AppColors.primary
        : AppColors.mutedInk;

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
            Icon(
              done ? Icons.check_circle_rounded : icon,
              color: tone,
              size: 14,
            ),
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

class _Signal extends StatelessWidget {
  const _Signal({required this.icon, required this.label, required this.tone});
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

// ── Policy Strip ───────────────────────────────────────────────────
class _PolicyStrip extends StatelessWidget {
  const _PolicyStrip();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _PolicyTile(
            icon: Icons.history_toggle_off,
            titleKey: AppTextKey.patientAccessPolicyTemporaryTitle,
            bodyKey: AppTextKey.patientAccessPolicyTemporaryBody,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _PolicyTile(
            icon: Icons.fact_check_outlined,
            titleKey: AppTextKey.patientAccessPolicyReasonTitle,
            bodyKey: AppTextKey.patientAccessPolicyReasonBody,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
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
      constraints: const BoxConstraints(minHeight: _Layout.policyMinHeight),
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

// import 'dart:async';

// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:qr_flutter/qr_flutter.dart';

// import '../../../../core/l10n/app_localizations.dart';
// import '../../../../core/l10n/app_text_key.dart';
// import '../../../../core/theme/app_colors.dart';
// import '../../../../core/theme/app_spacing.dart';
// import '../../../../core/widgets/section_card.dart';
// import '../../../../core/widgets/status_badge.dart';

// abstract final class _PatientAccessLayout {
//   static const double sessionCardMinHeight = 430;
//   static const double policyTileMinHeight = 96;
//   static const double actionButtonHeight = 46;
//   static const double qrSize = 246;
// }

// class PatientAccessScreen extends StatelessWidget {
//   const PatientAccessScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Expanded(flex: 5, child: _SessionScanCard()),
//             const SizedBox(width: AppSpacing.lg),
//             Expanded(flex: 7, child: _AccessFormCard()),
//           ],
//         ),
//         const SizedBox(height: AppSpacing.lg),
//         const _SessionPolicyStrip(),
//       ],
//     );
//   }
// }

// class _SessionScanCard extends StatelessWidget {
//   const _SessionScanCard();

//   @override
//   Widget build(BuildContext context) {
//     final sessionId = context.tr(AppTextKey.patientAccessSessionIdHint);

//     return SectionCard(
//       title: context.tr(AppTextKey.patientAccessScanTitle),
//       subtitle: context.tr(AppTextKey.patientAccessScanSubtitle),
//       minHeight: _PatientAccessLayout.sessionCardMinHeight,
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.stretch,
//         children: [
//           Container(
//             padding: const EdgeInsets.all(AppSpacing.lg),
//             decoration: BoxDecoration(
//               color: AppColors.glassSurfaceStrong,
//               borderRadius: BorderRadius.circular(AppSpacing.panelRadius),
//               border: Border.all(
//                 color: AppColors.primary.withValues(alpha: 0.14),
//               ),
//             ),
//             child: Column(
//               children: [
//                 Container(
//                   width: _PatientAccessLayout.qrSize,
//                   height: _PatientAccessLayout.qrSize,
//                   padding: const EdgeInsets.all(AppSpacing.lg),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(24),
//                     border: Border.all(color: AppColors.borderFaint),
//                   ),
//                   child: QrImageView(
//                     data: sessionId,
//                     version: QrVersions.auto,
//                     errorCorrectionLevel: QrErrorCorrectLevel.H,
//                     padding: EdgeInsets.zero,
//                     backgroundColor: Colors.white,
//                     eyeStyle: const QrEyeStyle(
//                       eyeShape: QrEyeShape.square,
//                       color: AppColors.primary,
//                     ),
//                     dataModuleStyle: const QrDataModuleStyle(
//                       dataModuleShape: QrDataModuleShape.square,
//                       color: AppColors.ink,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: AppSpacing.lg),
//                 Row(
//                   children: [
//                     Expanded(child: _SessionIdPanel(sessionId: sessionId)),
//                     const SizedBox(width: AppSpacing.sm),
//                     IconButton.filledTonal(
//                       tooltip: context.tr(AppTextKey.patientAccessSessionId),
//                       onPressed: () {
//                         Clipboard.setData(ClipboardData(text: sessionId));
//                         ScaffoldMessenger.of(context).showSnackBar(
//                           SnackBar(
//                             content: Text(
//                               context.tr(AppTextKey.patientAccessSessionId),
//                             ),
//                           ),
//                         );
//                       },
//                       icon: const Icon(Icons.content_copy_rounded, size: 18),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(height: AppSpacing.md),
//           Row(
//             children: [
//               Expanded(
//                 child: _SessionSignal(
//                   icon: Icons.qr_code_scanner_rounded,
//                   label: context.tr(AppTextKey.patientAccessScanTitle),
//                   tone: AppColors.primary,
//                 ),
//               ),
//               const SizedBox(width: AppSpacing.sm),
//               Expanded(
//                 child: _SessionSignal(
//                   icon: Icons.policy_outlined,
//                   label: context.tr(AppTextKey.patientAccessAuditEnabled),
//                   tone: AppColors.mutedInk,
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _SessionIdPanel extends StatelessWidget {
//   const _SessionIdPanel({required this.sessionId});

//   final String sessionId;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(
//         horizontal: AppSpacing.md,
//         vertical: AppSpacing.sm,
//       ),
//       decoration: BoxDecoration(
//         color: AppColors.primary.withValues(alpha: 0.055),
//         borderRadius: BorderRadius.circular(14),
//         border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             context.tr(AppTextKey.patientAccessSessionId),
//             style: Theme.of(context).textTheme.labelSmall?.copyWith(
//               color: AppColors.mutedInk,
//               fontWeight: FontWeight.w700,
//             ),
//           ),
//           const SizedBox(height: 2),
//           Text(
//             sessionId,
//             maxLines: 1,
//             overflow: TextOverflow.ellipsis,
//             style: Theme.of(context).textTheme.bodySmall?.copyWith(
//               color: AppColors.ink,
//               fontWeight: FontWeight.w900,
//               letterSpacing: 0.2,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _SessionSignal extends StatelessWidget {
//   const _SessionSignal({
//     required this.icon,
//     required this.label,
//     required this.tone,
//   });

//   final IconData icon;
//   final String label;
//   final Color tone;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(AppSpacing.md),
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(14),
//         border: Border.all(color: tone.withValues(alpha: 0.14)),
//       ),
//       child: Row(
//         children: [
//           Icon(icon, color: tone, size: 16),
//           const SizedBox(width: AppSpacing.sm),
//           Expanded(
//             child: Text(
//               label,
//               maxLines: 2,
//               overflow: TextOverflow.ellipsis,
//               style: Theme.of(context).textTheme.labelSmall?.copyWith(
//                 color: AppColors.ink,
//                 fontWeight: FontWeight.w800,
//                 height: 1.2,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _AccessFormCard extends StatefulWidget {
//   @override
//   State<_AccessFormCard> createState() => _AccessFormCardState();
// }

// class _AccessFormCardState extends State<_AccessFormCard> {
//   static const int _pinLength = 6;
//   static const int _sessionSeconds = 300; // 5 minutes

//   final List<TextEditingController> _pinControllers = List.generate(
//     _pinLength,
//     (_) => TextEditingController(),
//   );
//   final List<FocusNode> _pinFocusNodes = List.generate(
//     _pinLength,
//     (_) => FocusNode(),
//   );

//   late Timer _countdownTimer;

//   // ValueNotifier: timer ticks update only the badge and canSubmit check —
//   // the PIN inputs and other form elements are never rebuilt by the timer.
//   late final ValueNotifier<int> _remainingSeconds;

//   String _pin = '';

//   @override
//   void initState() {
//     super.initState();
//     _remainingSeconds = ValueNotifier(_sessionSeconds);
//     _startCountdown();
//   }

//   void _startCountdown() {
//     _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
//       if (!mounted) return;
//       if (_remainingSeconds.value <= 0) {
//         _countdownTimer.cancel();
//       } else {
//         _remainingSeconds.value--;
//         // No setState — ValueListenableBuilder handles badge + canSubmit
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _countdownTimer.cancel();
//     _remainingSeconds.dispose();
//     for (final c in _pinControllers) {
//       c.dispose();
//     }
//     for (final f in _pinFocusNodes) {
//       f.dispose();
//     }
//     super.dispose();
//   }

//   String _formattedTimeFor(int seconds) {
//     final m = (seconds ~/ 60).toString().padLeft(2, '0');
//     final s = (seconds % 60).toString().padLeft(2, '0');
//     return '$m:$s';
//   }

//   BadgeTone _timerToneFor(int seconds) {
//     if (seconds <= 0) return BadgeTone.critical;
//     if (seconds < 60) return BadgeTone.warning;
//     return BadgeTone.neutral;
//   }

//   void _onPinDigitEntered(int index, String value) {
//     if (value.isNotEmpty && index < _pinLength - 1) {
//       _pinFocusNodes[index + 1].requestFocus();
//     }
//     setState(() {
//       _pin = _pinControllers.map((c) => c.text).join();
//     });
//   }

//   void _onPinBackspace(int index) {
//     if (_pinControllers[index].text.isEmpty && index > 0) {
//       _pinControllers[index - 1].clear();
//       _pinFocusNodes[index - 1].requestFocus();
//       setState(() {
//         _pin = _pinControllers.map((c) => c.text).join();
//       });
//     }
//   }

//   void _openSession() {
//     // Mock — in production this calls the PIN verification API
//     if (_pin.length == _pinLength) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(context.tr(AppTextKey.patientAccessOpenSession)),
//         ),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     // ValueListenableBuilder: only the trailing badge and submit button
//     // depend on the countdown — PIN inputs and labels are never touched.
//     return ValueListenableBuilder<int>(
//       valueListenable: _remainingSeconds,
//       builder: (context, remaining, child) {
//         final canSubmit = _pin.length == _pinLength && remaining > 0;
//         return SectionCard(
//           title: context.tr(AppTextKey.patientAccessFormTitle),
//           subtitle: context.tr(AppTextKey.patientAccessFormSubtitle),
//           minHeight: _PatientAccessLayout.sessionCardMinHeight,
//           trailing: StatusBadge(
//             label: _formattedTimeFor(remaining),
//             tone: _timerToneFor(remaining),
//             icon: Icons.timer_outlined,
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 children: [
//                   _FormStagePill(
//                     icon: Icons.pin_outlined,
//                     label: context.tr(AppTextKey.otp),
//                     active: true,
//                   ),
//                   const SizedBox(width: AppSpacing.sm),
//                   _FormStagePill(
//                     icon: Icons.schedule_outlined,
//                     label: context.tr(AppTextKey.patientAccessDuration),
//                   ),
//                   const SizedBox(width: AppSpacing.sm),
//                   _FormStagePill(
//                     icon: Icons.person_outline,
//                     label: context.tr(AppTextKey.patientAccessDoctor),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: AppSpacing.md),
//               Container(
//                 padding: const EdgeInsets.all(AppSpacing.lg),
//                 decoration: BoxDecoration(
//                   color: AppColors.primary.withValues(alpha: 0.04),
//                   borderRadius: BorderRadius.circular(AppSpacing.panelRadius),
//                   border: Border.all(
//                     color: AppColors.primary.withValues(alpha: 0.10),
//                   ),
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       children: [
//                         for (int i = 0; i < _pinLength; i++) ...[
//                           Expanded(
//                             child: _PinBox(
//                               controller: _pinControllers[i],
//                               focusNode: _pinFocusNodes[i],
//                               onChanged: (v) => _onPinDigitEntered(i, v),
//                               onBackspace: () => _onPinBackspace(i),
//                             ),
//                           ),
//                           if (i < _pinLength - 1)
//                             const SizedBox(width: AppSpacing.sm),
//                         ],
//                       ],
//                     ),
//                     const SizedBox(height: AppSpacing.md),
//                     Wrap(
//                       spacing: AppSpacing.sm,
//                       runSpacing: AppSpacing.sm,
//                       children: [
//                         StatusBadge(
//                           label: context.tr(
//                             AppTextKey.patientAccessReasonConsultation,
//                           ),
//                           tone: BadgeTone.neutral,
//                         ),
//                         StatusBadge(
//                           label: context.tr(
//                             AppTextKey.patientAccessReasonEmergency,
//                           ),
//                           tone: BadgeTone.critical,
//                         ),
//                         StatusBadge(
//                           label: context.tr(
//                             AppTextKey.patientAccessReasonFollowUp,
//                           ),
//                           tone: BadgeTone.neutral,
//                         ),
//                         StatusBadge(
//                           label: context.tr(
//                             AppTextKey.patientAccessReasonRenewal,
//                           ),
//                           tone: BadgeTone.neutral,
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: AppSpacing.md),
//               Row(
//                 children: [
//                   Expanded(
//                     child: TextField(
//                       decoration: InputDecoration(
//                         isDense: true,
//                         labelText: context.tr(AppTextKey.patientAccessDuration),
//                         hintText: context.tr(
//                           AppTextKey.patientAccessDurationHint,
//                         ),
//                         prefixIcon: const Icon(Icons.schedule_outlined),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: AppSpacing.md),
//                   Expanded(
//                     child: TextField(
//                       decoration: InputDecoration(
//                         isDense: true,
//                         labelText: context.tr(AppTextKey.patientAccessDoctor),
//                         hintText: context.tr(
//                           AppTextKey.patientAccessDoctorHint,
//                         ),
//                         prefixIcon: const Icon(Icons.person_outline),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: AppSpacing.md),
//               SizedBox(
//                 width: double.infinity,
//                 height: _PatientAccessLayout.actionButtonHeight,
//                 child: FilledButton.icon(
//                   style: FilledButton.styleFrom(
//                     backgroundColor: AppColors.mutedInk,
//                     foregroundColor: AppColors.surface,
//                     disabledBackgroundColor: AppColors.border.withValues(
//                       alpha: 0.40,
//                     ),
//                     disabledForegroundColor: AppColors.mutedInk.withValues(
//                       alpha: 0.45,
//                     ),
//                   ),
//                   onPressed: canSubmit ? _openSession : null,
//                   icon: const Icon(Icons.lock_open_rounded, size: 18),
//                   label: Text(context.tr(AppTextKey.patientAccessOpenSession)),
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
// }

// class _FormStagePill extends StatelessWidget {
//   const _FormStagePill({
//     required this.icon,
//     required this.label,
//     this.active = false,
//   });

//   final IconData icon;
//   final String label;
//   final bool active;

//   @override
//   Widget build(BuildContext context) {
//     final tone = active ? AppColors.primary : AppColors.mutedInk;
//     return Expanded(
//       child: Container(
//         padding: const EdgeInsets.symmetric(
//           horizontal: AppSpacing.md,
//           vertical: AppSpacing.sm,
//         ),
//         decoration: BoxDecoration(
//           color: tone.withValues(alpha: active ? 0.08 : 0.04),
//           borderRadius: BorderRadius.circular(999),
//           border: Border.all(
//             color: tone.withValues(alpha: active ? 0.18 : 0.10),
//           ),
//         ),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(icon, color: tone, size: 14),
//             const SizedBox(width: AppSpacing.xs),
//             Flexible(
//               child: Text(
//                 label,
//                 maxLines: 1,
//                 overflow: TextOverflow.ellipsis,
//                 style: Theme.of(context).textTheme.labelSmall?.copyWith(
//                   color: tone,
//                   fontWeight: FontWeight.w800,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _PinBox extends StatefulWidget {
//   const _PinBox({
//     required this.controller,
//     required this.focusNode,
//     required this.onChanged,
//     required this.onBackspace,
//   });

//   final TextEditingController controller;
//   final FocusNode focusNode;
//   final ValueChanged<String> onChanged;
//   final VoidCallback onBackspace;

//   @override
//   State<_PinBox> createState() => _PinBoxState();
// }

// class _PinBoxState extends State<_PinBox> {
//   // Owned here — created once, properly disposed.
//   late final FocusNode _kbFocusNode;

//   @override
//   void initState() {
//     super.initState();
//     _kbFocusNode = FocusNode();
//   }

//   @override
//   void dispose() {
//     _kbFocusNode.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return KeyboardListener(
//       focusNode: _kbFocusNode,
//       onKeyEvent: (e) {
//         if (e is KeyDownEvent &&
//             e.logicalKey == LogicalKeyboardKey.backspace &&
//             widget.controller.text.isEmpty) {
//           widget.onBackspace();
//         }
//       },
//       child: TextFormField(
//         controller: widget.controller,
//         focusNode: widget.focusNode,
//         keyboardType: TextInputType.number,
//         maxLength: 1,
//         obscureText: true,
//         textAlign: TextAlign.center,
//         inputFormatters: [FilteringTextInputFormatter.digitsOnly],
//         onChanged: widget.onChanged,
//         decoration: InputDecoration(
//           counterText: '',
//           contentPadding: EdgeInsets.zero,
//           filled: true,
//           fillColor: widget.controller.text.isNotEmpty
//               ? AppColors.mutedInk.withValues(alpha: 0.08)
//               : AppColors.canvas,
//           enabledBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(10),
//             borderSide: BorderSide(
//               color: widget.controller.text.isNotEmpty
//                   ? AppColors.mutedInk.withValues(alpha: 0.22)
//                   : AppColors.border,
//             ),
//           ),
//           focusedBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(10),
//             borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
//           ),
//         ),
//         style: Theme.of(context).textTheme.headlineSmall?.copyWith(
//           color: AppColors.mutedInk,
//           fontWeight: FontWeight.w900,
//         ),
//       ),
//     );
//   }
// }

// class _SessionPolicyStrip extends StatelessWidget {
//   const _SessionPolicyStrip();

//   @override
//   Widget build(BuildContext context) {
//     return const Row(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Expanded(
//           child: _PolicyTile(
//             icon: Icons.history_toggle_off,
//             titleKey: AppTextKey.patientAccessPolicyTemporaryTitle,
//             bodyKey: AppTextKey.patientAccessPolicyTemporaryBody,
//           ),
//         ),
//         SizedBox(width: AppSpacing.md),
//         Expanded(
//           child: _PolicyTile(
//             icon: Icons.fact_check_outlined,
//             titleKey: AppTextKey.patientAccessPolicyReasonTitle,
//             bodyKey: AppTextKey.patientAccessPolicyReasonBody,
//           ),
//         ),
//         SizedBox(width: AppSpacing.md),
//         Expanded(
//           child: _PolicyTile(
//             icon: Icons.logout_rounded,
//             titleKey: AppTextKey.patientAccessPolicyEndTitle,
//             bodyKey: AppTextKey.patientAccessPolicyEndBody,
//           ),
//         ),
//       ],
//     );
//   }
// }

// class _PolicyTile extends StatelessWidget {
//   const _PolicyTile({
//     required this.icon,
//     required this.titleKey,
//     required this.bodyKey,
//   });

//   final IconData icon;
//   final AppTextKey titleKey;
//   final AppTextKey bodyKey;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       constraints: const BoxConstraints(
//         minHeight: _PatientAccessLayout.policyTileMinHeight,
//       ),
//       padding: const EdgeInsets.all(AppSpacing.md),
//       decoration: BoxDecoration(
//         color: AppColors.surface,
//         borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
//         border: Border.all(color: AppColors.borderFaint),
//         boxShadow: AppColors.cardShadow,
//       ),
//       child: Row(
//         children: [
//           Container(
//             width: 30,
//             height: 30,
//             decoration: BoxDecoration(
//               color: AppColors.mutedInk.withValues(alpha: 0.07),
//               borderRadius: BorderRadius.circular(10),
//             ),
//             child: Icon(icon, color: AppColors.mutedInk, size: 16),
//           ),
//           const SizedBox(width: AppSpacing.sm),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   context.tr(titleKey),
//                   style: Theme.of(context).textTheme.titleMedium,
//                 ),
//                 const SizedBox(height: 3),
//                 Text(
//                   context.tr(bodyKey),
//                   maxLines: 2,
//                   overflow: TextOverflow.ellipsis,
//                   style: Theme.of(context).textTheme.bodySmall,
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
