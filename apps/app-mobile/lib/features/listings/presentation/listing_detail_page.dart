import 'package:flutter/material.dart';

import '../../../core/models/app_listing.dart';
import '../../../core/session/app_scope.dart';
import '../../../core/theme/app_theme.dart';
import '../../applications/models/create_application_input.dart';
import '../../applications/presentation/received_applications_page.dart';
import '../../publish/models/edit_listing_args.dart';
import '../../publish/presentation/publish_page.dart';

class ListingDetailPage extends StatelessWidget {
  const ListingDetailPage({super.key, required this.listing});

  final AppListing listing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!;
    final controller = AppScope.of(context);
    final isMine = controller.userId == listing.publisherId;
    final canEdit = _canEditListing(listing.status);
    final canApply = !isMine && _isOpenForApplication(listing.status);
    final isExchange = listing.listingType == 'EXCHANGE';
    final accent = isExchange
        ? const Color(0xFF06B6D4)
        : const Color(0xFFF97316);
    final relatedListings = controller.listings
        .where(
          (item) =>
              item.id != listing.id &&
              item.listingType == listing.listingType &&
              item.cityCode == listing.cityCode,
        )
        .toList(growable: false)
      ..sort((a, b) {
        final featuredCompare = (b.isFeatured ? 1 : 0).compareTo(
          a.isFeatured ? 1 : 0,
        );
        if (featuredCompare != 0) {
          return featuredCompare;
        }
        final applicationsCompare = b.applicationCount.compareTo(
          a.applicationCount,
        );
        if (applicationsCompare != 0) {
          return applicationsCompare;
        }
        return (b.budgetAmount ?? 0).compareTo(a.budgetAmount ?? 0);
      });
    final visibleRelatedListings = relatedListings
        .take(3)
        .toList(growable: false);

