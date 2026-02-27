import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/network/duel_ws_service.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../domain/entities/duel.dart';
import '../../providers/duel_provider.dart';

class DuelDetailScreen extends ConsumerStatefulWidget {
  const DuelDetailScreen({super.key, required this.duelId});
  final String duelId;

  @override
  ConsumerState<DuelDetailScreen> createState() => _DuelDetailScreenState();
}

class _DuelDetailScreenState extends ConsumerState<DuelDetailScreen> {
  StreamSubscription<DuelWsEvent>? _wsSub;
  bool _isCheckinLoading = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(duelDetailProvider.notifier).load(widget.duelId);
      _connectWs();
    });
  }

  void _connectWs() {
    final ws = ref.read(duelWsServiceProvider);
    ws.connect(widget.duelId);
    _wsSub = ws.events.listen(_onWsEvent);
  }

  void _onWsEvent(DuelWsEvent event) {
    switch (event.type) {
      case 'checkin_created':
      case 'streak_broken':
        // Refresh detail to show updated streaks / new check-in
        ref.read(duelDetailProvider.notifier).load(widget.duelId);
        ref.read(duelsListProvider.notifier).load();
        // Show local push notification for opponent's broken streak
        final opponentName = event.data['username'] as String? ?? 'Opponent';
        final oldStreak = event.data['old_streak'] as int? ?? 0;
        NotificationService.instance.showStreakBrokenNotification(
          opponentUsername: opponentName,
          oldStreak: oldStreak,
        );
      case 'duel_completed':
        ref.read(duelDetailProvider.notifier).load(widget.duelId);
        ref.read(duelsListProvider.notifier).load();
        if (mounted) {
          final winner = event.data['winner_username'] as String?;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                winner != null
                    ? 'Duel completed! Winner: $winner 🏆'
                    : 'Duel completed — it\'s a draw!',
              ),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      default:
        break;
    }
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    ref.read(duelWsServiceProvider).disconnect();
    super.dispose();
  }

  Future<void> _handleCheckIn() async {
    if (_isCheckinLoading) return;
    setState(() => _isCheckinLoading = true);
    try {
      final ok = await ref
          .read(duelDetailProvider.notifier)
          .checkIn(widget.duelId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ok ? 'Checked in!' : 'Check-in failed'),
          ),
        );
        if (ok) ref.read(duelsListProvider.notifier).load();
      }
    } finally {
      if (mounted) setState(() => _isCheckinLoading = false);
    }
  }

  Future<void> _handleAccept() async {
    final ok = await ref
        .read(duelDetailProvider.notifier)
        .accept(widget.duelId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Duel accepted!' : 'Accept failed'),
        ),
      );
      if (ok) ref.read(duelsListProvider.notifier).load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(duelDetailProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Duel Detail')),
      body: switch (state) {
        DuelDetailLoading() => const Center(
            child: CircularProgressIndicator(),
          ),
        DuelDetailError(:final message) => Center(
            child: Text(message),
          ),
        DuelDetailLoaded(:final duel) => _DuelBody(
            duel: duel,
            onCheckIn: _handleCheckIn,
            onAccept: _handleAccept,
            isCheckinLoading: _isCheckinLoading,
          ),
      },
    );
  }
}

// ─── Duel body ──────────────────────────────────────────────────────────

class _DuelBody extends StatelessWidget {
  const _DuelBody({
    required this.duel,
    required this.onCheckIn,
    required this.onAccept,
    required this.isCheckinLoading,
  });
  final Duel duel;
  final VoidCallback onCheckIn;
  final VoidCallback onAccept;
  final bool isCheckinLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFmt = DateFormat.yMMMd();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Header card ──
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  duel.habitName,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (duel.description != null) ...[
                  const SizedBox(height: 8),
                  Text(duel.description!),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    _InfoChip(
                      icon: Icons.timer,
                      label: '${duel.durationDays} days',
                    ),
                    const SizedBox(width: 12),
                    _InfoChip(
                      icon: Icons.flag,
                      label: duel.status.toUpperCase(),
                    ),
                  ],
                ),
                if (duel.startsAt != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Started: ${dateFmt.format(duel.startsAt!)}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
                if (duel.endsAt != null)
                  Text(
                    'Ends: ${dateFmt.format(duel.endsAt!)}',
                    style: theme.textTheme.bodySmall,
                  ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // ── Participants / Streaks ──
        if (duel.participants.isNotEmpty) ...[
          Text('Participants', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          ...duel.participants.map((p) => _ParticipantTile(participant: p)),
          const SizedBox(height: 16),
        ],

        // ── Action buttons ──
        if (duel.status == 'active')
          FilledButton.icon(
            onPressed: isCheckinLoading ? null : onCheckIn,
            icon: isCheckinLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_circle),
            label: Text(isCheckinLoading ? 'Checking in…' : 'Check In'),
          ),
        if (duel.status == 'pending')
          FilledButton.icon(
            onPressed: onAccept,
            icon: const Icon(Icons.handshake),
            label: const Text('Accept Duel'),
          ),

        const SizedBox(height: 24),

        // ── Check-in history ──
        if (duel.checkins.isNotEmpty) ...[
          Text('Check-in History', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          ...duel.checkins.map((c) => _CheckInTile(entry: c)),
        ],
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      visualDensity: VisualDensity.compact,
      side: BorderSide.none,
    );
  }
}

class _ParticipantTile extends StatelessWidget {
  const _ParticipantTile({required this.participant});
  final DuelParticipant participant;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const CircleAvatar(child: Icon(Icons.person)),
      title: Text(participant.username),
      trailing: Text(
        '${participant.streak} 🔥',
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _CheckInTile extends StatelessWidget {
  const _CheckInTile({required this.entry});
  final CheckInEntry entry;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat.yMMMd().add_Hm();
    return ListTile(
      dense: true,
      leading: const Icon(Icons.check, color: Colors.green, size: 20),
      title: Text(entry.username),
      subtitle: entry.note != null ? Text(entry.note!) : null,
      trailing: Text(
        fmt.format(entry.checkedAt),
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}
