import 'package:flutter/material.dart';

import '../../../core/session/app_scope.dart';
import '../../../core/theme/app_theme.dart';
import '../../applications/presentation/my_applications_page.dart';
import '../../listings/presentation/my_listings_page.dart';
import '../../orders/presentation/orders_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final user = controller.currentUser;
    final palette = Theme.of(context).extension<AppPalette>()!;
    final activeListings = controller.myListings
        .where((item) => item.status == 'PUBLISHED' || item.status == 'MATCHED' || item.status == 'IN_PROGRESS')
        .length;
    final orderCount = controller.myOrders.length;
    final hunterLevel = _hunterLevelFromRaw(user?.level);
    final completedCount =
        (user?.completedTaskCount ?? 0) + (user?.completedExchangeCount ?? 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的'),
        actions: [
          IconButton(
            onPressed: controller.refreshAll,
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            onPressed: controller.resetSession,
            icon: const Icon(Icons.logout_rounded),
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
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            _ProfileHero(
              nickname: user?.nickname ?? '未登录',
              subtitle: user == null
                  ? '等你开始接住这座城市里的第一件小事'
                  : '${hunterLevel.title} · 信用分 ${user.creditScore ?? 0} · 评分 ${_formatRating(user.ratingAvg)}',
              cityCode: user?.cityCode,
              levelLabel: hunterLevel.title,
              levelColor: hunterLevel.color,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(18),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: hunterLevel.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          hunterLevel.title,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: hunterLevel.color,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Lv.${user?.level ?? 1}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '我的名声与记录',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '这里留住你接住过什么、完成过什么，以及别人为什么愿意继续把事托付给你。',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _HunterMetric(
                          label: '累计完成',
                          value: '$completedCount',
                          tint: hunterLevel.color.withValues(alpha: 0.14),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _HunterMetric(
                          label: '信用分',
                          value: '${user?.creditScore ?? 0}',
                          tint: const Color(0xFFEDE9FE),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _HunterMetric(
                          label: '评分',
                          value: _formatRating(user?.ratingAvg),
                          tint: const Color(0xFFFFF3C4),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _LevelBenefitChip(label: hunterLevel.title),
                      _LevelBenefitChip(label: 'Lv.${user?.level ?? 1}'),
                      _LevelBenefitChip(label: '${user?.ratingCount ?? 0} 条评价'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _StatCard(
                  label: '我发起的事',
                  value: '${controller.myListings.length}',
                  tone: palette.primarySoft,
                  icon: Icons.inventory_2_rounded,
                ),
                _StatCard(
                  label: '推进中',
                  value: '$activeListings',
                  tone: palette.tertiarySoft,
                  icon: Icons.bolt_rounded,
                ),
                _StatCard(
                  label: '合作单',
                  value: '$orderCount',
                  tone: palette.successSoft,
                  icon: Icons.receipt_long_rounded,
                ),
                _StatCard(
                  label: '收到评价',
                  value: '${user?.ratingCount ?? 0}',
                  tone: const Color(0xFFFFF3C4),
                  icon: Icons.star_rounded,
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text('这一路我留下了什么', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            _WorkspaceCard(
              icon: Icons.inventory_2_outlined,
              title: '我发起的事',
              description: '当前共 ${controller.myListings.length} 条，看看你把哪些小事贴上了任务墙，它们现在推进到哪一步。',
              color: const Color(0xFFEDE9FE),
              onTap: () async {
                final result = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(builder: (_) => const MyListingsPage()),
                );

                if (result == true) {
                  await controller.refreshAll();
                }
              },
            ),
            const SizedBox(height: 12),
            _WorkspaceCard(
              icon: Icons.send_and_archive_outlined,
              title: '我的回应',
              description: '当前共 ${controller.myApplications.length} 条，看看你接住过哪些事，哪些已经收到了回音。',
              color: const Color(0xFFFFE8DA),
              onTap: () async {
                final result = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(builder: (_) => const MyApplicationsPage()),
                );

                if (result == true) {
                  await controller.refreshAll();
                }
              },
            ),
            const SizedBox(height: 12),
            _WorkspaceCard(
              icon: Icons.receipt_long_outlined,
              title: '我做成的合作',
              description: '当前共 ${controller.myOrders.length} 条，把已经接住的事继续推进到完成，让它们真的落地。',
              color: const Color(0xFFE4F9EC),
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const OrdersPage()),
                );
              },
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(18),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('我是谁，别人为什么会信我', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  _InfoRow(label: '城市', value: user?.cityCode ?? '未填写'),
                  _InfoRow(label: '平均评分', value: _formatRating(user?.ratingAvg)),
                  _InfoRow(label: '评价次数', value: '${user?.ratingCount ?? 0}'),
                  _InfoRow(label: '个人简介', value: user?.bio ?? '还没有留下自我介绍'),
                ],
              ),
            ),
            if (controller.errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE2E2),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text('最近一次同步异常：${controller.errorMessage}'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.nickname,
    required this.subtitle,
    required this.cityCode,
    required this.levelLabel,
    required this.levelColor,
  });

  final String nickname;
  final String subtitle;
  final String? cityCode;
  final String levelLabel;
  final Color levelColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          colors: [Color(0xFFEC4899), Color(0xFFF97316)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(Icons.person_rounded, color: Colors.white, size: 34),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nickname,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        height: 1.05,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.88),
                      ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: levelColor.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
                  ),
                  child: Text(
                    levelLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                if (cityCode?.isNotEmpty == true) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      cityCode!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HunterMetric extends StatelessWidget {
  const _HunterMetric({
    required this.label,
    required this.value,
    required this.tint,
  });

  final String label;
  final String value;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _LevelBenefitChip extends StatelessWidget {
  const _LevelBenefitChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7FB),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}

class _HunterLevelViewModel {
  const _HunterLevelViewModel({
    required this.title,
    required this.color,
    required this.benefits,
  });

  final String title;
  final Color color;
  final List<String> benefits;
}

_HunterLevelViewModel _hunterLevelFromRaw(int? rawLevel) {
  final level = rawLevel ?? 1;
  if (level >= 7) {
    return const _HunterLevelViewModel(
      title: '大师回应者',
      color: Color(0xFF7C3AED),
      benefits: ['高价任务优先推荐', '门店精选候选', '高信任故事曝光'],
    );
  }
  if (level >= 5) {
    return const _HunterLevelViewModel(
      title: '黄金回应者',
      color: Color(0xFFF59E0B),
      benefits: ['优质任务优先可见', '更高推荐权重', '稳定合作标签'],
    );
  }
  if (level >= 3) {
    return const _HunterLevelViewModel(
      title: '白银回应者',
      color: Color(0xFF64748B),
      benefits: ['更多任务曝光', '建立口碑阶段', '信用开始沉淀'],
    );
  }
  return const _HunterLevelViewModel(
    title: '青铜回应者',
    color: Color(0xFFB45309),
    benefits: ['完成首批任务', '建立基础评分', '解锁更多推荐'],
  );
}

String _formatRating(double? rating) {
  if (rating == null) {
    return '暂无';
  }
  return rating.toStringAsFixed(1);
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.tone,
    required this.icon,
  });

  final String label;
  final String value;
  final Color tone;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: tone,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon),
            const SizedBox(height: 12),
            Text(value, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 2),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _WorkspaceCard extends StatelessWidget {
  const _WorkspaceCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
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
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(description, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 18),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 84,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