    return Scaffold(
      appBar: AppBar(title: const Text('详情')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              gradient: LinearGradient(
                colors: isExchange
                    ? const [Color(0xFF06B6D4), Color(0xFF5DD6E8)]
                    : const [Color(0xFFF97316), Color(0xFFFFB056)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        isExchange
                            ? 'SKILL SWAP'
                            : 'TASK BOUNTY',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _statusLabel(listing.status),
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  listing.title,
                  style: theme.textTheme.headlineLarge?.copyWith(
                    color: Colors.white,
                    fontSize: 36,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  listing.budgetLabel ?? listing.status,
                  style: theme.textTheme.titleLarge?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    if (listing.cityCode != null) _HeroTag(label: listing.cityCode!),
                    if (listing.serviceMode != null)
                      _HeroTag(label: _serviceModeLabel(listing.serviceMode!)),
                    if (listing.isUrgent) const _HeroTag(label: '加急'),
                    if (listing.isFeatured) const _HeroTag(label: '推荐任务'),
                  ],
                ),
              ],
            ),
          ),
          if (listing.isFeatured) ...[
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.auto_awesome_rounded,
                            color: Color(0xFF4338CA),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '人工推荐中',
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      (listing.opsNote ?? '').trim().isNotEmpty
                          ? listing.opsNote!
                          : '这条任务已进入人工运营视野，适合优先撮合，建议尽快沟通并锁定合作节奏。',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _InlineHintChip(
                          label: listing.featuredUntil == null
                              ? '推荐进行中'
                              : _featuredRemainingLabel(listing.featuredUntil),
                        ),
                        _InlineHintChip(label: '${listing.applicationCount} 个申请'),
                        if (listing.orderCount > 0)
                          _InlineHintChip(label: '${listing.orderCount} 笔订单推进'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 560;
              final children = [
                Expanded(
                  child: _TrustStatCard(
                    label: '匹配氛围',
                    value: isExchange
                        ? '交换友好'
                        : '目标明确',
                    tint: palette.primarySoft,
                  ),
                ),
                if (!isNarrow) const SizedBox(width: 10),
                Expanded(
                  child: _TrustStatCard(
                    label: '合作方式',
                    value: listing.serviceMode == null
                        ? '待补充'
                        : _serviceModeLabel(listing.serviceMode!),
                    tint: palette.secondarySoft,
                  ),
                ),
              ];

              if (isNarrow) {
                return Column(
                  children: [
                    _TrustStatCard(
                      label: '匹配氛围',
                      value: isExchange
                          ? '交换友好'
                          : '目标明确',
                      tint: palette.primarySoft,
                    ),
                    const SizedBox(height: 10),
                    _TrustStatCard(
                      label: '合作方式',
                      value: listing.serviceMode == null
                          ? '待补充'
                          : _serviceModeLabel(listing.serviceMode!),
                      tint: palette.secondarySoft,
                    ),
                  ],
                );
              }

              return Row(children: children);
            },
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('这次合作是什么感觉', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 10),
                  Text(listing.description, style: theme.textTheme.bodyLarge),
                ],
              ),
            ),
          ),
          if (visibleRelatedListings.isNotEmpty) ...[
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('同城相似任务', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 10),
                    Text(
                      '如果这条任务暂时不合适，也可以顺手看看同城还有哪些相似机会。',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 14),
                    ...visibleRelatedListings.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ListingDetailPage(listing: item),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.titleMedium,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        item.locationText ?? _detailCityLabel(item.cityCode),
                                        style: theme.textTheme.bodySmall,
                                      ),
                                      if (item.isFeatured) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          '推荐任务',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: const Color(0xFF4338CA),
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    if (item.budgetAmount != null)
                                      Text(
                                        '¥${item.budgetAmount!.toStringAsFixed(0)}',
                                        style: theme.textTheme.titleMedium,
                                      ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '${item.applicationCount} 申请',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (isExchange &&
              (listing.exchangeOfferText?.isNotEmpty == true ||
                  listing.exchangeWantText?.isNotEmpty == true)) ...[
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 720) {
                  return Column(
                    children: [
                      _ExchangeCard(
                        title: '我能提供',
                        content: listing.exchangeOfferText ?? '待补充',
                        tint: palette.primarySoft,
                        icon: Icons.favorite_border_rounded,
                      ),
                      const SizedBox(height: 12),
                      _ExchangeCard(
                        title: '我想交换',
                        content: listing.exchangeWantText ?? '待补充',
                        tint: palette.secondarySoft,
                        icon: Icons.outbound_rounded,
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(
                      child: _ExchangeCard(
                        title: '我能提供',
                        content: listing.exchangeOfferText ?? '待补充',
                        tint: palette.primarySoft,
                        icon: Icons.favorite_border_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ExchangeCard(
                        title: '我想交换',
                        content: listing.exchangeWantText ?? '待补充',
                        tint: palette.secondarySoft,
                        icon: Icons.outbound_rounded,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: palette.tertiarySoft,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(Icons.verified_user_outlined),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${listing.publisherName} 发布', style: theme.textTheme.titleMedium),
                            const SizedBox(height: 4),
                            Text(
                              listing.locationText ?? '暂无地点说明',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      isMine ? '我的发布' : '可信合作',
                      style: theme.textTheme.bodySmall?.copyWith(color: accent),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _TrustChip(
                        icon: Icons.verified_outlined,
                        label: '信用分 ${listing.publisherCreditScore ?? 0}',
                      ),
                      _TrustChip(
                        icon: Icons.star_rounded,
                        label:
                            '评分 ${_formatTrustRating(listing.publisherRatingAvg)} · ${listing.publisherRatingCount ?? 0} 评',
                      ),
                      _TrustChip(
                        icon: Icons.check_circle_outline_rounded,
                        label:
                            '完成 ${listing.publisherCompletedTaskCount ?? 0} 任务 / ${listing.publisherCompletedExchangeCount ?? 0} 交换',
                      ),
                    ],
                  ),
                  if (!isMine) ...[
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: () => _reportListing(context),
                      icon: const Icon(Icons.flag_outlined),
                      label: const Text('举报此内容'),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (isMine) ...[
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('发布者操作', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(
                      '把收到的申请、编辑和关闭动作收在这里，方便你快速管理合作节奏。',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _DetailAction(
                          label: '收到的申请',
                          icon: Icons.inbox_outlined,
                          filled: true,
                          onTap: () => _viewApplications(context),
                        ),
                        _DetailAction(
                          label: '编辑发布',
                          icon: Icons.edit_outlined,
                          filled: false,
                          onTap: canEdit ? () => _editListing(context) : null,
                        ),
                        _DetailAction(
                          label: '关闭发布',
                          icon: Icons.pause_circle_outline,
                          filled: false,
                          onTap: _isClosable(listing.status)
                              ? () => _closeListing(context)
                              : null,
                        ),
                      ],
                    ),
                    if (!_isClosable(listing.status)) ...[
                      const SizedBox(height: 14),
                      Text(
                        '这条发布已经进入匹配或订单阶段，后续请在订单流程里结束合作。',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
      bottomNavigationBar: canApply
          ? SafeArea(
              minimum: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (listing.isFeatured)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFC7D2FE)),
                      ),
                      child: Text(
                        isExchange
                            ? '这条交换正在被优先撮合，尽量把你能提供的内容写具体一点，会更容易被接受。'
                            : '这条任务正在被优先推动成交，建议立即申请并写清楚你能怎么完成。${listing.applicationCount > 0 ? ' 当前已有 ${listing.applicationCount} 个人在跟进。' : ''}',
                      ),
                    ),
                  FilledButton.icon(
                    onPressed: () => _applyToListing(context),
                    icon: const Icon(Icons.send_outlined),
                    label: Text(
                      isExchange ? '立即发起交换' : '立即申请这条任务',
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  Future<void> _applyToListing(BuildContext context) async {
    final input = await showDialog<CreateApplicationInput>(
      context: context,
      builder: (_) => _ApplicationDialog(listing: listing),
    );

    if (input == null || !context.mounted) {
      return;
    }

    final controller = AppScope.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      await controller.createApplication(
        listingId: listing.id,
        input: input,
      );

      if (!context.mounted) {
        return;
      }

      messenger.showSnackBar(
        const SnackBar(content: Text('申请已提交，可以在“申请”页查看状态。')),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('申请失败：$error')),
      );
    }
  }

  Future<void> _editListing(BuildContext context) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PublishPage(
          initialDraft: EditListingArgs.fromListing(listing),
        ),
      ),
    );

    if (result == true && context.mounted) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _closeListing(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('关闭这条发布？'),
          content: const Text('关闭后它不会继续对外展示，后面我们再补重新发布能力。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('确认关闭'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    final controller = AppScope.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      await controller.closeListing(listing.id);
      if (!context.mounted) {
        return;
      }

      messenger.showSnackBar(
        const SnackBar(content: Text('这条发布已经关闭。')),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('关闭失败：$error')),
      );
    }
  }

  Future<void> _viewApplications(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReceivedApplicationsPage(listing: listing),
      ),
    );
  }

  Future<void> _reportListing(BuildContext context) async {
    final input = await showDialog<_ReportInput>(
      context: context,
      builder: (_) => const _ReportDialog(),
    );

    if (input == null || !context.mounted) {
      return;
    }

    final controller = AppScope.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      await controller.createListingReport(
        listingId: listing.id,
        reasonCode: input.reasonCode,
        description: input.description,
      );
      if (!context.mounted) {
        return;
      }
      messenger.showSnackBar(
        const SnackBar(content: Text('举报已提交，后台会进入处理流程。')),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('举报提交失败：$error')),
      );
    }
  }
}

