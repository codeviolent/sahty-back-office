import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/app_text_key.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/status_badge.dart';

abstract final class _MessagingLayout {
  static const double filterWidth = 132;
  static const double listWidth = 280;
  static const double contextWidth = 220;
  static const double threadHeight = 78;

  static double workspaceHeightFor(BuildContext context) {
    const shellDividerHeight = 1.0;
    final reservedHeight =
        AppSpacing.topBarHeight +
        shellDividerHeight +
        (AppSpacing.shellInset * 2) +
        (AppSpacing.xl * 2);
    final availableHeight = MediaQuery.sizeOf(context).height - reservedHeight;
    return availableHeight < 520 ? 520 : availableHeight;
  }
}

void _showMessagingAction(BuildContext context, String label) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(label),
        duration: const Duration(milliseconds: 1100),
      ),
    );
}

abstract final class _MessagingMock {
  static const threads = [
    _ThreadData(
      titleKey: AppTextKey.messagingThreadPatient,
      previewKey: AppTextKey.messagingPatientPreview,
      stateKey: AppTextKey.messagingThreadUnread,
      icon: Icons.person_outline,
      time: '09:42',
      unread: true,
      selected: true,
    ),
    _ThreadData(
      titleKey: AppTextKey.messagingThreadTeam,
      previewKey: AppTextKey.messagingTeamPreview,
      stateKey: AppTextKey.messagingThreadRead,
      icon: Icons.groups_outlined,
      time: '08:15',
    ),
    _ThreadData(
      titleKey: AppTextKey.messagingThreadPinned,
      previewKey: AppTextKey.messagingPinnedPreview,
      stateKey: AppTextKey.messagingPinned,
      icon: Icons.push_pin_outlined,
      time: 'Hier',
      pinned: true,
    ),
  ];

  static const messages = [
    _MessageData(
      bodyKey: AppTextKey.messagingMessagePatient,
      author: 'Mariam',
      time: '09:42',
      critical: true,
    ),
    _MessageData(
      bodyKey: AppTextKey.messagingMessageDoctor,
      author: 'Dr. Nichols',
      time: '09:45',
      mine: true,
    ),
    _MessageData(
      bodyKey: AppTextKey.messagingMessageTeam,
      author: 'Care team',
      time: '09:48',
    ),
  ];
}

class _ThreadData {
  const _ThreadData({
    required this.titleKey,
    required this.previewKey,
    required this.stateKey,
    required this.icon,
    required this.time,
    this.unread = false,
    this.pinned = false,
    this.selected = false,
  });

  final AppTextKey titleKey;
  final AppTextKey previewKey;
  final AppTextKey stateKey;
  final IconData icon;
  final String time;
  final bool unread;
  final bool pinned;
  final bool selected;
}

class _MessageData {
  const _MessageData({
    required this.bodyKey,
    required this.author,
    required this.time,
    this.mine = false,
    this.critical = false,
  });

  final AppTextKey bodyKey;
  final String author;
  final String time;
  final bool mine;
  final bool critical;
}

class MessagingScreen extends StatelessWidget {
  const MessagingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [const _MessagingWorkspace()],
    );
  }
}

class _MessagingWorkspace extends StatelessWidget {
  const _MessagingWorkspace();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _MessagingLayout.workspaceHeightFor(context),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(width: _MessagingLayout.filterWidth, child: _InboxRail()),
          VerticalDivider(width: 1),
          SizedBox(width: _MessagingLayout.listWidth, child: _ThreadListPane()),
          VerticalDivider(width: 1),
          Expanded(child: _ChatPane()),
          VerticalDivider(width: 1),
          SizedBox(
            width: _MessagingLayout.contextWidth,
            child: _ConversationContextPanel(),
          ),
        ],
      ),
    );
  }
}

