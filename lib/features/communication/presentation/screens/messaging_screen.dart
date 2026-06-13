import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/app_text_key.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../data/models/messaging_models.dart';
import '../bloc/messaging_bloc.dart';
import '../bloc/messaging_event.dart';
import '../bloc/messaging_state.dart';

// ══════════════════════════════════════════════════════════════════
// Layout — identique à l'original
// ══════════════════════════════════════════════════════════════════
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

// ══════════════════════════════════════════════════════════════════
// Screen principal
// ══════════════════════════════════════════════════════════════════
class MessagingScreen extends StatefulWidget {
  const MessagingScreen({super.key});
  @override
  State<MessagingScreen> createState() => _MessagingScreenState();
}

class _MessagingScreenState extends State<MessagingScreen> {
  @override
  void initState() {
    super.initState();
    context.read<MessagingBloc>().add(MessagingLoadConversations());
  }

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [_MessagingWorkspace()],
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Workspace — structure identique à l'original
// ══════════════════════════════════════════════════════════════════
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

// ══════════════════════════════════════════════════════════════════
// Rail gauche — compteurs réels
// ══════════════════════════════════════════════════════════════════
class _InboxRail extends StatelessWidget {
  const _InboxRail();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MessagingBloc, MessagingState>(
      buildWhen: (p, n) =>
          p.conversations.length != n.conversations.length ||
          p.totalUnread != n.totalUnread,
      builder: (ctx, state) {
        final total = state.conversations.length;
        final unread = state.totalUnread;

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
                  count: total.toString(),
                  active: true,
                ),
                const SizedBox(height: AppSpacing.xs),
                _RailFilter(
                  icon: Icons.mark_email_unread_outlined,
                  label: context.tr(AppTextKey.messagingAssignedFilter),
                  count: unread.toString(),
                ),
                const SizedBox(height: AppSpacing.xs),
                _RailFilter(
                  icon: Icons.push_pin_outlined,
                  label: context.tr(AppTextKey.messagingPinned),
                  count: '0',
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
      },
    );
  }
}

class _RailTitle extends StatelessWidget {
  final String label;
  const _RailTitle({required this.label});

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
  final IconData icon;
  final String label;
  final String count;
  final bool active;
  const _RailFilter({
    required this.icon,
    required this.label,
    required this.count,
    this.active = false,
  });

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

// ══════════════════════════════════════════════════════════════════
// Liste des conversations
// ══════════════════════════════════════════════════════════════════
class _ThreadListPane extends StatelessWidget {
  const _ThreadListPane();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MessagingBloc, MessagingState>(
      buildWhen: (p, n) =>
          p.conversations != n.conversations ||
          p.selectedConversationId != n.selectedConversationId ||
          p.isLoadingConversations != n.isLoadingConversations ||
          p.totalUnread != n.totalUnread,
      builder: (ctx, state) {
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête
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
                  if (state.totalUnread > 0)
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

              // Chargement
              if (state.isLoadingConversations)
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 2.5,
                    ),
                  ),
                ),

              // Erreur
              if (!state.isLoadingConversations && state.error != null)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 36,
                          color: AppColors.mutedInk,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          state.error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.mutedInk,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextButton(
                          onPressed: () =>
                              ctx.read<MessagingBloc>().add(MessagingRefresh()),
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  ),
                ),

              // Conversations réelles — même visuel que _ThreadTile original
              if (!state.isLoadingConversations && state.error == null)
                ...(state.conversations.isEmpty
                    ? [
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.only(top: AppSpacing.xl),
                            child: Text(
                              'Aucune conversation',
                              style: TextStyle(
                                color: AppColors.mutedInk,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ]
                    : state.conversations.asMap().entries.map((e) {
                        final conv = e.value;
                        final selected =
                            conv.id == state.selectedConversationId;
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: e.key < state.conversations.length - 1
                                ? AppSpacing.sm
                                : 0,
                          ),
                          child: _ConversationTile(
                            conversation: conv,
                            selected: selected,
                            onTap: () => ctx.read<MessagingBloc>().add(
                              MessagingSelectConversation(conv.id),
                            ),
                          ),
                        );
                      }).toList()),
            ],
          ),
        );
      },
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
  final IconData icon;
  final String label;
  const _SecurityItem({required this.icon, required this.label});

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

// ── Tuile conversation — même visuel que _ThreadTile original ──────
class _ConversationTile extends StatelessWidget {
  final ConversationItem conversation;
  final bool selected;
  final VoidCallback onTap;
  const _ConversationTile({
    required this.conversation,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasUnread = conversation.hasUnread;
    final tone = hasUnread ? AppColors.critical : AppColors.primary;
    final background = selected
        ? AppColors.primary.withValues(alpha: 0.075)
        : AppColors.surface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        onTap: onTap,
        child: Container(
          height: _MessagingLayout.threadHeight,
          padding: const EdgeInsets.all(AppSpacing.sm + 2),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.22)
                  : AppColors.borderFaint,
            ),
          ),
          child: Row(
            children: [
              // Avatar initiales (même style que l'icône original)
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: tone.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    conversation.patient.initials,
                    style: TextStyle(
                      color: tone,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),

              // Nom + preview
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      conversation.patient.displayName,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      conversation.lastMessagePreview,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: hasUnread ? AppColors.ink : AppColors.mutedInk,
                        fontWeight: hasUnread
                            ? FontWeight.w700
                            : FontWeight.w400,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),

              // Temps + badge
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    conversation.formattedTime,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.placeholder,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  StatusBadge(
                    label: hasUnread ? 'Non lu' : 'Lu',
                    tone: hasUnread ? BadgeTone.critical : BadgeTone.neutral,
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

// ══════════════════════════════════════════════════════════════════
// Panneau chat
// ══════════════════════════════════════════════════════════════════
class _ChatPane extends StatelessWidget {
  const _ChatPane();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MessagingBloc, MessagingState>(
      buildWhen: (p, n) =>
          p.selectedConversationId != n.selectedConversationId ||
          p.messages.length != n.messages.length ||
          p.isLoadingMessages != n.isLoadingMessages ||
          p.isSending != n.isSending ||
          p.sendError != n.sendError,
      builder: (ctx, state) {
        // Aucune conversation sélectionnée
        if (state.selectedConversationId == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 32,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const Text(
                    'Sélectionnez une conversation',
                    style: TextStyle(color: AppColors.mutedInk, fontSize: 13),
                  ),
                ],
              ),
            ),
          );
        }

        final conv = state.selectedConversation;
        if (conv == null) return const SizedBox.shrink();

        return Column(
          children: [
            // Barre contexte thread — même structure que l'original
            _ThreadContextBar(conversation: conv),

            // Zone messages
            Expanded(
              child: ColoredBox(
                color: AppColors.canvas.withValues(alpha: 0.50),
                child: state.isLoadingMessages
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                          strokeWidth: 2.5,
                        ),
                      )
                    : _MessageListView(
                        messages: state.messages,
                        doctorName:
                            'Dr. ${conv.patient.displayName.split(" ").last}',
                      ),
              ),
            ),

            // Composer
            _MessageComposer(
              conversationId: state.selectedConversationId!,
              isSending: state.isSending,
              sendError: state.sendError,
            ),
          ],
        );
      },
    );
  }
}

