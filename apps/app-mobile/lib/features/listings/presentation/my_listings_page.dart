import 'package:flutter/material.dart';

import '../../../core/models/app_listing.dart';
import '../../../core/session/app_scope.dart';
import '../../../core/theme/app_theme.dart';
import '../../publish/models/edit_listing_args.dart';
import '../../publish/presentation/publish_page.dart';
import 'listing_detail_page.dart';

enum MyListingsFilter { all, pendingReview, active, closed }

class MyListingsPage extends StatefulWidget {
  const MyListingsPage({
    super.key,
    this.initialFilter = MyListingsFilter.all,
    this.noticeMessage,
  });

  final MyListingsFilter initialFilter;
  final String? noticeMessage;

  @override
  State<MyListingsPage> createState() => _MyListingsPageState();
}

class _MyListingsPageState extends State<MyListingsPage> {
  late MyListingsFilter _filter = widget.initialFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final noticeMessage = widget.noticeMessage;
      if (noticeMessage == null || !mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(noticeMessage)),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final allListings = controller.myListings
        .where((item) => item.listingType != 'BUDDY')
        .toList(growable: false);
    final listings = _filterListings(allListings, _filter);
    final pendingCount = _filterListings(allListings, MyListingsFilter.pendingReview).length;
    final activeCount = _filterListings(allListings, MyListingsFilter.active).length;
    final closedCount = _filterListings(allListings, MyListingsFilter.closed).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的发布'),
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
            colors: [Color(0xFFFDF2F8), Color(0xFFF7F6FF), Color(0xFFFFFCF7)],
          ),
        ),
        child: listings.isEmpty
            ? _EmptyState(
                title: _filter == MyListingsFilter.all ? '还没有发布内容' : '当前筛选下还没有内容',
                description: _filter == MyListingsFilter.all
                    ? '先去发布页发一条任务或交换，把你的工作台填满。'
                    : '换个状态看看，或者继续创建一条新的发布。',
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                children: [
                  _ListingsHero(
                    totalCount: allListings.length,
                    pendingCount: pendingCount,
                    activeCount: activeCount,
                    closedCount: closedCount,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _FilterPill(
                        label: '全部 ${allListings.length}',
                        selected: _filter == MyListingsFilter.all,
                        onTap: () => setState(() => _filter = MyListingsFilter.all),
                      ),
                      _FilterPill(
                        label: '待审核 $pendingCount',
                        selected: _filter == MyListingsFilter.pendingReview,
                        onTap: () => setState(() => _filter = MyListingsFilter.pendingReview),
                      ),
                      _FilterPill(
                        label: '进行中 $activeCount',
                        selected: _filter == MyListingsFilter.active,
                        onTap: () => setState(() => _filter = MyListingsFilter.active),
                      ),
                      _FilterPill(
                        label: '已结束 $closedCount',
                        selected: _filter == MyListingsFilter.closed,
                        onTap: () => setState(() => _filter = MyListingsFilter.closed),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  ...listings.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _ListingCard(item: item),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _ListingsHero extends StatelessWidget {
  const _ListingsHero({
    required this.totalCount,
    required this.pendingCount,
    required this.activeCount,
    required this.closedCount,
  });

  final int totalCount;
  final int pendingCount;
  final int activeCount;
  final int closedCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          colors: [Color(0xFFEC4899), Color(0xFF7C3AED), Color(0xFF4F46E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'Creator workspace',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '把你的任务和交换，像作品集一样管理起来。',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  height: 1.08,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            '待审核、进行中、已结束会自动分层，你只需要专注于下一条最值得推进的合作。',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.86),
                ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MiniStat(label: '全部', value: '$totalCount'),
              _MiniStat(label: '待审核', value: '$pendingCount'),
              _MiniStat(label: '进行中', value: '$activeCount'),
              _MiniStat(label: '已结束', value: '$closedCount'),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEC4899) : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? const Color(0xFFEC4899) : palette.primarySoft,
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

class _ListingCard extends StatelessWidget {
  const _ListingCard({required this.item});

  final AppListing item;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final accent = _statusPalette(item.status).$2;

    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: () async {
        final result = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => ListingDetailPage(listing: item),
          ),
        );

        if (result == true) {
          await controller.refreshAll();
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
              color: Color(0x101E1B4B),
              blurRadius: 22,
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
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(18),
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
                        Text(item.title, style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 4),
                        Text(
                          item.budgetLabel ?? _statusLabel(item.status),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  _StatusPill(status: item.status),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MetaChip(
                    label: item.listingType == 'EXCHANGE'
                        ? '技能交换'
                        : '悬赏任务',
                  ),
                  if (item.cityCode?.isNotEmpty == true) _MetaChip(label: item.cityCode!),
                  if (item.isUrgent) const _MetaChip(label: '加急'),
                  if (item.applicationCount > 0) _MetaChip(label: '${item.applicationCount} 条申请'),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                item.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (item.status == 'REJECTED' && (item.auditReason?.isNotEmpty == true)) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE4E6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Color(0xFFE11D48)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('驳回原因', style: Theme.of(context).textTheme.titleSmall),
                            const SizedBox(height: 4),
                            Text(item.auditReason!, style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: () async {
                      final result = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (_) => PublishPage(
                            initialDraft: EditListingArgs.fromListing(item),
                          ),
                        ),
                      );

                      if (result == true && context.mounted) {
                        await AppScope.of(context).refreshAll();
                      }
                    },
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('去修改重新提交'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F4FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final palette = _statusPalette(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: palette.$1,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(
          color: palette.$2,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Container(
          width: 430,
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
                  color: const Color(0xFFEDE9FE),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.inventory_2_outlined, size: 34),
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

List<AppListing> _filterListings(List<AppListing> listings, MyListingsFilter filter) {
  return listings.where((item) {
    switch (filter) {
      case MyListingsFilter.all:
        return true;
      case MyListingsFilter.pendingReview:
        return item.status == 'PENDING_REVIEW' || item.status == 'REJECTED';
      case MyListingsFilter.active:
        return item.status == 'PUBLISHED' ||
            item.status == 'MATCHED' ||
            item.status == 'IN_PROGRESS';
      case MyListingsFilter.closed:
        return item.status == 'CLOSED' || item.status == 'COMPLETED';
    }
  }).toList(growable: false);
}

String _statusLabel(String status) {
  switch (status) {
    case 'PENDING_REVIEW':
      return '待审核';
    case 'REJECTED':
      return '未通过';
    case 'PUBLISHED':
      return '已发布';
    case 'MATCHED':
      return '已匹配';
    case 'IN_PROGRESS':
      return '进行中';
    case 'CLOSED':
      return '已关闭';
    case 'COMPLETED':
      return '已完成';
    default:
      return status;
  }
}

(Color, Color) _statusPalette(String status) {
  switch (status) {
    case 'PENDING_REVIEW':
      return (const Color(0xFFFFF3D6), const Color(0xFF8A5A00));
    case 'REJECTED':
      return (const Color(0xFFFFE3E3), const Color(0xFFA33636));
    case 'PUBLISHED':
      return (const Color(0xFFDDF5E8), const Color(0xFF1E7A46));
    case 'MATCHED':
    case 'IN_PROGRESS':
      return (const Color(0xFFE0EEFF), const Color(0xFF215DAB));
    case 'CLOSED':
    case 'COMPLETED':
      return (const Color(0xFFECECEC), const Color(0xFF555555));
    default:
      return (const Color(0xFFF2F2F2), const Color(0xFF444444));
  }
}
