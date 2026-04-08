import 'package:flutter/material.dart';

import '../../../core/models/app_application.dart';
import '../../../core/session/app_scope.dart';
import '../../../core/theme/app_theme.dart';

class MyApplicationsPage extends StatefulWidget {
  const MyApplicationsPage({super.key});

  @override
  State<MyApplicationsPage> createState() => _MyApplicationsPageState();
}

enum _ApplicationFilter { all, pending, accepted, closed }

class _MyApplicationsPageState extends State<MyApplicationsPage> {
  _ApplicationFilter _filter = _ApplicationFilter.all;
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final items = controller.myApplications
        .where((item) => item.listingType != 'BUDDY')
        .toList(growable: false);
    final pendingCount = items.where((item) => item.status == 'PENDING').length;
    final acceptedCount = items.where((item) => item.status == 'ACCEPTED').length;
    final closedCount = items.where((item) => item.status == 'WITHDRAWN' || item.status == 'REJECTED').length;
    final filteredItems = items.where((item) {
      switch (_filter) {
        case _ApplicationFilter.all:
          break;
        case _ApplicationFilter.pending:
          if (item.status != 'PENDING') {
            return false;
          }
          break;
        case _ApplicationFilter.accepted:
          if (item.status != 'ACCEPTED') {
            return false;
          }
          break;
        case _ApplicationFilter.closed:
          if (item.status != 'WITHDRAWN' && item.status != 'REJECTED') {
            return false;
          }
          break;
      }

      if (_search.isEmpty) {
        return true;
      }

      final query = _search.toLowerCase();
      return item.listingTitle.toLowerCase().contains(query) ||
          item.message.toLowerCase().contains(query) ||
          _statusLabel(item.status).toLowerCase().contains(query);
    }).toList(growable: false);
    final palette = Theme.of(context).extension<AppPalette>()!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的申请'),
        actions: [
          IconButton(
            onPressed: controller.refreshAll,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF7F4FF), Color(0xFFF4F8FF), Color(0xFFFFFCF7)],
          ),
        ),
        child: items.isEmpty
            ? _EmptyState(
                accent: palette.secondarySoft,
                title: '还没有出手过',
                description: '先去首页挑一条让你眼前一亮的任务，发出第一条申请吧。',
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                children: [
                  _ApplicationsHero(
                    totalCount: items.length,
                    pendingCount: pendingCount,
                    acceptedCount: acceptedCount,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _FilterChip(
                        label: '全部 ${items.length}',
                        selected: _filter == _ApplicationFilter.all,
                        onTap: () => setState(() => _filter = _ApplicationFilter.all),
                      ),
                      _FilterChip(
                        label: '待处理 $pendingCount',
                        selected: _filter == _ApplicationFilter.pending,
                        onTap: () => setState(() => _filter = _ApplicationFilter.pending),
                      ),
                      _FilterChip(
                        label: '已接受 $acceptedCount',
                        selected: _filter == _ApplicationFilter.accepted,
                        onTap: () => setState(() => _filter = _ApplicationFilter.accepted),
                      ),
                      _FilterChip(
                        label: '已结束 $closedCount',
                        selected: _filter == _ApplicationFilter.closed,
                        onTap: () => setState(() => _filter = _ApplicationFilter.closed),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search_rounded),
                      hintText: '搜索标题 / 申请说明 / 状态',
                    ),
                    onChanged: (value) {
                      setState(() {
                        _search = value.trim();
                      });
                    },
                  ),
                  const SizedBox(height: 18),
                  ...filteredItems.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _ApplicationCard(item: item),
                      )),
                ],
              ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF5447E7) : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? const Color(0xFF5447E7) : const Color(0xFFD9CFFE),
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: selected ? Colors.white : Theme.of(context).colorScheme.onSurface,
              ),
        ),
      ),
    );
  }
}

class _ApplicationsHero extends StatelessWidget {
  const _ApplicationsHero({
    required this.totalCount,
    required this.pendingCount,
    required this.acceptedCount,
  });

