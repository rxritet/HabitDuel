import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/duel.dart';
import '../../providers/auth_provider.dart';
import '../../providers/duel_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(duelsListProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(duelsListProvider);
    final authState = ref.watch(authProvider);
    final currentUserId = authState is Authenticated ? authState.user.id : null;
    final body = switch (state) {
      DuelsListInitial() || DuelsListLoading() => const Center(
          child: CircularProgressIndicator(),
        ),
      DuelsListError(:final message) => _ErrorBody(
          message: message,
          onRetry: () => ref.read(duelsListProvider.notifier).load(),
        ),
      DuelsListLoaded(:final duels) => duels.isEmpty
          ? const _EmptyBody()
          : RefreshIndicator(
              onRefresh: () async => ref.read(duelsListProvider.notifier).load(),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: duels.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) => _AnimatedDuelCard(
                  duel: duels[index],
                  index: index,
                  currentUserId: currentUserId,
                ),
              ),
            ),
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('HabitDuel'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: KeyedSubtree(
          key: ValueKey(state.runtimeType),
          child: body,
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/create-duel'),
        icon: const Icon(Icons.add),
        label: const Text('New Duel'),
      ),
    );
  }
}

class _DuelCard extends StatelessWidget {
  const _DuelCard({required this.duel, required this.currentUserId});

  final Duel duel;
  final String? currentUserId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPending = duel.status == 'pending';
    final myParticipants = currentUserId == null
        ? const <DuelParticipant>[]
        : duel.participants.where((p) => p.userId == currentUserId).toList(growable: false);
    final opponentParticipants = currentUserId == null
        ? duel.participants
        : duel.participants.where((p) => p.userId != currentUserId).toList(growable: false);
    final myStreak = myParticipants.isNotEmpty ? myParticipants.first.streak : duel.myStreak;
    final opponentStreak =
        opponentParticipants.isNotEmpty ? opponentParticipants.first.streak : duel.opponentStreak;

    final gradient = switch (duel.status) {
      'active' => LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.15),
            theme.colorScheme.secondary.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      'open' => LinearGradient(
          colors: [
            Colors.blue.withValues(alpha: 0.15),
            Colors.cyan.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      'completed' => LinearGradient(
          colors: [
            Colors.green.withValues(alpha: 0.15),
            Colors.teal.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      _ => null,
    };

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, '/duel', arguments: duel.id),
        child: Container(
          decoration: gradient != null ? BoxDecoration(gradient: gradient) : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        duel.habitName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _StatusChip(status: duel.status),
                  ],
                ),
                if (duel.description != null && duel.description!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    duel.description!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 12),
                if (!isPending) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (duel.status == 'open')
                        _InfoChip(
                          icon: Icons.people,
                          label:
                              '${duel.participants.length}/${duel.maxParticipants}',
                        ),
                      if (duel.hasEntryFee)
                        _InfoChip(
                          icon: Icons.payments_outlined,
                          label:
                              '${duel.entryFee} ${duel.currency.symbol} с игрока',
                        ),
                      if (duel.hasEntryFee)
                        _InfoChip(
                          icon: Icons.workspace_premium_outlined,
                          label:
                              'Банк ${duel.prizePool} ${duel.currency.symbol}',
                        ),
                    ],
                  ),
                  if (duel.status != 'open') ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.local_fire_department,
                                    size: 14,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text('Вы', style: theme.textTheme.bodySmall),
                                  const Spacer(),
                                  Text(
                                    '$myStreak🔥',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: (myStreak / duel.durationDays).clamp(0, 1),
                                  minHeight: 6,
                                  backgroundColor:
                                      theme.colorScheme.outline.withValues(alpha: 0.2),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.local_fire_department,
                                    size: 14,
                                    color: theme.colorScheme.secondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Соперник',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                  const Spacer(),
                                  Text(
                                    '$opponentStreak🔥',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.secondary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: (opponentStreak / duel.durationDays)
                                      .clamp(0, 1),
                                  minHeight: 6,
                                  backgroundColor:
                                      theme.colorScheme.outline.withValues(alpha: 0.2),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    theme.colorScheme.secondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 14,
                        color: theme.colorScheme.outline,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${duel.durationDays} дней',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                      if (duel.endsAt != null) ...[
                        const Spacer(),
                        Text(
                          'До ${duel.endsAt!.day}.${duel.endsAt!.month}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ],
                  ),
                ] else
                  Text(
                    'Waiting for opponent…',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
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
      avatar: Icon(icon, size: 14),
      label: Text(label, style: const TextStyle(fontSize: 11)),
      visualDensity: VisualDensity.compact,
      side: BorderSide.none,
      padding: EdgeInsets.zero,
    );
  }
}

class _AnimatedDuelCard extends StatelessWidget {
  const _AnimatedDuelCard({
    required this.duel,
    required this.index,
    required this.currentUserId,
  });

  final Duel duel;
  final int index;
  final String? currentUserId;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 260 + (index * 35)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 16),
            child: child,
          ),
        );
      },
      child: _DuelCard(duel: duel, currentUserId: currentUserId),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'active' => ('Active', Colors.green),
      'pending' => ('Pending', Colors.orange),
      'open' => ('Open Lobby', Colors.blue),
      'completed' => ('Done', Colors.blue),
      'cancelled' => ('Cancelled', Colors.grey),
      _ => (status, Colors.grey),
    };
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      backgroundColor: color.withValues(alpha: 0.15),
      side: BorderSide.none,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _EmptyBody extends StatelessWidget {
  const _EmptyBody();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.emoji_events_outlined, size: 64),
            SizedBox(height: 16),
            Text(
              'No duels yet.\nTap "New Duel" to challenge a friend!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