// ── Barre contexte thread — même visuel que l'original ────────────

class _ThreadContextBar extends StatelessWidget {
  final ConversationItem conversation;
  const _ThreadContextBar({required this.conversation});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderFaint)),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Avatar initiales ──────────────────────────────────
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                conversation.patient.initials,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),

          // ── Infos patient — Expanded prend tout l'espace ──────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  conversation.patient.displayName,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'GS: ${conversation.patient.bloodType}'
                  '  ·  ${conversation.patient.phone}',
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

          // ── Indicateurs compacts (icônes seules, pas de badges) ──
          // Remplace les 2 StatusBadge larges qui causaient l'overflow
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: const Color(0xFF158034).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.circle,
                  size: 8,
                  color: Color(0xFF158034),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.lock_outline,
                  size: 14,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
// class _ThreadContextBar extends StatelessWidget {
//   final ConversationItem conversation;
//   const _ThreadContextBar({required this.conversation});

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(
//         horizontal: AppSpacing.lg, vertical: AppSpacing.md),
//       child: Row(children: [
//         Container(
//           width: 38, height: 38,
//           decoration: BoxDecoration(
//             color:        AppColors.primary.withValues(alpha: 0.10),
//             borderRadius: BorderRadius.circular(12)),
//           child: Center(child: Text(conversation.patient.initials,
//             style: const TextStyle(
//               color: AppColors.primary, fontSize: 14,
//               fontWeight: FontWeight.w900)))),
//         const SizedBox(width: AppSpacing.md),
//         Expanded(child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(conversation.patient.displayName, overflow: TextOverflow.ellipsis,
//               style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                 color: AppColors.ink, fontWeight: FontWeight.w900)),
//             const SizedBox(height: 2),
//             Text('GS: ${conversation.patient.bloodType}  ·  '
//                 '${conversation.patient.phone}',
//               overflow: TextOverflow.ellipsis,
//               style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                 color: AppColors.mutedInk, fontWeight: FontWeight.w600)),
//           ],
//         )),
//         const SizedBox(width: AppSpacing.sm),
//         StatusBadge(
//           label: context.tr(AppTextKey.messagingOnlineStatus),
//           tone:  BadgeTone.normal),
//         const SizedBox(width: AppSpacing.sm),
//         StatusBadge(
//           label: context.tr(AppTextKey.messagingEncrypted),
//           tone:  BadgeTone.primary,
//           icon:  Icons.lock_outline),
//       ]),
//     );
//   }
// }

// ── Liste des messages ─────────────────────────────────────────────
class _MessageListView extends StatefulWidget {
  final List<MessageItem> messages;
  final String doctorName;
  const _MessageListView({required this.messages, required this.doctorName});

  @override
  State<_MessageListView> createState() => _MessageListViewState();
}

class _MessageListViewState extends State<_MessageListView> {
  final _scrollController = ScrollController();

  @override
  void didUpdateWidget(_MessageListView old) {
    super.didUpdateWidget(old);
    // Scroll automatique vers le bas quand nouveau message
    if (widget.messages.length != old.messages.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.messages.isEmpty) {
      return const Center(
        child: Text(
          'Aucun message',
          style: TextStyle(color: AppColors.mutedInk, fontSize: 13),
        ),
      );
    }

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          // Séparateur date — même visuel que _DayDivider original
          _DayDivider(label: _dayLabel(widget.messages.first.createdAt)),
          const SizedBox(height: AppSpacing.md),

          // Messages
          ...widget.messages.asMap().entries.map((e) {
            final i = e.key;
            final msg = e.value;
            final showDate =
                i > 0 &&
                msg.createdAt.day != widget.messages[i - 1].createdAt.day;
            return Column(
              children: [
                if (showDate) ...[
                  const SizedBox(height: AppSpacing.md),
                  _DayDivider(label: _dayLabel(msg.createdAt)),
                  const SizedBox(height: AppSpacing.md),
                ],
                // Même visuel que _MessageBubble original — adapté à MessageItem
                _RealMessageBubble(message: msg, doctorName: widget.doctorName),
                if (i < widget.messages.length - 1)
                  const SizedBox(height: AppSpacing.md),
              ],
            );
          }),
        ],
      ),
    );
  }

  String _dayLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(dt.year, dt.month, dt.day);
    if (d == today) return "Aujourd'hui";
    if (d == today.subtract(const Duration(days: 1))) return 'Hier';
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }
}