  final int totalCount;
  final int pendingCount;
  final int acceptedCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          colors: [Color(0xFF5447E7), Color(0xFF7C3AED), Color(0xFFEB6C2D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x224F46E5),
            blurRadius: 30,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'Pitch board',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.white),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '把你想接的机会，排成一条有节奏的出击线。',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              height: 1.08,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '待处理的申请会停在前排，已经被接纳的机会则继续向订单推进。',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.86),
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _HeroStat(
                label: '总申请',
                value: '$totalCount',
                tone: Colors.white,
                background: Colors.white.withValues(alpha: 0.16),
              ),
              _HeroStat(
                label: '待处理',
                value: '$pendingCount',
                tone: const Color(0xFF4C1D95),
                background: palette.spotlight,
              ),
              _HeroStat(
                label: '已接受',
                value: '$acceptedCount',
                tone: const Color(0xFF14532D),
                background: const Color(0xFFD9FDE5),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({
    required this.label,
    required this.value,
    required this.tone,
    required this.background,
  });

  final String label;
  final String value;
  final Color tone;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 108,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: tone,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: tone),
          ),
        ],
      ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard({required this.item});

  final AppApplication item;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final theme = Theme.of(context);
    final accent = _statusAccent(item.status);
    final chips = [
      if (item.cityCode?.isNotEmpty == true) item.cityCode!,
      _listingTypeLabel(item.listingType),
      if (item.quotedPrice != null) '报价 ¥${item.quotedPrice!.toStringAsFixed(0)}',
    ];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent.withValues(alpha: 0.14), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F1E1B4B),
            blurRadius: 24,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    item.listingType == 'EXCHANGE'
                        ? Icons.swap_horiz_rounded
                        : Icons.bolt_rounded,
                    color: accent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.listingTitle,
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.createdAt == null
                            ? '刚刚投出的一条申请'
                            : '投递于 ${_formatDate(item.createdAt!)}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                _StatusBadge(status: item.status),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: chips
                  .map(
                    (chip) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.76),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(chip, style: theme.textTheme.bodySmall),
                    ),
                  )
                  .toList(growable: false),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.82),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                item.message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            if (_canWithdraw(item.status)) ...[
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (dialogContext) {
                        return AlertDialog(
                          title: const Text('撤回这条申请？'),
                          content: const Text('撤回后会退出当前排队，但你之后还能重新申请。'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(dialogContext).pop(false),
                              child: const Text('取消'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.of(dialogContext).pop(true),
                              child: const Text('确认撤回'),
                            ),
                          ],
                        );
                      },
                    );

                    if (confirmed != true || !context.mounted) {
                      return;
                    }

                    try {
                      await controller.withdrawApplication(item.id);
                      if (!context.mounted) {
                        return;
                      }

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('申请已撤回。')),
                      );
                    } catch (error) {
                      if (!context.mounted) {
                        return;
                      }

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('撤回失败：$error')),
                      );
                    }
                  },
                  icon: const Icon(Icons.undo_rounded),
                  label: const Text('撤回申请'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final background = _statusAccent(status).withValues(alpha: 0.14);
    final foreground = _statusAccent(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _statusLabel(status),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: foreground),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.accent,
    required this.title,
    required this.description,
  });

  final Color accent;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Container(
          width: 420,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: const [
              BoxShadow(
                color: Color(0x121E1B4B),
                blurRadius: 28,
                offset: Offset(0, 18),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.send_rounded, size: 34),
              ),
              const SizedBox(height: 18),
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                description,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

bool _canWithdraw(String status) => status == 'PENDING';

String _statusLabel(String status) {
  switch (status) {
    case 'PENDING':
      return '待处理';
    case 'ACCEPTED':
      return '已接受';
    case 'REJECTED':
      return '已拒绝';
    case 'WITHDRAWN':
      return '已撤回';
    case 'EXPIRED':
      return '已失效';
    default:
      return status;
  }
}

String _listingTypeLabel(String listingType) {
  switch (listingType) {
    case 'EXCHANGE':
      return '技能交换';
    default:
      return '悬赏任务';
  }
}

Color _statusAccent(String status) {
  switch (status) {
    case 'ACCEPTED':
      return const Color(0xFF169B62);
    case 'REJECTED':
      return const Color(0xFFDF4457);
    case 'WITHDRAWN':
    case 'EXPIRED':
      return const Color(0xFF7A7C90);
    default:
      return const Color(0xFFF59E0B);
  }
}

String _formatDate(DateTime time) {
  final month = time.month.toString().padLeft(2, '0');
  final day = time.day.toString().padLeft(2, '0');
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$month/$day $hour:$minute';
}