class _HeroTag extends StatelessWidget {
  const _HeroTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white),
      ),
    );
  }
}

class _ExchangeCard extends StatelessWidget {
  const _ExchangeCard({
    required this.title,
    required this.content,
    required this.tint,
    required this.icon,
  });

  final String title;
  final String content;
  final Color tint;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            colors: [Colors.white, tint],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon),
            ),
            const SizedBox(height: 14),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(content, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _TrustStatCard extends StatelessWidget {
  const _TrustStatCard({
    required this.label,
    required this.value,
    required this.tint,
  });

  final String label;
  final String value;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            colors: [Colors.white, tint],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 6),
            Text(value, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}

class _InlineHintChip extends StatelessWidget {
  const _InlineHintChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _TrustChip extends StatelessWidget {
  const _TrustChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F4FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 8),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _DetailAction extends StatelessWidget {
  const _DetailAction({
    required this.label,
    required this.icon,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final child = filled
        ? FilledButton.icon(
            onPressed: onTap,
            icon: Icon(icon),
            label: Text(label),
          )
        : OutlinedButton.icon(
            onPressed: onTap,
            icon: Icon(icon),
            label: Text(label),
          );

    return SizedBox(
      width: 170,
      child: child,
    );
  }
}

bool _canEditListing(String status) {
  return status == 'DRAFT' ||
      status == 'REJECTED' ||
      status == 'PENDING_REVIEW';
}

bool _isClosable(String status) {
  return status == 'DRAFT' ||
      status == 'REJECTED' ||
      status == 'PENDING_REVIEW' ||
      status == 'PUBLISHED';
}

bool _isOpenForApplication(String status) {
  return status == 'PUBLISHED' || status == 'MATCHED';
}

String _statusLabel(String status) {
  switch (status) {
    case 'PENDING_REVIEW':
      return '待审核';
    case 'MATCHED':
      return '已匹配';
    case 'IN_PROGRESS':
      return '进行中';
    case 'CLOSED':
      return '已关闭';
    default:
      return status;
  }
}

String _serviceModeLabel(String value) {
  switch (value) {
    case 'ONLINE':
      return '线上';
    case 'OFFLINE':
      return '线下';
    case 'BOTH':
      return '都可以';
    default:
      return value;
  }
}

String _detailCityLabel(String? cityCode) {
  switch (cityCode) {
    case 'shanghai':
      return '上海';
    case 'beijing':
      return '北京';
    case 'guangzhou':
      return '广州';
    case 'shenzhen':
      return '深圳';
    case 'hangzhou':
      return '杭州';
    case 'chengdu':
      return '成都';
    case 'wuhan':
      return '武汉';
    case 'nanjing':
      return '南京';
    case 'xiamen':
      return '厦门';
    case 'chongqing':
      return '重庆';
    default:
      return cityCode ?? '城市';
  }
}

String _formatTrustRating(double? rating) {
  if (rating == null) {
    return '暂无';
  }
  return rating.toStringAsFixed(1);
}

String _featuredRemainingLabel(DateTime? featuredUntil) {
  if (featuredUntil == null) {
    return '推荐进行中';
  }
  final remainingHours = featuredUntil.difference(DateTime.now()).inHours;
  if (remainingHours <= 0) {
    return '今日到期';
  }
  if (remainingHours < 24) {
    return '${remainingHours}h 后到期';
  }
  return '${(remainingHours / 24).ceil()} 天推荐期';
}

class _ApplicationDialog extends StatefulWidget {
  const _ApplicationDialog({required this.listing});

  final AppListing listing;

  @override
  State<_ApplicationDialog> createState() => _ApplicationDialogState();
}

class _ApplicationDialogState extends State<_ApplicationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  final _priceController = TextEditingController();

  bool get _isExchange => widget.listing.listingType == 'EXCHANGE';

  @override
  void dispose() {
    _messageController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: Text(
        _isExchange ? '发起交换申请' : '提交申请',
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isExchange
                    ? '告诉对方你能提供什么、希望怎么交换。'
                    : '简单介绍一下你能怎么帮忙，以及你希望如何合作。',
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _messageController,
                maxLines: 5,
                minLines: 4,
                decoration: InputDecoration(
                  labelText: _isExchange
                      ? '交换说明'
                      : '申请说明',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return _isExchange
                        ? '请填写你的交换说明'
                        : '请简单介绍一下你能怎么帮忙';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: _isExchange
                      ? '补差金额（可选）'
                      : '我的报价（可选）',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(
            _isExchange
                ? '发起交换'
                : '发送申请',
          ),
        ),
      ],
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop(
      CreateApplicationInput(
        message: _messageController.text.trim(),
        quotedPrice: double.tryParse(_priceController.text.trim()),
      ),
    );
  }
}

class _ReportInput {
  const _ReportInput({
    required this.reasonCode,
    this.description,
  });

  final String reasonCode;
  final String? description;
}

class _ReportDialog extends StatefulWidget {
  const _ReportDialog();

  @override
  State<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<_ReportDialog> {
  final _descriptionController = TextEditingController();
  String _reasonCode = 'fraud_risk';

  static const _reasons = [
    ('fraud_risk', '疑似欺诈'),
    ('illegal_content', '违规内容'),
    ('harassment', '骚扰或冒犯'),
    ('spam', '垃圾信息'),
    ('other', '其他问题'),
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('举报此内容'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _reasonCode,
              decoration: const InputDecoration(labelText: '举报原因'),
              items: _reasons
                  .map(
                    (item) => DropdownMenuItem<String>(
                      value: item.$1,
                      child: Text(item.$2),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                setState(() {
                  _reasonCode = value;
                });
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: '补充说明（可选）',
                hintText: '比如说明你看到的具体问题。',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop(
              _ReportInput(
                reasonCode: _reasonCode,
                description: _descriptionController.text.trim().isEmpty
                    ? null
                    : _descriptionController.text.trim(),
              ),
            );
          },
          child: const Text('提交举报'),
        ),
      ],
    );
  }
}