// ── Divider jour — identique à l'original ─────────────────────────
class _DayDivider extends StatelessWidget {
  final String label;
  const _DayDivider({required this.label});

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

// ── Bulle message réelle — même visuel que _MessageBubble original ─
class _RealMessageBubble extends StatelessWidget {
  final MessageItem message;
  final String doctorName;
  const _RealMessageBubble({required this.message, required this.doctorName});

  @override
  Widget build(BuildContext context) {
    final isDoctor = message.isFromDoctor;
    final tone = AppColors.primary;

    return Align(
      alignment: isDoctor
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
            color: isDoctor
                ? AppColors.primary.withValues(alpha: 0.09)
                : AppColors.surface,
            borderRadius: BorderRadiusDirectional.only(
              topStart: const Radius.circular(AppSpacing.cardRadius),
              topEnd: const Radius.circular(AppSpacing.cardRadius),
              bottomStart: Radius.circular(
                isDoctor ? AppSpacing.cardRadius : 4,
              ),
              bottomEnd: Radius.circular(isDoctor ? 4 : AppSpacing.cardRadius),
            ),
            border: Border.all(color: AppColors.borderFaint),
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
                      isDoctor ? doctorName : 'Patient',
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: tone,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Text(
                    message.formattedTime,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.placeholder,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                message.content,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.ink,
                  height: 1.42,
                ),
              ),
              // Statut lu/non-lu pour les messages du médecin
              if (isDoctor)
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Icon(
                      message.isRead
                          ? Icons.done_all_rounded
                          : Icons.done_rounded,
                      size: 13,
                      color: message.isRead
                          ? AppColors.primary
                          : AppColors.placeholder,
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

// ── Composer — même visuel que l'original + envoi réel ────────────
class _MessageComposer extends StatefulWidget {
  final int conversationId;
  final bool isSending;
  final String? sendError;
  const _MessageComposer({
    required this.conversationId,
    required this.isSending,
    this.sendError,
  });
  @override
  State<_MessageComposer> createState() => _MessageComposerState();
}

class _MessageComposerState extends State<_MessageComposer> {
  final _ctrl = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() {
      final hasText = _ctrl.text.trim().isNotEmpty;
      if (hasText != _hasText) setState(() => _hasText = hasText);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _send() {
    final content = _ctrl.text.trim();
    if (content.isEmpty || widget.isSending) return;
    _ctrl.clear();
    context.read<MessagingBloc>().add(
      MessagingSendMessage(
        conversationId: widget.conversationId,
        content: content,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final attachLabel = context.tr(AppTextKey.messagingAttachmentTitle);
    final sendLabel = context.tr(AppTextKey.messagingSendAction);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Erreur d'envoi
        if (widget.sendError != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            color: AppColors.critical.withValues(alpha: 0.08),
            child: Text(
              widget.sendError!,
              style: const TextStyle(color: AppColors.critical, fontSize: 12),
            ),
          ),

        // Composer — même visuel que l'original
        Padding(
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
                // TextField réel à la place du Text stub de l'original
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
                    child: TextField(
                      controller: _ctrl,
                      maxLines: 3,
                      minLines: 1,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: context.tr(AppTextKey.messagingComposeHint),
                        hintStyle: const TextStyle(
                          color: AppColors.placeholder,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                // Bouton envoi — même visuel, onPressed réel
                FilledButton.icon(
                  onPressed: (_hasText && !widget.isSending) ? _send : null,
                  icon: widget.isSending
                      ? const SizedBox(
                          width: 15,
                          height: 15,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.send_rounded, size: 15),
                  label: Text(sendLabel),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Panneau contexte droite
// ══════════════════════════════════════════════════════════════════
class _ConversationContextPanel extends StatelessWidget {
  const _ConversationContextPanel();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MessagingBloc, MessagingState>(
      buildWhen: (p, n) => p.selectedConversationId != n.selectedConversationId,
      builder: (ctx, state) {
        final conv = state.selectedConversation;

        return ColoredBox(
          color: AppColors.canvas.withValues(alpha: 0.35),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: conv == null
                // Aucune sélection — afficher l'UI d'origine
                ? _DefaultContextPanel()
                // Conversation sélectionnée — infos réelles du patient
                : _PatientContextPanel(conversation: conv),
          ),
        );
      },
    );
  }
}

// ── Panneau par défaut (aucune sélection) — identique à l'original ─
class _DefaultContextPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
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
        _PanelSectionTitle(label: context.tr(AppTextKey.messagingArchiveTitle)),
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
    );
  }
}

// ── Panneau patient sélectionné — même visuel, données réelles ─────
class _PatientContextPanel extends StatelessWidget {
  final ConversationItem conversation;
  const _PatientContextPanel({required this.conversation});

  @override
  Widget build(BuildContext context) {
    final patient = conversation.patient;
    return Column(
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
            child: Center(
              child: Text(
                patient.initials,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Center(
          child: Text(
            patient.displayName,
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
            'GS: ${patient.bloodType}  ·  ${patient.phone}',
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
        _PanelSectionTitle(label: context.tr(AppTextKey.messagingArchiveTitle)),
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
    );
  }
}

class _PanelSectionTitle extends StatelessWidget {
  final String label;
  const _PanelSectionTitle({required this.label});

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

class _ArchiveSignal extends StatelessWidget {
  final IconData icon;
  final String label;
  const _ArchiveSignal({required this.icon, required this.label});

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

// import 'package:flutter/material.dart';

// import '../../../../core/l10n/app_localizations.dart';
// import '../../../../core/l10n/app_text_key.dart';
// import '../../../../core/theme/app_colors.dart';
// import '../../../../core/theme/app_spacing.dart';
// import '../../../../core/widgets/status_badge.dart';

// abstract final class _MessagingLayout {
//   static const double filterWidth = 132;
//   static const double listWidth = 280;
//   static const double contextWidth = 220;
//   static const double threadHeight = 78;

//   static double workspaceHeightFor(BuildContext context) {
//     const shellDividerHeight = 1.0;
//     final reservedHeight =
//         AppSpacing.topBarHeight +
//         shellDividerHeight +
//         (AppSpacing.shellInset * 2) +
//         (AppSpacing.xl * 2);
//     final availableHeight = MediaQuery.sizeOf(context).height - reservedHeight;
//     return availableHeight < 520 ? 520 : availableHeight;
//   }
// }

// void _showMessagingAction(BuildContext context, String label) {
//   ScaffoldMessenger.of(context)
//     ..hideCurrentSnackBar()
//     ..showSnackBar(
//       SnackBar(
//         content: Text(label),
//         duration: const Duration(milliseconds: 1100),
//       ),
//     );
// }

// abstract final class _MessagingMock {
//   static const threads = [
//     _ThreadData(
//       titleKey: AppTextKey.messagingThreadPatient,
//       previewKey: AppTextKey.messagingPatientPreview,
//       stateKey: AppTextKey.messagingThreadUnread,
//       icon: Icons.person_outline,
//       time: '09:42',
//       unread: true,
//       selected: true,
//     ),
//     _ThreadData(
//       titleKey: AppTextKey.messagingThreadTeam,
//       previewKey: AppTextKey.messagingTeamPreview,
//       stateKey: AppTextKey.messagingThreadRead,
//       icon: Icons.groups_outlined,
//       time: '08:15',
//     ),
//     _ThreadData(
//       titleKey: AppTextKey.messagingThreadPinned,
//       previewKey: AppTextKey.messagingPinnedPreview,
//       stateKey: AppTextKey.messagingPinned,
//       icon: Icons.push_pin_outlined,
//       time: 'Hier',
//       pinned: true,
//     ),
//   ];

//   static const messages = [
//     _MessageData(
//       bodyKey: AppTextKey.messagingMessagePatient,
//       author: 'Mariam',
//       time: '09:42',
//       critical: true,
//     ),
//     _MessageData(
//       bodyKey: AppTextKey.messagingMessageDoctor,
//       author: 'Dr. Nichols',
//       time: '09:45',
//       mine: true,
//     ),
//     _MessageData(
//       bodyKey: AppTextKey.messagingMessageTeam,
//       author: 'Care team',
//       time: '09:48',
//     ),
//   ];
// }

// class _ThreadData {
//   const _ThreadData({
//     required this.titleKey,
//     required this.previewKey,
//     required this.stateKey,
//     required this.icon,
//     required this.time,
//     this.unread = false,
//     this.pinned = false,
//     this.selected = false,
//   });

//   final AppTextKey titleKey;
//   final AppTextKey previewKey;
//   final AppTextKey stateKey;
//   final IconData icon;
//   final String time;
//   final bool unread;
//   final bool pinned;
//   final bool selected;
// }

// class _MessageData {
//   const _MessageData({
//     required this.bodyKey,
//     required this.author,
//     required this.time,
//     this.mine = false,
//     this.critical = false,
//   });

//   final AppTextKey bodyKey;
//   final String author;
//   final String time;
//   final bool mine;
//   final bool critical;
// }

// class MessagingScreen extends StatelessWidget {
//   const MessagingScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [const _MessagingWorkspace()],
//     );
//   }
// }

// class _MessagingWorkspace extends StatelessWidget {
//   const _MessagingWorkspace();

//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       height: _MessagingLayout.workspaceHeightFor(context),
//       child: const Row(
//         crossAxisAlignment: CrossAxisAlignment.stretch,
//         children: [
//           SizedBox(width: _MessagingLayout.filterWidth, child: _InboxRail()),
//           VerticalDivider(width: 1),
//           SizedBox(width: _MessagingLayout.listWidth, child: _ThreadListPane()),
//           VerticalDivider(width: 1),
//           Expanded(child: _ChatPane()),
//           VerticalDivider(width: 1),
//           SizedBox(
//             width: _MessagingLayout.contextWidth,
//             child: _ConversationContextPanel(),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _InboxRail extends StatelessWidget {
//   const _InboxRail();

//   @override
//   Widget build(BuildContext context) {
//     return ColoredBox(
//       color: AppColors.canvas.withValues(alpha: 0.55),
//       child: Padding(
//         padding: const EdgeInsets.all(AppSpacing.md),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _RailTitle(label: context.tr(AppTextKey.messagingInboxTitle)),
//             const SizedBox(height: AppSpacing.md),
//             _RailFilter(
//               icon: Icons.inbox_outlined,
//               label: context.tr(AppTextKey.messagingAllFilter),
//               count: '3',
//               active: true,
//             ),
//             const SizedBox(height: AppSpacing.xs),
//             _RailFilter(
//               icon: Icons.assignment_ind_outlined,
//               label: context.tr(AppTextKey.messagingAssignedFilter),
//               count: '1',
//             ),
//             const SizedBox(height: AppSpacing.xs),
//             _RailFilter(
//               icon: Icons.push_pin_outlined,
//               label: context.tr(AppTextKey.messagingPinned),
//               count: '1',
//             ),
//             const SizedBox(height: AppSpacing.lg),
//             const Divider(),
//             const SizedBox(height: AppSpacing.md),
//             _RailTitle(label: context.tr(AppTextKey.messagingThreadsTitle)),
//             const SizedBox(height: AppSpacing.sm),
//             StatusBadge(
//               label: context.tr(AppTextKey.messagingClinicalPriority),
//               tone: BadgeTone.primary,
//             ),
//             const SizedBox(height: AppSpacing.sm),
//             StatusBadge(
//               label: context.tr(AppTextKey.messagingEncrypted),
//               tone: BadgeTone.neutral,
//               icon: Icons.lock_outline,
//             ),
//             const SizedBox(height: AppSpacing.xxl),
//             _RailFilter(
//               icon: Icons.archive_outlined,
//               label: context.tr(AppTextKey.messagingLegalHold),
//               count: 'On',
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _RailTitle extends StatelessWidget {
//   const _RailTitle({required this.label});

//   final String label;

//   @override
//   Widget build(BuildContext context) {
//     return Text(
//       label.toUpperCase(),
//       overflow: TextOverflow.ellipsis,
//       style: Theme.of(context).textTheme.labelSmall?.copyWith(
//         color: AppColors.placeholder,
//         fontWeight: FontWeight.w900,
//         letterSpacing: 0.6,
//       ),
//     );
//   }
// }

// class _RailFilter extends StatelessWidget {
//   const _RailFilter({
//     required this.icon,
//     required this.label,
//     required this.count,
//     this.active = false,
//   });

//   final IconData icon;
//   final String label;
//   final String count;
//   final bool active;

//   @override
//   Widget build(BuildContext context) {
//     return Material(
//       color: Colors.transparent,
//       child: InkWell(
//         borderRadius: BorderRadius.circular(9),
//         onTap: () => _showMessagingAction(context, label),
//         child: Container(
//           padding: const EdgeInsets.symmetric(
//             horizontal: AppSpacing.sm,
//             vertical: AppSpacing.xs + 1,
//           ),
//           decoration: BoxDecoration(
//             color: active ? AppColors.primary.withValues(alpha: 0.08) : null,
//             borderRadius: BorderRadius.circular(9),
//           ),
//           child: Row(
//             children: [
//               Icon(
//                 icon,
//                 color: active ? AppColors.primary : AppColors.mutedInk,
//                 size: 15,
//               ),
//               const SizedBox(width: AppSpacing.xs),
//               Expanded(
//                 child: Text(
//                   label,
//                   overflow: TextOverflow.ellipsis,
//                   style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                     color: active ? AppColors.ink : AppColors.mutedInk,
//                     fontWeight: active ? FontWeight.w800 : FontWeight.w600,
//                   ),
//                 ),
//               ),
//               Text(
//                 count,
//                 style: Theme.of(context).textTheme.labelSmall?.copyWith(
//                   color: active ? AppColors.primary : AppColors.placeholder,
//                   fontWeight: FontWeight.w800,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _ThreadListPane extends StatelessWidget {
//   const _ThreadListPane();

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.all(AppSpacing.md),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Expanded(
//                 child: Text(
//                   context.tr(AppTextKey.messagingThreadsTitle),
//                   overflow: TextOverflow.ellipsis,
//                   style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                     color: AppColors.ink,
//                     fontWeight: FontWeight.w900,
//                   ),
//                 ),
//               ),
//               StatusBadge(
//                 label: context.tr(AppTextKey.messagingThreadUnread),
//                 tone: BadgeTone.critical,
//               ),
//             ],
//           ),
//           const SizedBox(height: AppSpacing.md),
//           const _SearchStub(),
//           const SizedBox(height: AppSpacing.md),
//           const _MessagingSecurityStrip(),
//           const SizedBox(height: AppSpacing.md),
//           for (int i = 0; i < _MessagingMock.threads.length; i++) ...[
//             _ThreadTile(thread: _MessagingMock.threads[i]),
//             if (i < _MessagingMock.threads.length - 1)
//               const SizedBox(height: AppSpacing.sm),
//           ],
//         ],
//       ),
//     );
//   }
// }

// class _SearchStub extends StatelessWidget {
//   const _SearchStub();

//   @override
//   Widget build(BuildContext context) {
//     final label = context.tr(AppTextKey.messagingSearchHint);
//     return Material(
//       color: Colors.transparent,
//       child: InkWell(
//         borderRadius: BorderRadius.circular(9),
//         onTap: () => _showMessagingAction(context, label),
//         child: Container(
//           height: 34,
//           padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
//           decoration: BoxDecoration(
//             color: AppColors.canvas.withValues(alpha: 0.60),
//             borderRadius: BorderRadius.circular(9),
//             border: Border.all(color: AppColors.borderFaint),
//           ),
//           child: Row(
//             children: [
//               const Icon(Icons.search, size: 15, color: AppColors.placeholder),
//               const SizedBox(width: AppSpacing.xs),
//               Expanded(
//                 child: Text(
//                   label,
//                   overflow: TextOverflow.ellipsis,
//                   style: Theme.of(context).textTheme.labelSmall?.copyWith(
//                     color: AppColors.placeholder,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _ChatPane extends StatelessWidget {
//   const _ChatPane();

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         const _ThreadContextBar(),
//         Expanded(
//           child: ColoredBox(
//             color: AppColors.canvas.withValues(alpha: 0.50),
//             child: SingleChildScrollView(
//               padding: const EdgeInsets.all(AppSpacing.lg),
//               child: Column(
//                 children: [
//                   _DayDivider(
//                     label: context.tr(AppTextKey.messagingTodayDivider),
//                   ),
//                   const SizedBox(height: AppSpacing.md),
//                   for (int i = 0; i < _MessagingMock.messages.length; i++) ...[
//                     _MessageBubble(message: _MessagingMock.messages[i]),
//                     if (i == 0) ...[
//                       const SizedBox(height: AppSpacing.sm),
//                       _AttachmentRail(
//                         attachments: const [
//                           _AttachmentSpec(
//                             icon: Icons.picture_as_pdf_outlined,
//                             labelKey: AppTextKey.messagingAttachmentLab,
//                             tone: AppColors.critical,
//                           ),
//                         ],
//                       ),
//                     ],
//                     if (i < _MessagingMock.messages.length - 1)
//                       const SizedBox(height: AppSpacing.md),
//                   ],
//                   const SizedBox(height: AppSpacing.sm),
//                   _AttachmentRail(
//                     attachments: const [
//                       _AttachmentSpec(
//                         icon: Icons.image_outlined,
//                         labelKey: AppTextKey.messagingAttachmentImage,
//                         tone: AppColors.info,
//                       ),
//                     ],
//                     alignEnd: true,
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//         const _MessageComposer(),
//       ],
//     );
//   }
// }

// class _ConversationContextPanel extends StatelessWidget {
//   const _ConversationContextPanel();

//   @override
//   Widget build(BuildContext context) {
//     return ColoredBox(
//       color: AppColors.canvas.withValues(alpha: 0.35),
//       child: Padding(
//         padding: const EdgeInsets.all(AppSpacing.md),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Center(
//               child: Container(
//                 width: 40,
//                 height: 40,
//                 decoration: BoxDecoration(
//                   color: AppColors.primary.withValues(alpha: 0.10),
//                   borderRadius: BorderRadius.circular(14),
//                 ),
//                 child: const Icon(
//                   Icons.person_outline,
//                   color: AppColors.primary,
//                   size: 20,
//                 ),
//               ),
//             ),
//             const SizedBox(height: AppSpacing.md),
//             Center(
//               child: Text(
//                 context.tr(AppTextKey.messagingThreadPatient),
//                 textAlign: TextAlign.center,
//                 maxLines: 2,
//                 overflow: TextOverflow.ellipsis,
//                 style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                   color: AppColors.ink,
//                   fontWeight: FontWeight.w900,
//                 ),
//               ),
//             ),
//             const SizedBox(height: AppSpacing.xs),
//             Center(
//               child: Text(
//                 context.tr(AppTextKey.messagingPatientMeta),
//                 textAlign: TextAlign.center,
//                 maxLines: 2,
//                 overflow: TextOverflow.ellipsis,
//                 style: Theme.of(context).textTheme.labelSmall?.copyWith(
//                   color: AppColors.mutedInk,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//             ),
//             const SizedBox(height: AppSpacing.md),
//             Center(
//               child: StatusBadge(
//                 label: context.tr(AppTextKey.messagingOnlineStatus),
//                 tone: BadgeTone.normal,
//               ),
//             ),
//             const SizedBox(height: AppSpacing.lg),
//             const Divider(),
//             const SizedBox(height: AppSpacing.md),
//             _PanelSectionTitle(
//               label: context.tr(AppTextKey.messagingArchiveTitle),
//             ),
//             const SizedBox(height: AppSpacing.sm),
//             Text(
//               context.tr(AppTextKey.messagingArchiveBody),
//               style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                 color: AppColors.mutedInk,
//                 height: 1.42,
//               ),
//             ),
//             const SizedBox(height: AppSpacing.md),
//             _ArchiveSignal(
//               icon: Icons.history_edu_outlined,
//               label: context.tr(AppTextKey.messagingArchiveRetention),
//             ),
//             const SizedBox(height: AppSpacing.sm),
//             _ArchiveSignal(
//               icon: Icons.admin_panel_settings_outlined,
//               label: context.tr(AppTextKey.messagingArchiveAccess),
//             ),
//             const SizedBox(height: AppSpacing.md),
//             StatusBadge(
//               label: context.tr(AppTextKey.messagingLegalHold),
//               tone: BadgeTone.neutral,
//               icon: Icons.archive_outlined,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _PanelSectionTitle extends StatelessWidget {
//   const _PanelSectionTitle({required this.label});

//   final String label;

//   @override
//   Widget build(BuildContext context) {
//     return Text(
//       label,
//       style: Theme.of(context).textTheme.bodySmall?.copyWith(
//         color: AppColors.ink,
//         fontWeight: FontWeight.w900,
//       ),
//     );
//   }
// }

// class _MessagingSecurityStrip extends StatelessWidget {
//   const _MessagingSecurityStrip();

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(AppSpacing.sm + 2),
//       decoration: BoxDecoration(
//         color: AppColors.primary.withValues(alpha: 0.055),
//         borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
//         border: Border.all(color: AppColors.primary.withValues(alpha: 0.13)),
//       ),
//       child: Row(
//         children: [
//           Expanded(
//             child: _SecurityItem(
//               icon: Icons.lock_outline,
//               label: context.tr(AppTextKey.messagingEncrypted),
//             ),
//           ),
//           Container(width: 1, height: 22, color: AppColors.borderFaint),
//           Expanded(
//             child: _SecurityItem(
//               icon: Icons.fact_check_outlined,
//               label: context.tr(AppTextKey.messagingAuditTrail),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _SecurityItem extends StatelessWidget {
//   const _SecurityItem({required this.icon, required this.label});

//   final IconData icon;
//   final String label;

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         Icon(icon, size: 14, color: AppColors.primary),
//         const SizedBox(width: AppSpacing.xs),
//         Flexible(
//           child: Text(
//             label,
//             overflow: TextOverflow.ellipsis,
//             style: Theme.of(context).textTheme.labelSmall?.copyWith(
//               color: AppColors.primary,
//               fontWeight: FontWeight.w800,
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }

// class _ThreadTile extends StatelessWidget {
//   const _ThreadTile({required this.thread});

//   final _ThreadData thread;

//   @override
//   Widget build(BuildContext context) {
//     final tone = thread.unread ? AppColors.critical : AppColors.primary;
//     final background = thread.selected
//         ? AppColors.primary.withValues(alpha: 0.075)
//         : AppColors.surface;

//     return Material(
//       color: Colors.transparent,
//       child: InkWell(
//         borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
//         onTap: () => _showMessagingAction(context, context.tr(thread.titleKey)),
//         child: Container(
//           height: _MessagingLayout.threadHeight,
//           padding: const EdgeInsets.all(AppSpacing.sm + 2),
//           decoration: BoxDecoration(
//             color: background,
//             borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
//             border: Border.all(
//               color: thread.selected
//                   ? AppColors.primary.withValues(alpha: 0.22)
//                   : AppColors.borderFaint,
//             ),
//           ),
//           child: Row(
//             children: [
//               Container(
//                 width: 34,
//                 height: 34,
//                 decoration: BoxDecoration(
//                   color: tone.withValues(alpha: 0.10),
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 child: Icon(thread.icon, color: tone, size: 18),
//               ),
//               const SizedBox(width: AppSpacing.md),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Row(
//                       children: [
//                         Expanded(
//                           child: Text(
//                             context.tr(thread.titleKey),
//                             overflow: TextOverflow.ellipsis,
//                             style: Theme.of(context).textTheme.titleMedium
//                                 ?.copyWith(
//                                   fontWeight: FontWeight.w900,
//                                   color: AppColors.ink,
//                                 ),
//                           ),
//                         ),
//                         if (thread.pinned) ...[
//                           const SizedBox(width: AppSpacing.xs),
//                           const Icon(
//                             Icons.push_pin_rounded,
//                             color: AppColors.primary,
//                             size: 13,
//                           ),
//                         ],
//                       ],
//                     ),
//                     const SizedBox(height: 3),
//                     Text(
//                       context.tr(thread.previewKey),
//                       maxLines: 2,
//                       overflow: TextOverflow.ellipsis,
//                       style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                         color: AppColors.mutedInk,
//                         height: 1.25,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(width: AppSpacing.sm),
//               Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 crossAxisAlignment: CrossAxisAlignment.end,
//                 children: [
//                   Text(
//                     thread.time,
//                     style: Theme.of(context).textTheme.labelSmall?.copyWith(
//                       color: AppColors.placeholder,
//                       fontWeight: FontWeight.w700,
//                     ),
//                   ),
//                   const SizedBox(height: AppSpacing.xs),
//                   StatusBadge(
//                     label: context.tr(thread.stateKey),
//                     tone: thread.unread
//                         ? BadgeTone.critical
//                         : BadgeTone.neutral,
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _ThreadContextBar extends StatelessWidget {
//   const _ThreadContextBar();

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(
//         horizontal: AppSpacing.lg,
//         vertical: AppSpacing.md,
//       ),
//       child: Row(
//         children: [
//           Container(
//             width: 38,
//             height: 38,
//             decoration: BoxDecoration(
//               color: AppColors.primary.withValues(alpha: 0.10),
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: const Icon(
//               Icons.person_outline,
//               color: AppColors.primary,
//               size: 20,
//             ),
//           ),
//           const SizedBox(width: AppSpacing.md),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   context.tr(AppTextKey.messagingThreadPatient),
//                   overflow: TextOverflow.ellipsis,
//                   style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                     color: AppColors.ink,
//                     fontWeight: FontWeight.w900,
//                   ),
//                 ),
//                 const SizedBox(height: 2),
//                 Text(
//                   context.tr(AppTextKey.messagingPatientMeta),
//                   overflow: TextOverflow.ellipsis,
//                   style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                     color: AppColors.mutedInk,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(width: AppSpacing.sm),
//           StatusBadge(
//             label: context.tr(AppTextKey.messagingOnlineStatus),
//             tone: BadgeTone.normal,
//           ),
//           const SizedBox(width: AppSpacing.sm),
//           StatusBadge(
//             label: context.tr(AppTextKey.messagingEncrypted),
//             tone: BadgeTone.primary,
//             icon: Icons.lock_outline,
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _DayDivider extends StatelessWidget {
//   const _DayDivider({required this.label});

//   final String label;

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: [
//         const Expanded(child: Divider()),
//         Padding(
//           padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
//           child: Text(
//             label,
//             style: Theme.of(context).textTheme.labelSmall?.copyWith(
//               color: AppColors.placeholder,
//               fontWeight: FontWeight.w800,
//             ),
//           ),
//         ),
//         const Expanded(child: Divider()),
//       ],
//     );
//   }
// }

// class _MessageBubble extends StatelessWidget {
//   const _MessageBubble({required this.message});

//   final _MessageData message;

//   @override
//   Widget build(BuildContext context) {
//     final tone = message.critical ? AppColors.critical : AppColors.primary;
//     return Align(
//       alignment: message.mine
//           ? AlignmentDirectional.centerEnd
//           : AlignmentDirectional.centerStart,
//       child: ConstrainedBox(
//         constraints: const BoxConstraints(maxWidth: 520),
//         child: Container(
//           padding: const EdgeInsets.symmetric(
//             horizontal: AppSpacing.md,
//             vertical: AppSpacing.sm + 2,
//           ),
//           decoration: BoxDecoration(
//             color: message.mine
//                 ? AppColors.primary.withValues(alpha: 0.09)
//                 : AppColors.surface,
//             borderRadius: BorderRadiusDirectional.only(
//               topStart: const Radius.circular(AppSpacing.cardRadius),
//               topEnd: const Radius.circular(AppSpacing.cardRadius),
//               bottomStart: Radius.circular(
//                 message.mine ? AppSpacing.cardRadius : 4,
//               ),
//               bottomEnd: Radius.circular(
//                 message.mine ? 4 : AppSpacing.cardRadius,
//               ),
//             ),
//             border: Border.all(
//               color: message.critical
//                   ? AppColors.critical.withValues(alpha: 0.20)
//                   : AppColors.borderFaint,
//             ),
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 children: [
//                   Container(
//                     width: 7,
//                     height: 7,
//                     decoration: BoxDecoration(
//                       color: tone,
//                       shape: BoxShape.circle,
//                     ),
//                   ),
//                   const SizedBox(width: AppSpacing.xs),
//                   Expanded(
//                     child: Text(
//                       message.author,
//                       overflow: TextOverflow.ellipsis,
//                       style: Theme.of(context).textTheme.labelSmall?.copyWith(
//                         color: tone,
//                         fontWeight: FontWeight.w900,
//                       ),
//                     ),
//                   ),
//                   Text(
//                     message.time,
//                     style: Theme.of(context).textTheme.labelSmall?.copyWith(
//                       color: AppColors.placeholder,
//                       fontWeight: FontWeight.w700,
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: AppSpacing.xs),
//               Text(
//                 context.tr(message.bodyKey),
//                 style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                   color: AppColors.ink,
//                   height: 1.42,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _AttachmentSpec {
//   const _AttachmentSpec({
//     required this.icon,
//     required this.labelKey,
//     required this.tone,
//   });

//   final IconData icon;
//   final AppTextKey labelKey;
//   final Color tone;
// }

// class _AttachmentRail extends StatelessWidget {
//   const _AttachmentRail({required this.attachments, this.alignEnd = false});

//   final List<_AttachmentSpec> attachments;
//   final bool alignEnd;

//   @override
//   Widget build(BuildContext context) {
//     return Align(
//       alignment: alignEnd
//           ? AlignmentDirectional.centerEnd
//           : AlignmentDirectional.centerStart,
//       child: ConstrainedBox(
//         constraints: const BoxConstraints(maxWidth: 420),
//         child: Column(
//           children: [
//             for (int i = 0; i < attachments.length; i++) ...[
//               _AttachmentTile(
//                 icon: attachments[i].icon,
//                 labelKey: attachments[i].labelKey,
//                 tone: attachments[i].tone,
//               ),
//               if (i < attachments.length - 1)
//                 const SizedBox(height: AppSpacing.sm),
//             ],
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _AttachmentTile extends StatelessWidget {
//   const _AttachmentTile({
//     required this.icon,
//     required this.labelKey,
//     required this.tone,
//   });

//   final IconData icon;
//   final AppTextKey labelKey;
//   final Color tone;

//   @override
//   Widget build(BuildContext context) {
//     final label = context.tr(labelKey);
//     return Material(
//       color: Colors.transparent,
//       child: InkWell(
//         borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
//         onTap: () => _showMessagingAction(context, label),
//         child: Container(
//           padding: const EdgeInsets.symmetric(
//             horizontal: AppSpacing.md,
//             vertical: AppSpacing.sm + 2,
//           ),
//           decoration: BoxDecoration(
//             color: AppColors.surface,
//             borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
//             border: Border.all(color: AppColors.borderFaint),
//           ),
//           child: Row(
//             children: [
//               Container(
//                 width: 30,
//                 height: 30,
//                 decoration: BoxDecoration(
//                   color: tone.withValues(alpha: 0.09),
//                   borderRadius: BorderRadius.circular(9),
//                 ),
//                 child: Icon(icon, color: tone, size: 16),
//               ),
//               const SizedBox(width: AppSpacing.md),
//               Expanded(
//                 child: Text(
//                   label,
//                   overflow: TextOverflow.ellipsis,
//                   style: Theme.of(
//                     context,
//                   ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w800),
//                 ),
//               ),
//               StatusBadge(
//                 label: context.tr(AppTextKey.messagingAttachmentLocked),
//                 tone: BadgeTone.neutral,
//                 icon: Icons.lock_outline,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _MessageComposer extends StatelessWidget {
//   const _MessageComposer();

//   @override
//   Widget build(BuildContext context) {
//     final attachLabel = context.tr(AppTextKey.messagingAttachmentTitle);
//     final sendLabel = context.tr(AppTextKey.messagingSendAction);
//     return Padding(
//       padding: const EdgeInsets.all(AppSpacing.lg),
//       child: Container(
//         padding: const EdgeInsets.all(AppSpacing.sm),
//         decoration: BoxDecoration(
//           color: AppColors.surface,
//           borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
//           border: Border.all(color: AppColors.borderFaint),
//         ),
//         child: Row(
//           children: [
//             IconButton(
//               tooltip: attachLabel,
//               onPressed: () => _showMessagingAction(context, attachLabel),
//               icon: const Icon(Icons.attach_file_rounded, size: 18),
//               visualDensity: VisualDensity.compact,
//               color: AppColors.mutedInk,
//             ),
//             Expanded(
//               child: Container(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: AppSpacing.md,
//                   vertical: AppSpacing.sm,
//                 ),
//                 decoration: BoxDecoration(
//                   color: AppColors.canvas.withValues(alpha: 0.55),
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 child: Text(
//                   context.tr(AppTextKey.messagingComposeHint),
//                   overflow: TextOverflow.ellipsis,
//                   style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                     color: AppColors.placeholder,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               ),
//             ),
//             const SizedBox(width: AppSpacing.sm),
//             FilledButton.icon(
//               onPressed: () => _showMessagingAction(context, sendLabel),
//               icon: const Icon(Icons.send_rounded, size: 15),
//               label: Text(sendLabel),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _ArchiveSignal extends StatelessWidget {
//   const _ArchiveSignal({required this.icon, required this.label});

//   final IconData icon;
//   final String label;

//   @override
//   Widget build(BuildContext context) {
//     return Material(
//       color: Colors.transparent,
//       child: InkWell(
//         borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
//         onTap: () => _showMessagingAction(context, label),
//         child: Container(
//           padding: const EdgeInsets.all(AppSpacing.sm + 2),
//           decoration: BoxDecoration(
//             color: AppColors.canvas.withValues(alpha: 0.60),
//             borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
//             border: Border.all(color: AppColors.borderFaint),
//           ),
//           child: Row(
//             children: [
//               Icon(icon, color: AppColors.primary, size: 16),
//               const SizedBox(width: AppSpacing.sm),
//               Expanded(
//                 child: Text(
//                   label,
//                   overflow: TextOverflow.ellipsis,
//                   style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                     color: AppColors.ink,
//                     fontWeight: FontWeight.w800,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