class _InboxRail extends StatelessWidget {
  const _InboxRail();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.canvas.withValues(alpha: 0.55),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _RailTitle(label: context.tr(AppTextKey.messagingInboxTitle)),
            const SizedBox(height: AppSpacing.md),
            _RailFilter(
              icon: Icons.inbox_outlined,
              label: context.tr(AppTextKey.messagingAllFilter),
              count: '3',
              active: true,
            ),
            const SizedBox(height: AppSpacing.xs),
            _RailFilter(
              icon: Icons.assignment_ind_outlined,
              label: context.tr(AppTextKey.messagingAssignedFilter),
              count: '1',
            ),
            const SizedBox(height: AppSpacing.xs),
            _RailFilter(
              icon: Icons.push_pin_outlined,
              label: context.tr(AppTextKey.messagingPinned),
              count: '1',
            ),
            const SizedBox(height: AppSpacing.lg),
            const Divider(),
            const SizedBox(height: AppSpacing.md),
            _RailTitle(label: context.tr(AppTextKey.messagingThreadsTitle)),
            const SizedBox(height: AppSpacing.sm),
            StatusBadge(
              label: context.tr(AppTextKey.messagingClinicalPriority),
              tone: BadgeTone.primary,
            ),
            const SizedBox(height: AppSpacing.sm),
            StatusBadge(
              label: context.tr(AppTextKey.messagingEncrypted),
              tone: BadgeTone.neutral,
              icon: Icons.lock_outline,
            ),
            const SizedBox(height: AppSpacing.xxl),
            _RailFilter(
              icon: Icons.archive_outlined,
              label: context.tr(AppTextKey.messagingLegalHold),
              count: 'On',
            ),
          ],
        ),
      ),
    );
  }
}

class _RailTitle extends StatelessWidget {
  const _RailTitle({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: AppColors.placeholder,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.6,
      ),
    );
  }
}

class _RailFilter extends StatelessWidget {
  const _RailFilter({
    required this.icon,
    required this.label,
    required this.count,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final String count;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: () => _showMessagingAction(context, label),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs + 1,
          ),
          decoration: BoxDecoration(
            color: active ? AppColors.primary.withValues(alpha: 0.08) : null,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: active ? AppColors.primary : AppColors.mutedInk,
                size: 15,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: active ? AppColors.ink : AppColors.mutedInk,
                    fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
              Text(
                count,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: active ? AppColors.primary : AppColors.placeholder,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThreadListPane extends StatelessWidget {
  const _ThreadListPane();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  context.tr(AppTextKey.messagingThreadsTitle),
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              StatusBadge(
                label: context.tr(AppTextKey.messagingThreadUnread),
                tone: BadgeTone.critical,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const _SearchStub(),
          const SizedBox(height: AppSpacing.md),
          const _MessagingSecurityStrip(),
          const SizedBox(height: AppSpacing.md),
          for (int i = 0; i < _MessagingMock.threads.length; i++) ...[
            _ThreadTile(thread: _MessagingMock.threads[i]),
            if (i < _MessagingMock.threads.length - 1)
              const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _SearchStub extends StatelessWidget {
  const _SearchStub();

  @override
  Widget build(BuildContext context) {
    final label = context.tr(AppTextKey.messagingSearchHint);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: () => _showMessagingAction(context, label),
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.canvas.withValues(alpha: 0.60),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: AppColors.borderFaint),
          ),
          child: Row(
            children: [
              const Icon(Icons.search, size: 15, color: AppColors.placeholder),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.placeholder,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatPane extends StatelessWidget {
  const _ChatPane();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _ThreadContextBar(),
        Expanded(
          child: ColoredBox(
            color: AppColors.canvas.withValues(alpha: 0.50),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  _DayDivider(
                    label: context.tr(AppTextKey.messagingTodayDivider),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  for (int i = 0; i < _MessagingMock.messages.length; i++) ...[
                    _MessageBubble(message: _MessagingMock.messages[i]),
                    if (i == 0) ...[
                      const SizedBox(height: AppSpacing.sm),
                      _AttachmentRail(
                        attachments: const [
                          _AttachmentSpec(
                            icon: Icons.picture_as_pdf_outlined,
                            labelKey: AppTextKey.messagingAttachmentLab,
                            tone: AppColors.critical,
                          ),
                        ],
                      ),
                    ],
                    if (i < _MessagingMock.messages.length - 1)
                      const SizedBox(height: AppSpacing.md),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  _AttachmentRail(
                    attachments: const [
                      _AttachmentSpec(
                        icon: Icons.image_outlined,
                        labelKey: AppTextKey.messagingAttachmentImage,
                        tone: AppColors.info,
                      ),
                    ],
                    alignEnd: true,
                  ),
                ],
              ),
            ),
          ),
        ),
        const _MessageComposer(),
      ],
    );
  }
}

class _ConversationContextPanel extends StatelessWidget {
  const _ConversationContextPanel();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.canvas.withValues(alpha: 0.35),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: Text(
                context.tr(AppTextKey.messagingThreadPatient),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Center(
              child: Text(
                context.tr(AppTextKey.messagingPatientMeta),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.mutedInk,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: StatusBadge(
                label: context.tr(AppTextKey.messagingOnlineStatus),
                tone: BadgeTone.normal,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Divider(),
            const SizedBox(height: AppSpacing.md),
            _PanelSectionTitle(
              label: context.tr(AppTextKey.messagingArchiveTitle),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              context.tr(AppTextKey.messagingArchiveBody),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.mutedInk,
                height: 1.42,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _ArchiveSignal(
              icon: Icons.history_edu_outlined,
              label: context.tr(AppTextKey.messagingArchiveRetention),
            ),
            const SizedBox(height: AppSpacing.sm),
            _ArchiveSignal(
              icon: Icons.admin_panel_settings_outlined,
              label: context.tr(AppTextKey.messagingArchiveAccess),
            ),
            const SizedBox(height: AppSpacing.md),
            StatusBadge(
              label: context.tr(AppTextKey.messagingLegalHold),
              tone: BadgeTone.neutral,
              icon: Icons.archive_outlined,
            ),
          ],
        ),
      ),
    );
  }
}

class _PanelSectionTitle extends StatelessWidget {
  const _PanelSectionTitle({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: AppColors.ink,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _MessagingSecurityStrip extends StatelessWidget {
  const _MessagingSecurityStrip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm + 2),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.13)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SecurityItem(
              icon: Icons.lock_outline,
              label: context.tr(AppTextKey.messagingEncrypted),
            ),
          ),
          Container(width: 1, height: 22, color: AppColors.borderFaint),
          Expanded(
            child: _SecurityItem(
              icon: Icons.fact_check_outlined,
              label: context.tr(AppTextKey.messagingAuditTrail),
            ),
          ),
        ],
      ),
    );
  }
}

class _SecurityItem extends StatelessWidget {
  const _SecurityItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 14, color: AppColors.primary),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _ThreadTile extends StatelessWidget {
  const _ThreadTile({required this.thread});

  final _ThreadData thread;

  @override
  Widget build(BuildContext context) {
    final tone = thread.unread ? AppColors.critical : AppColors.primary;
    final background = thread.selected
        ? AppColors.primary.withValues(alpha: 0.075)
        : AppColors.surface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        onTap: () => _showMessagingAction(context, context.tr(thread.titleKey)),
        child: Container(
          height: _MessagingLayout.threadHeight,
          padding: const EdgeInsets.all(AppSpacing.sm + 2),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(
              color: thread.selected
                  ? AppColors.primary.withValues(alpha: 0.22)
                  : AppColors.borderFaint,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: tone.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(thread.icon, color: tone, size: 18),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            context.tr(thread.titleKey),
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.ink,
                                ),
                          ),
                        ),
                        if (thread.pinned) ...[
                          const SizedBox(width: AppSpacing.xs),
                          const Icon(
                            Icons.push_pin_rounded,
                            color: AppColors.primary,
                            size: 13,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      context.tr(thread.previewKey),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.mutedInk,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    thread.time,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.placeholder,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  StatusBadge(
                    label: context.tr(thread.stateKey),
                    tone: thread.unread
                        ? BadgeTone.critical
                        : BadgeTone.neutral,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThreadContextBar extends StatelessWidget {
  const _ThreadContextBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.person_outline,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr(AppTextKey.messagingThreadPatient),
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.tr(AppTextKey.messagingPatientMeta),
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.mutedInk,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          StatusBadge(
            label: context.tr(AppTextKey.messagingOnlineStatus),
            tone: BadgeTone.normal,
          ),
          const SizedBox(width: AppSpacing.sm),
          StatusBadge(
            label: context.tr(AppTextKey.messagingEncrypted),
            tone: BadgeTone.primary,
            icon: Icons.lock_outline,
          ),
        ],
      ),
    );
  }
}

class _DayDivider extends StatelessWidget {
  const _DayDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.placeholder,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final _MessageData message;

  @override
  Widget build(BuildContext context) {
    final tone = message.critical ? AppColors.critical : AppColors.primary;
    return Align(
      alignment: message.mine
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + 2,
          ),
          decoration: BoxDecoration(
            color: message.mine
                ? AppColors.primary.withValues(alpha: 0.09)
                : AppColors.surface,
            borderRadius: BorderRadiusDirectional.only(
              topStart: const Radius.circular(AppSpacing.cardRadius),
              topEnd: const Radius.circular(AppSpacing.cardRadius),
              bottomStart: Radius.circular(
                message.mine ? AppSpacing.cardRadius : 4,
              ),
              bottomEnd: Radius.circular(
                message.mine ? 4 : AppSpacing.cardRadius,
              ),
            ),
            border: Border.all(
              color: message.critical
                  ? AppColors.critical.withValues(alpha: 0.20)
                  : AppColors.borderFaint,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: tone,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      message.author,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: tone,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Text(
                    message.time,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.placeholder,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                context.tr(message.bodyKey),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.ink,
                  height: 1.42,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AttachmentSpec {
  const _AttachmentSpec({
    required this.icon,
    required this.labelKey,
    required this.tone,
  });

  final IconData icon;
  final AppTextKey labelKey;
  final Color tone;
}

class _AttachmentRail extends StatelessWidget {
  const _AttachmentRail({required this.attachments, this.alignEnd = false});

  final List<_AttachmentSpec> attachments;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignEnd
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          children: [
            for (int i = 0; i < attachments.length; i++) ...[
              _AttachmentTile(
                icon: attachments[i].icon,
                labelKey: attachments[i].labelKey,
                tone: attachments[i].tone,
              ),
              if (i < attachments.length - 1)
                const SizedBox(height: AppSpacing.sm),
            ],
          ],
        ),
      ),
    );
  }
}

class _AttachmentTile extends StatelessWidget {
  const _AttachmentTile({
    required this.icon,
    required this.labelKey,
    required this.tone,
  });

  final IconData icon;
  final AppTextKey labelKey;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    final label = context.tr(labelKey);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        onTap: () => _showMessagingAction(context, label),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + 2,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(color: AppColors.borderFaint),
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: tone.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: tone, size: 16),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              StatusBadge(
                label: context.tr(AppTextKey.messagingAttachmentLocked),
                tone: BadgeTone.neutral,
                icon: Icons.lock_outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageComposer extends StatelessWidget {
  const _MessageComposer();

  @override
  Widget build(BuildContext context) {
    final attachLabel = context.tr(AppTextKey.messagingAttachmentTitle);
    final sendLabel = context.tr(AppTextKey.messagingSendAction);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(color: AppColors.borderFaint),
        ),
        child: Row(
          children: [
            IconButton(
              tooltip: attachLabel,
              onPressed: () => _showMessagingAction(context, attachLabel),
              icon: const Icon(Icons.attach_file_rounded, size: 18),
              visualDensity: VisualDensity.compact,
              color: AppColors.mutedInk,
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.canvas.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  context.tr(AppTextKey.messagingComposeHint),
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.placeholder,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            FilledButton.icon(
              onPressed: () => _showMessagingAction(context, sendLabel),
              icon: const Icon(Icons.send_rounded, size: 15),
              label: Text(sendLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArchiveSignal extends StatelessWidget {
  const _ArchiveSignal({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        onTap: () => _showMessagingAction(context, label),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm + 2),
          decoration: BoxDecoration(
            color: AppColors.canvas.withValues(alpha: 0.60),
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(color: AppColors.borderFaint),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 16),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
