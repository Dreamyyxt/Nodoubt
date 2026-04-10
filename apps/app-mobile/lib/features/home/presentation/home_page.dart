// ignore_for_file: unused_element, unused_element_parameter

import 'package:flutter/material.dart';

import '../../../core/models/app_listing.dart';
import '../../../core/models/app_order.dart';
import '../../../core/config/map_config.dart';
import '../../../core/session/app_scope.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/city_coordinates.dart';
import '../../feed/presentation/story_feed_page.dart';
import '../../listings/presentation/listing_detail_page.dart';
import '../../publish/models/create_listing_input.dart';
import '../../publish/presentation/publish_page.dart';
import 'widgets/amap_region_map.dart';
import 'widgets/amap_region_map_data.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

enum _HomeViewMode { cards, list }

enum _ListingDiscoveryType {
  all,
  companionship,
  together,
  lifestyle,
  kindness,
  skill,
}

enum _ListingSortMode { newest, hottest, trusted, budgetHigh }

class _HomePageState extends State<HomePage> {
  String? _selectedCityCode;
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final allListings = controller.listings
        .where((item) => item.listingType != 'BUDDY')
        .toList(growable: false);
    final cityClusters = _buildCityClusters(allListings);
    final selectedCluster = _selectedCityCode == null
        ? null
        : cityClusters
              .where((cluster) => cluster.cityCode == _selectedCityCode)
              .firstOrNull;
    final listings = selectedCluster == null
        ? allListings
        : allListings
              .where((item) => item.cityCode == selectedCluster.cityCode)
              .toList(growable: false);
    final discoveredListings = _applyDiscoveryFilters(listings);
    return RefreshIndicator(
      onRefresh: controller.refreshAll,
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            surfaceTintColor: Colors.transparent,
            title: const Text('确任'),
            actions: [
              IconButton(
                onPressed: controller.refreshAll,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _MinimalHomeBlock(
                  eyebrow: 'Map',
                  title: selectedCluster == null
                      ? '先看这座城市的任务落在哪里'
                      : '现在看的是 ${selectedCluster.label}',
                  subtitle: selectedCluster == null
                      ? '地图先帮你缩小范围，下面只留一叠正在等待回应的小事。'
                      : '地图已经切到 ${selectedCluster.label}，下面这叠卡片也会跟着变化。',
                  child: _RegionHeatSection(
                    clusters: cityClusters,
                    selectedCityCode: _selectedCityCode,
                    onCityTap: (cluster) {
                      setState(() {
                        _selectedCityCode = cluster.cityCode.isEmpty
                            ? null
                            : cluster.cityCode;
                      });
                    },
                    onClearFilter: _selectedCityCode == null
                        ? null
                        : () {
                            setState(() {
                              _selectedCityCode = null;
                            });
                          },
                  ),
                ),
                const SizedBox(height: 22),
                _MinimalHomeBlock(
                  eyebrow: 'Deck',
                  title: selectedCluster == null
                      ? '翻翻这叠城市里的小事'
                      : '翻翻 ${selectedCluster.label} 的这叠小事',
                  subtitle: selectedCluster == null
                      ? '首页只留下地图和任务 deck。你可以先搜一句话，再一张张翻。'
                      : '下面这叠卡片，都是 ${selectedCluster.label} 此刻正在等待被接住的小事。',
                  trailing: SizedBox(
                    width: 240,
                    child: TextField(
                      onChanged: (value) {
                        setState(() {
                          _search = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: '搜一句话或地点',
                        isDense: true,
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _search.isEmpty
                            ? null
                            : IconButton(
                                onPressed: () {
                                  setState(() {
                                    _search = '';
                                  });
                                },
                                icon: const Icon(Icons.close_rounded),
                              ),
                      ),
                    ),
                  ),
                  child: Builder(
                    builder: (context) {
                      if (controller.isBootstrapping) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      if (controller.errorMessage != null) {
                        return _StateCard(
                          title: '联调暂时没接上',
                          description: controller.errorMessage!,
                          tint: Theme.of(
                            context,
                          ).colorScheme.error.withValues(alpha: 0.08),
                          actionLabel: '重新加载',
                          onAction: controller.refreshAll,
                        );
                      }
                      if (discoveredListings.isEmpty) {
                        return _StateCard(
                          title: _search.isEmpty ? '这叠卡片还空着' : '没有搜到这件事',
                          description: _search.isEmpty
                              ? '地图已经准备好了，但现在还没有新的小事贴上来。你可以先发起一件。'
                              : '换一句更短的关键词试试，或者清空搜索看看整叠卡片。',
                          actionLabel: _search.isEmpty ? '去贴一件事' : '清空搜索',
                          onAction: _search.isEmpty
                              ? () {
                                  Navigator.of(context).push(
                                    _playfulRoute(
                                      const PublishPage(
                                        initialListingType:
                                            PublishListingType.task,
                                      ),
                                    ),
                                  );
                                }
                              : () {
                                  setState(() {
                                    _search = '';
                                  });
                                },
                        );
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${discoveredListings.length} 张卡片',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 14),
                          _CardDeckSection(listings: discoveredListings),
                        ],
                      );
                    },
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  List<AppListing> _applyDiscoveryFilters(List<AppListing> source) {
    Iterable<AppListing> results = source;

    if (_search.isNotEmpty) {
      final query = _search.toLowerCase();
      results = results.where((item) {
        return item.title.toLowerCase().contains(query) ||
            item.description.toLowerCase().contains(query) ||
            item.publisherName.toLowerCase().contains(query) ||
            item.tags.any((tag) => tag.toLowerCase().contains(query)) ||
            _cityLabel(item.cityCode).toLowerCase().contains(query);
      });
    }
    return results.toList(growable: false);
  }
}

class _HomeHero extends StatelessWidget {
  const _HomeHero({required this.taskCount, required this.exchangeCount});

  final int taskCount;
  final int exchangeCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF6D5DF6), Color(0xFF9277FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x334F46E5),
            blurRadius: 28,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'CITY TASK WALL',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white,
                letterSpacing: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '把一件小事\n认真托付给一个对的人。',
            style: theme.textTheme.headlineLarge?.copyWith(
              color: Colors.white,
              fontSize: 40,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '这里不是找兼职，而是帮你在城市里，找到愿意回应、愿意陪你把这件事做成的人。',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: const Color(0xFFF1F2FF),
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              _StoryTag(label: '陪我看展'),
              _StoryTag(label: '一起散步'),
              _StoryTag(label: '生活帮忙'),
              _StoryTag(label: '把小事做成'),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _HeroMetric(label: '任务', value: '$taskCount'),
              _HeroMetric(label: '交换', value: '$exchangeCount'),
              _HeroMetric(
                label: '任务墙',
                value: _plazaStage(taskCount + exchangeCount),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _plazaStage(int total) {
  if (total >= 20) {
    return '活跃';
  }
  if (total >= 8) {
    return '升温';
  }
  return '起步';
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(22),
      ),
      child: RichText(
        text: TextSpan(
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.white),
          children: [
            TextSpan(
              text: '$value ',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.white),
            ),
            TextSpan(text: label),
          ],
        ),
      ),
    );
  }
}

class _HomeSectionTitle extends StatelessWidget {
  const _HomeSectionTitle({
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 6),
              Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 12), trailing!],
      ],
    );
  }
}

class _SectionPanel extends StatelessWidget {
  const _SectionPanel({
    required this.title,
    required this.subtitle,
    required this.child,
    required this.accent,
    this.action,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Color accent;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFEAE7F2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HomeSectionTitle(title: title, subtitle: subtitle, trailing: action),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(24),
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _MinimalHomeBlock extends StatelessWidget {
  const _MinimalHomeBlock({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE7E5E4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            eyebrow.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              letterSpacing: 1.2,
              color: const Color(0xFF71717A),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.headlineMedium),
                    const SizedBox(height: 6),
                    Text(subtitle, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 16), trailing!],
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _DiscoveryControlPanel extends StatelessWidget {
  const _DiscoveryControlPanel({
    required this.search,
    required this.typeFilter,
    required this.sortMode,
    required this.serviceModeFilter,
    required this.urgentOnly,
    required this.resultCount,
    required this.onSearchChanged,
    required this.onTypeChanged,
    required this.onSortChanged,
    required this.onServiceModeChanged,
    required this.onUrgentChanged,
    this.onReset,
  });

  final String search;
  final _ListingDiscoveryType typeFilter;
  final _ListingSortMode sortMode;
  final String? serviceModeFilter;
  final bool urgentOnly;
  final int resultCount;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<_ListingDiscoveryType> onTypeChanged;
  final ValueChanged<_ListingSortMode> onSortChanged;
  final ValueChanged<String?> onServiceModeChanged;
  final ValueChanged<bool> onUrgentChanged;
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              onChanged: onSearchChanged,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded),
                hintText: '搜任务标题、技能关键词、发起人、城市',
                suffixIcon: search.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () => onSearchChanged(''),
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _DiscoveryChip(
                    label: '全部',
                    selected: typeFilter == _ListingDiscoveryType.all,
                    onTap: () => onTypeChanged(_ListingDiscoveryType.all),
                  ),
                  const SizedBox(width: 8),
                  _DiscoveryChip(
                    label: '倾听陪伴',
                    selected: typeFilter == _ListingDiscoveryType.companionship,
                    onTap: () =>
                        onTypeChanged(_ListingDiscoveryType.companionship),
                  ),
                  const SizedBox(width: 8),
                  _DiscoveryChip(
                    label: '一起去做',
                    selected: typeFilter == _ListingDiscoveryType.together,
                    onTap: () => onTypeChanged(_ListingDiscoveryType.together),
                  ),
                  const SizedBox(width: 8),
                  _DiscoveryChip(
                    label: '生活帮忙',
                    selected: typeFilter == _ListingDiscoveryType.lifestyle,
                    onTap: () => onTypeChanged(_ListingDiscoveryType.lifestyle),
                  ),
                  const SizedBox(width: 8),
                  _DiscoveryChip(
                    label: '公益善意',
                    selected: typeFilter == _ListingDiscoveryType.kindness,
                    onTap: () => onTypeChanged(_ListingDiscoveryType.kindness),
                  ),
                  const SizedBox(width: 8),
                  _DiscoveryChip(
                    label: '技能支持',
                    selected: typeFilter == _ListingDiscoveryType.skill,
                    onTap: () => onTypeChanged(_ListingDiscoveryType.skill),
                  ),
                  const SizedBox(width: 8),
                  _DiscoveryChip(
                    label: '仅看加急',
                    selected: urgentOnly,
                    onTap: () => onUrgentChanged(!urgentOnly),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    initialValue: serviceModeFilter,
                    decoration: const InputDecoration(labelText: '服务方式'),
                    items: const [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text('全部方式'),
                      ),
                      DropdownMenuItem<String?>(
                        value: 'OFFLINE',
                        child: Text('线下'),
                      ),
                      DropdownMenuItem<String?>(
                        value: 'ONLINE',
                        child: Text('线上'),
                      ),
                      DropdownMenuItem<String?>(
                        value: 'BOTH',
                        child: Text('线上/线下'),
                      ),
                    ],
                    onChanged: onServiceModeChanged,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<_ListingSortMode>(
                    initialValue: sortMode,
                    decoration: const InputDecoration(labelText: '排序方式'),
                    items: const [
                      DropdownMenuItem(
                        value: _ListingSortMode.newest,
                        child: Text('最新贴出'),
                      ),
                      DropdownMenuItem(
                        value: _ListingSortMode.hottest,
                        child: Text('最热回应'),
                      ),
                      DropdownMenuItem(
                        value: _ListingSortMode.trusted,
                        child: Text('信用优先'),
                      ),
                      DropdownMenuItem(
                        value: _ListingSortMode.budgetHigh,
                        child: Text('预算更高'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        onSortChanged(value);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F4FF),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '当前匹配 $resultCount 条',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                const Spacer(),
                if (onReset != null)
                  TextButton.icon(
                    onPressed: onReset,
                    icon: const Icon(Icons.restart_alt_rounded),
                    label: const Text('清空筛选'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DiscoveryChip extends StatelessWidget {
  const _DiscoveryChip({
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
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF111827) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? const Color(0xFF111827) : const Color(0xFFE5E7EB),
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: selected ? Colors.white : const Color(0xFF344054),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _RegionHeatSection extends StatelessWidget {
  const _RegionHeatSection({
    required this.clusters,
    required this.onCityTap,
    required this.selectedCityCode,
    this.onClearFilter,
  });

  final List<_CityCluster> clusters;
  final ValueChanged<_CityCluster> onCityTap;
  final String? selectedCityCode;
  final VoidCallback? onClearFilter;

  @override
  Widget build(BuildContext context) {
    final selectedCluster = selectedCityCode == null
        ? null
        : clusters
              .where((cluster) => cluster.cityCode == selectedCityCode)
              .firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFFAFAFA),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE7E5E4)),
          ),
          child: _GoogleMapRegionBoard(
            clusters: clusters,
            selectedCityCode: selectedCityCode,
            onCityTap: onCityTap,
          ),
        ),
        if (selectedCluster != null) ...[
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: onClearFilter,
            icon: const Icon(Icons.restart_alt_rounded),
            label: Text('回到全部城市 · 当前 ${selectedCluster.label}'),
          ),
        ] else ...[
          const SizedBox(height: 10),
          Text(
            '拖动地图，或者点下面的城市名称，把 deck 切到那一片。',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}

class _RegionLegend extends StatelessWidget {
  const _RegionLegend({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class _StoryWallSection extends StatelessWidget {
  const _StoryWallSection({required this.stories});

  final List<_StoryWallCardModel> stories;

  @override
  Widget build(BuildContext context) {
    if (stories.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 286,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) => _StoryWallCard(story: stories[index]),
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemCount: stories.length,
      ),
    );
  }
}

class _StoryWallCard extends StatelessWidget {
  const _StoryWallCard({required this.story});

  final _StoryWallCardModel story;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 286,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [
            story.color.withValues(alpha: 0.95),
            story.color.withValues(alpha: 0.78),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x121E1B4B),
            blurRadius: 22,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  story.label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      story.mediaKind == _StoryMediaKind.video
                          ? Icons.play_arrow_rounded
                          : Icons.photo_camera_outlined,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      story.mediaKind == _StoryMediaKind.video ? '短视频' : '照片故事',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 96,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: 14,
                  top: 14,
                  child: Icon(
                    story.icon,
                    color: Colors.white.withValues(alpha: 0.72),
                    size: 28,
                  ),
                ),
                Positioned(
                  left: 14,
                  bottom: 14,
                  child: Text(
                    story.mediaKind == _StoryMediaKind.video
                        ? '现场感更强'
                        : '画面感更强',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            story.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: Colors.white, height: 1.15),
          ),
          const SizedBox(height: 10),
          Text(
            story.summary,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.92),
            ),
          ),
          const Spacer(),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _WhitePill(label: story.cityLabel),
              _WhitePill(label: story.meta),
            ],
          ),
        ],
      ),
    );
  }
}

class _WhitePill extends StatelessWidget {
  const _WhitePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _GoogleMapRegionBoard extends StatelessWidget {
  const _GoogleMapRegionBoard({
    required this.clusters,
    required this.selectedCityCode,
    required this.onCityTap,
  });

  final List<_CityCluster> clusters;
  final String? selectedCityCode;
  final ValueChanged<_CityCluster> onCityTap;

  @override
  Widget build(BuildContext context) {
    final selectedCluster = selectedCityCode == null
        ? null
        : clusters
              .where((cluster) => cluster.cityCode == selectedCityCode)
              .firstOrNull;
    final markers = clusters
        .expand((cluster) => cluster.listings)
        .where((item) => item.longitude != null && item.latitude != null)
        .map((item) {
          return AmapRegionMarkerData(
            id: item.id,
            cityCode: item.cityCode ?? 'unknown',
            label: item.title,
            longitude: item.longitude!,
            latitude: item.latitude!,
            locationText: item.locationText ?? _cityLabel(item.cityCode),
            listingType: item.listingType,
            totalCount: 1,
            taskCount: item.listingType == 'TASK' ? 1 : 0,
            exchangeCount: item.listingType == 'EXCHANGE' ? 1 : 0,
          );
        })
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              selectedCluster == null ? '全国视角' : '${selectedCluster.label} 视角',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: const Color(0xFF18181B),
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F4F5),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${clusters.fold<int>(0, (sum, item) => sum + item.totalCount)} 件事',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 320,
          child: clusters.isEmpty
              ? Center(
                  child: Text(
                    '等公开广场再热一点，这里会自动长出城市信号。',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                )
              : AmapRegionMap(
                  apiKey: aMapWebApiKey,
                  markers: markers,
                  selectedCityCode: selectedCityCode,
                  onCityTap: (cityCode) {
                    final tappedCluster = clusters
                        .where((cluster) => cluster.cityCode == cityCode)
                        .firstOrNull;
                    if (tappedCluster != null) {
                      onCityTap(tappedCluster);
                    }
                  },
                ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _CityFilterChip(
              label: '全部城市',
              count: clusters.fold<int>(0, (sum, item) => sum + item.totalCount),
              selected: selectedCluster == null,
              onTap: () => onCityTap(
                const _CityCluster(
                  cityCode: '',
                  label: '全部城市',
                  listings: <AppListing>[],
                  taskCount: 0,
                  exchangeCount: 0,
                  longitude: 104.0,
                  latitude: 35.0,
                ),
              ),
            ),
            ...clusters.map(
              (cluster) => _CityFilterChip(
                label: cluster.label,
                count: cluster.totalCount,
                selected: cluster.cityCode == selectedCityCode,
                onTap: () => onCityTap(cluster),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CityFilterChip extends StatelessWidget {
  const _CityFilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF18181B) : const Color(0xFFFFFFFF),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? const Color(0xFF18181B)
                  : const Color(0xFFE7E5E4),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: selected ? Colors.white : const Color(0xFF18181B),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.12)
                      : const Color(0xFFF4F4F5),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$count',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: selected ? Colors.white : const Color(0xFF3F3F46),
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

class _CityCluster {
  const _CityCluster({
    required this.cityCode,
    required this.label,
    required this.listings,
    required this.taskCount,
    required this.exchangeCount,
    required this.longitude,
    required this.latitude,
  });

  final String cityCode;
  final String label;
  final List<AppListing> listings;
  final int taskCount;
  final int exchangeCount;
  final double longitude;
  final double latitude;

  int get totalCount => listings.length;
}

List<_CityCluster> _buildCityClusters(List<AppListing> listings) {
  final grouped = <String, List<AppListing>>{};
  for (final listing in listings) {
    final cityCode = listing.cityCode ?? 'unknown';
    grouped.putIfAbsent(cityCode, () => []).add(listing);
  }

  return grouped.entries
      .map((entry) {
        final cityListings = entry.value;
        return _CityCluster(
          cityCode: entry.key,
          label: _cityLabel(entry.key),
          listings: cityListings,
          taskCount: cityListings
              .where((item) => item.listingType == 'TASK')
              .length,
          exchangeCount: cityListings
              .where((item) => item.listingType == 'EXCHANGE')
              .length,
          longitude: _resolveClusterLongitude(entry.key, cityListings),
          latitude: _resolveClusterLatitude(entry.key, cityListings),
        );
      })
      .toList(growable: false)
    ..sort((a, b) => b.totalCount.compareTo(a.totalCount));
}

double _resolveClusterLongitude(String cityCode, List<AppListing> listings) {
  final values = listings
      .where((item) => item.longitude != null && item.latitude != null)
      .map((item) => item.longitude!)
      .toList(growable: false);
  if (values.isNotEmpty) {
    return values.reduce((a, b) => a + b) / values.length;
  }
  return resolveCityCoordinates(cityCode).longitude;
}

double _resolveClusterLatitude(String cityCode, List<AppListing> listings) {
  final values = listings
      .where((item) => item.longitude != null && item.latitude != null)
      .map((item) => item.latitude!)
      .toList(growable: false);
  if (values.isNotEmpty) {
    return values.reduce((a, b) => a + b) / values.length;
  }
  return resolveCityCoordinates(cityCode).latitude;
}

String _cityLabel(String? cityCode) {
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
    case 'xian':
      return '西安';
    case 'nanjing':
      return '南京';
    case 'suzhou':
      return '苏州';
    case 'chongqing':
      return '重庆';
    case 'changsha':
      return '长沙';
    case 'qingdao':
      return '青岛';
    case 'xiamen':
      return '厦门';
    case 'tianjin':
      return '天津';
    case 'unknown':
      return '未知区域';
    default:
      return cityCode ?? '';
  }
}

class _StateCard extends StatelessWidget {
  const _StateCard({
    required this.title,
    required this.description,
    this.tint = const Color(0xFFE9EDFF),
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String description;
  final Color tint;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          color: const Color(0xFFFAFAFA),
          border: Border.all(color: const Color(0xFFE7E5E4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(description, style: Theme.of(context).textTheme.bodyMedium),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 14),
              FilledButton.tonalIcon(
                onPressed: onAction,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ListingCard extends StatelessWidget {
  const _ListingCard({
    required this.listing,
    required this.onTap,
    this.compact = false,
  });

  final AppListing listing;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!;
    final isExchange = listing.listingType == 'EXCHANGE';
    final accentColor = isExchange
        ? const Color(0xFF06B6D4)
        : const Color(0xFFF97316);
    final mood = _listingMoodLabel(listing);
    final teaser = _listingTeaser(listing);
    final scene = _sceneLabel(listing);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Hero(
                          tag: _heroTag('pill', listing.id),
                          child: Material(
                            color: Colors.transparent,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isExchange
                                    ? palette.tertiarySoft
                                    : palette.secondarySoft,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                isExchange ? '技能交换' : '城市小事',
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: accentColor.withValues(alpha: 0.18),
                            ),
                          ),
                          child: Text(
                            mood,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: accentColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (listing.isFeatured)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF2FF),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: const Color(0xFFC7D2FE)),
                            ),
                            child: Text(
                              '推荐',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: const Color(0xFF4338CA),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.arrow_outward_rounded,
                      size: 18,
                      color: accentColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scene,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: accentColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      teaser,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF5B3A15),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Hero(
                tag: _heroTag('title', listing.id),
                child: Material(
                  color: Colors.transparent,
                  child: Text(listing.title, style: theme.textTheme.titleLarge),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                listing.description,
                maxLines: compact ? 3 : 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.local_fire_department_outlined,
                      size: 18,
                      color: accentColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        listing.budgetLabel ?? listing.status,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: accentColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: palette.primarySoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.person_outline, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${listing.publisherName} 发起',
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          scene,
                          style: theme.textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${listing.applicationCount} 次回应',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: accentColor,
                      fontWeight: FontWeight.w700,
                    ),
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

class _CardDeckSection extends StatefulWidget {
  const _CardDeckSection({super.key, required this.listings});

  final List<AppListing> listings;

  @override
  State<_CardDeckSection> createState() => _CardDeckSectionState();
}

class _CardDeckSectionState extends State<_CardDeckSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _swipeController;
  Animation<double>? _swipeAnimation;
  int _currentIndex = 0;
  double _dragDx = 0;
  bool _isDismissing = false;

  @override
  void initState() {
    super.initState();
    _swipeController =
        AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 220),
          )
          ..addListener(() {
            if (_swipeAnimation == null) {
              return;
            }
            setState(() {
              _dragDx = _swipeAnimation!.value;
            });
          })
          ..addStatusListener((status) {
            if (status != AnimationStatus.completed) {
              return;
            }

            if (_isDismissing && widget.listings.isNotEmpty) {
              setState(() {
                _currentIndex = (_currentIndex + 1) % widget.listings.length;
                _dragDx = 0;
                _isDismissing = false;
              });
            } else {
              setState(() {
                _dragDx = 0;
              });
            }
          });
  }

  @override
  void didUpdateWidget(covariant _CardDeckSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.listings.isEmpty) {
      _currentIndex = 0;
      _dragDx = 0;
      return;
    }
    if (_currentIndex >= widget.listings.length) {
      _currentIndex = 0;
    }
  }

  @override
  void dispose() {
    _swipeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listings = widget.listings;
    if (listings.isEmpty) {
      return const SizedBox.shrink();
    }

    final topListing = listings[_currentIndex % listings.length];
    final nextListing = listings[(_currentIndex + 1) % listings.length];
    final thirdListing = listings[(_currentIndex + 2) % listings.length];
    final cardHeight = 438.0;
    final normalized = (_dragDx.abs() / 180).clamp(0.0, 1.0);
    final secondAngle = 0.02 * (1 - (normalized * 0.8));
    final thirdAngle = -0.03 * (1 - (normalized * 0.75));

    return Column(
      children: [
        SizedBox(
          height: cardHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 18,
                right: 116 - (normalized * 10),
                top: 44 - (normalized * 8),
                bottom: 26 - (normalized * 4),
                child: Transform.rotate(
                  angle: thirdAngle,
                  alignment: Alignment.topCenter,
                  child: Transform.scale(
                    scale: 0.96 + (normalized * 0.015),
                    child: Opacity(
                      opacity: 0.78 + (normalized * 0.12),
                      child: IgnorePointer(
                        child: _DeckCard(
                          listing: thirdListing,
                          onTap: () {},
                          muted: true,
                          compact: true,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 10,
                right: 74 - (normalized * 14),
                top: 22 - (normalized * 10),
                bottom: 14 - (normalized * 4),
                child: Transform.rotate(
                  angle: secondAngle,
                  alignment: Alignment.topCenter,
                  child: Transform.scale(
                    scale: 0.985 + (normalized * 0.01),
                    child: Opacity(
                      opacity: 0.88 + (normalized * 0.08),
                      child: IgnorePointer(
                        child: _DeckCard(
                          listing: nextListing,
                          onTap: () {},
                          muted: true,
                          compact: true,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 34,
                top: 0,
                bottom: 32,
                child: Transform.translate(
                  offset: Offset(_dragDx, _dragDx.abs() * -0.04),
                  child: Transform.rotate(
                    angle: (_dragDx / 320) * 0.22,
                    child: GestureDetector(
                      onPanUpdate: (details) {
                        setState(() {
                          _dragDx += details.delta.dx;
                        });
                      },
                      onPanEnd: (_) => _settleTopCard(context),
                      child: _DeckCard(
                        listing: topListing,
                        onTap: () {
                          if (_dragDx.abs() > 8) {
                            return;
                          }
                          Navigator.of(context).push(
                            _playfulRoute(
                              ListingDetailPage(listing: topListing),
                            ),
                          );
                        },
                        overlay: _SwipeHintOverlay(dragDx: _dragDx),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          '左右拖拽当前卡片，像翻 Deck 一样挑今天想接住的事',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  void _settleTopCard(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final shouldDismiss = _dragDx.abs() > 110;
    final target = shouldDismiss ? (_dragDx.isNegative ? -width : width) : 0.0;

    _swipeAnimation = Tween<double>(begin: _dragDx, end: target).animate(
      CurvedAnimation(
        parent: _swipeController,
        curve: shouldDismiss ? Curves.easeOutCubic : Curves.easeOutBack,
      ),
    );

    _isDismissing = shouldDismiss;
    _swipeController
      ..reset()
      ..forward();
  }
}

class _DeckCard extends StatelessWidget {
  const _DeckCard({
    required this.listing,
    required this.onTap,
    this.muted = false,
    this.overlay,
    this.compact = false,
  });

  final AppListing listing;
  final VoidCallback onTap;
  final bool muted;
  final Widget? overlay;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isExchange = listing.listingType == 'EXCHANGE';
    final mood = _listingMoodLabel(listing);
    final teaser = _listingTeaser(listing);
    final scene = _sceneLabel(listing);
    final accent = listing.isFeatured
        ? const Color(0xFFEC4899)
        : const Color(0xFF18181B);
    final locationLabel = listing.locationText ?? _cityLabel(listing.cityCode);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(32),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            color: muted ? const Color(0xFFF7F7F8) : const Color(0xFFFFFFFF),
            border: Border.all(color: const Color(0xFFE7E5E4)),
          ),
          padding: EdgeInsets.all(compact ? 14 : 20),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _MaybeHero(
                              enabled: !muted,
                              tag: _heroTag('pill', listing.id),
                              child: Material(
                                color: Colors.transparent,
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: compact ? 9 : 12,
                                    vertical: compact ? 6 : 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF4F4F5),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    isExchange ? '技能交换' : '城市小事',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: compact ? 8 : 10,
                                vertical: compact ? 5 : 7,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF4F4F5),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                mood,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: const Color(0xFF52525B),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (listing.isFeatured && !compact)
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: compact ? 8 : 10,
                                  vertical: compact ? 5 : 7,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFCE7F3),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(color: const Color(0xFFF9A8D4)),
                                ),
                                child: Text(
                                  '推荐',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: const Color(0xFFBE185D),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F4F5),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          listing.cityCode ?? '同城',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF52525B),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: compact ? 8 : 16),
                  _MaybeHero(
                    enabled: !muted,
                    tag: _heroTag('title', listing.id),
                    child: Material(
                      color: Colors.transparent,
                      child: Text(
                        listing.title,
                        style: theme.textTheme.headlineMedium,
                        maxLines: compact ? 2 : 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  SizedBox(height: compact ? 4 : 10),
                  Text(
                    teaser,
                    maxLines: compact ? 2 : 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                  ),
                  SizedBox(height: compact ? 8 : 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _DeckMetaPill(label: scene),
                      _DeckMetaPill(label: locationLabel),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: EdgeInsets.all(compact ? 8 : 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAFAFA),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFE7E5E4)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: compact ? 32 : 44,
                          height: compact ? 32 : 44,
                          decoration: BoxDecoration(
                            color: listing.isFeatured
                                ? const Color(0xFFFCE7F3)
                                : const Color(0xFFF4F4F5),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.local_fire_department_outlined,
                            color: accent,
                            size: compact ? 16 : 22,
                          ),
                        ),
                        SizedBox(width: compact ? 6 : 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                listing.budgetLabel ?? listing.status,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: accent,
                                ),
                              ),
                              SizedBox(height: compact ? 2 : 4),
                              Text(
                                compact
                                    ? '${listing.applicationCount} 次回应'
                                    : '${listing.publisherName} 发起 · ${listing.applicationCount} 次回应',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        if (!compact) const Icon(Icons.arrow_forward_rounded),
                      ],
                    ),
                  ),
                ],
              ),
              if (overlay != null) Positioned.fill(child: overlay!),
            ],
          ),
        ),
      ),
    );
  }
}

class _MaybeHero extends StatelessWidget {
  const _MaybeHero({
    required this.enabled,
    required this.tag,
    required this.child,
  });

  final bool enabled;
  final String tag;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return child;
    }

    return Hero(tag: tag, child: child);
  }
}

class _DeckMetaPill extends StatelessWidget {
  const _DeckMetaPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F5),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: const Color(0xFF52525B),
        ),
      ),
    );
  }
}

String _heroTag(String part, String listingId) =>
    'home-listing-$part-$listingId';

class _SwipeHintOverlay extends StatelessWidget {
  const _SwipeHintOverlay({required this.dragDx});

  final double dragDx;

  @override
  Widget build(BuildContext context) {
    final isRight = dragDx > 0;
    final progress = (dragDx.abs() / 120).clamp(0.0, 1.0);
    if (progress == 0) {
      return const SizedBox.shrink();
    }

    final color = isRight ? const Color(0xFF18181B) : const Color(0xFF3F3F46);
    final alignment = isRight ? Alignment.topLeft : Alignment.topRight;
    final label = isRight ? '想继续看' : '换下一张';
    final icon = isRight
        ? Icons.favorite_border_rounded
        : Icons.skip_next_rounded;

    return IgnorePointer(
      child: Align(
        alignment: alignment,
        child: Opacity(
          opacity: progress,
          child: Container(
            margin: const EdgeInsets.all(18),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ListSection extends StatelessWidget {
  const _ListSection({super.key, required this.listings});

  final List<AppListing> listings;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(listings.length, (index) {
        final item = listings[index];
        return Padding(
          padding: EdgeInsets.only(
            bottom: index == listings.length - 1 ? 0 : 14,
          ),
          child: _ListingCard(
            listing: item,
            compact: true,
            onTap: () {
              Navigator.of(
                context,
              ).push(_playfulRoute(ListingDetailPage(listing: item)));
            },
          ),
        );
      }),
    );
  }
}

class _ViewToggle extends StatelessWidget {
  const _ViewToggle({required this.value, required this.onChanged});

  final _HomeViewMode value;
  final ValueChanged<_HomeViewMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD9DEFF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleButton(
            selected: value == _HomeViewMode.cards,
            icon: Icons.view_carousel_outlined,
            onTap: () => onChanged(_HomeViewMode.cards),
          ),
          _ToggleButton(
            selected: value == _HomeViewMode.list,
            icon: Icons.view_list_rounded,
            onTap: () => onChanged(_HomeViewMode.list),
          ),
        ],
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  const _ToggleButton({
    required this.selected,
    required this.icon,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          icon,
          size: 20,
          color: selected
              ? Colors.white
              : Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}

class _StoryTag extends StatelessWidget {
  const _StoryTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: Colors.white),
      ),
    );
  }
}

class _AnimatedLift extends StatefulWidget {
  const _AnimatedLift({required this.child});

  final Widget child;

  @override
  State<_AnimatedLift> createState() => _AnimatedLiftState();
}

class _AnimatedLiftState extends State<_AnimatedLift> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

class _StoryWallCardModel {
  const _StoryWallCardModel({
    required this.label,
    required this.title,
    required this.summary,
    required this.cityLabel,
    required this.meta,
    required this.icon,
    required this.color,
    required this.mediaKind,
    this.listingId,
  });

  final String label;
  final String title;
  final String summary;
  final String cityLabel;
  final String meta;
  final IconData icon;
  final Color color;
  final _StoryMediaKind mediaKind;
  final String? listingId;
}

enum _StoryMediaKind { photo, video }

List<_StoryWallCardModel> _buildStoryWallStories({
  required List<AppListing> listings,
  required List<AppListing> myListings,
  required List<AppOrder> myOrders,
}) {
  final combined = [...listings, ...myListings];
  if (combined.isEmpty) {
    return const [];
  }

  final featuredCandidates = [...combined]
    ..sort((a, b) {
      final featuredCompare = b.isFeatured.toString().compareTo(
        a.isFeatured.toString(),
      );
      if (featuredCompare != 0) {
        return featuredCompare;
      }
      final priorityCompare = b.featuredPriority.compareTo(a.featuredPriority);
      if (priorityCompare != 0) {
        return priorityCompare;
      }
      return _storyScore(b).compareTo(_storyScore(a));
    });
  final featuredStory = featuredCandidates.firstOrNull;

  final warmStory =
      [...combined]..sort((a, b) => _warmScore(b).compareTo(_warmScore(a)));
  final wildStory =
      [...combined]..sort((a, b) => _wildScore(b).compareTo(_wildScore(a)));
  final completedOrder = [...myOrders]
    ..sort((a, b) {
      final aTime = a.createdAt?.millisecondsSinceEpoch ?? 0;
      final bTime = b.createdAt?.millisecondsSinceEpoch ?? 0;
      return bTime.compareTo(aTime);
    });

  final cards = <_StoryWallCardModel>[];
  final usedListingIds = <String>{};

  void addListingStory({
    required String label,
    required AppListing? listing,
    required String meta,
    required IconData icon,
    required Color color,
    required _StoryMediaKind mediaKind,
    required String Function(AppListing listing) summaryBuilder,
  }) {
    if (listing == null || usedListingIds.contains(listing.id)) {
      return;
    }
    cards.add(
      _StoryWallCardModel(
        label: label,
        title: listing.title,
        summary: summaryBuilder(listing),
        cityLabel: _cityLabel(listing.cityCode).ifEmpty('城市灵感'),
        meta: meta,
        icon: icon,
        color: color,
        mediaKind: mediaKind,
        listingId: listing.id,
      ),
    );
    usedListingIds.add(listing.id);
  }

  addListingStory(
    label: '最像电影开场的一件事',
    listing: featuredStory,
    meta: featuredStory?.listingType == 'EXCHANGE' ? '精选交换' : '人工精选',
    icon: Icons.auto_awesome_rounded,
    color: const Color(0xFF7C3AED),
    mediaKind: _looksLikeVideoStory(featuredStory)
        ? _StoryMediaKind.video
        : _StoryMediaKind.photo,
    summaryBuilder: _featuredStorySummary,
  );
  addListingStory(
    label: '最温柔的一次托付',
    listing: warmStory.firstOrNull,
    meta: '城市陪伴',
    icon: Icons.favorite_rounded,
    color: const Color(0xFFEC4899),
    mediaKind: _StoryMediaKind.photo,
    summaryBuilder: _warmStorySummary,
  );
  addListingStory(
    label: '这件事居然真的发生了',
    listing: wildStory.firstOrNull,
    meta: '故事感任务',
    icon: Icons.bolt_rounded,
    color: const Color(0xFFF97316),
    mediaKind: _StoryMediaKind.video,
    summaryBuilder: _wildStorySummary,
  );

  final completed = completedOrder
      .where((item) => !usedListingIds.contains(item.listingId))
      .firstOrNull;
  if (completed != null) {
    cards.add(
      _StoryWallCardModel(
        label: '已经被认真做成的一件小事',
        title: completed.listingTitle,
        summary:
            '${_cityLabel(completed.cityCode).ifEmpty('这座城市')}刚刚完成了一笔真实合作，故事最可贵的地方不是“有人围观”，而是真的有人把这件事做成了。',
        cityLabel: _cityLabel(completed.cityCode).ifEmpty('合作完成'),
        meta: completed.listingType == 'EXCHANGE' ? '交换完成' : '任务完成',
        icon: Icons.celebration_rounded,
        color: const Color(0xFF0EA5E9),
        mediaKind: _StoryMediaKind.photo,
        listingId: completed.listingId,
      ),
    );
  }

  return cards.take(4).toList(growable: false);
}

List<StoryFeedItem> _mapToStoryFeedItems(List<_StoryWallCardModel> source) {
  return source
      .map(
        (story) => StoryFeedItem(
          label: story.label,
          title: story.title,
          summary: story.summary,
          body: _storyBodyFromLabel(story),
          city: story.cityLabel,
          tags: [story.meta, story.cityLabel],
          color: story.color,
          category: _storyCategoryFromLabel(story.label),
          listingId: story.listingId,
        ),
      )
      .toList(growable: false);
}

StoryCategory _storyCategoryFromLabel(String label) {
  if (label.contains('温柔')) {
    return StoryCategory.warm;
  }
  if (label.contains('居然')) {
    return StoryCategory.wild;
  }
  if (label.contains('完成')) {
    return StoryCategory.completed;
  }
  return StoryCategory.interesting;
}

String _storyBodyFromLabel(_StoryWallCardModel story) {
  switch (story.label) {
    case '最像电影开场的一件事':
      return '这条任务会被放进故事墙，不是因为它像一条更贵的单子，而是因为它本身自带画面感。有人想把普通生活过得更像电影，有人想去一个城市角落留下证据，这类需求才是确任和传统兼职平台最不一样的地方。';
    case '最温柔的一次托付':
      return '有些任务并不宏大，甚至没有那么“高效”，但它们很像城市里真实发生的求助和陪伴。故事墙想留下的，正是这种在现实生活里不太容易被平台认真对待的小需求。 ';
    case '已经被认真做成的一件小事':
      return '这笔合作已经完成，说明平台不只是停留在“有人贴、有人看”，而是真的有人见面、有人交付、有人把一件事做成。逛逛内容流最值得沉淀的，就是这种已经发生过的真实协作。';
    case '这件事居然真的发生了':
      return '一些任务看起来离谱，但真正让人记住它们的，不是离谱本身，而是那种“这事居然真的会发生在城市里”的真实感。这样的任务更容易被讨论，也更适合变成照片和短视频内容。';
    default:
      return '每一条任务都不只是一个需求说明，它背后往往都藏着一段具体的城市生活。逛逛内容流的意义，就是把这些生活瞬间收集起来，让确任不只是一套撮合系统。';
  }
}

String _sceneLabel(AppListing listing) {
  final location = listing.locationText?.trim();
  if (location != null && location.isNotEmpty) {
    return location;
  }
  return _cityLabel(listing.cityCode).ifEmpty('这座城市的某个角落');
}

String _listingMoodLabel(AppListing listing) {
  final text = '${listing.title} ${listing.description}';
  if (text.contains('生日') || text.contains('电影')) {
    return '仪式感';
  }
  if (text.contains('晚饭') || text.contains('陪') || text.contains('听我')) {
    return '陪伴感';
  }
  if (text.contains('记录') || text.contains('照片') || text.contains('明信片')) {
    return '记录感';
  }
  if (text.contains('生活') || text.contains('房间')) {
    return '生活感';
  }
  if (listing.listingType == 'EXCHANGE') {
    return '互相成全';
  }
  return '认真托付';
}

String _listingTeaser(AppListing listing) {
  final text = listing.description.trim();
  if (text.isEmpty) {
    return '有人把一件小事贴上了任务墙，也在等一个愿意出现的人。';
  }
  if (text.length <= 46) {
    return text;
  }
  return '${text.substring(0, 46)}...';
}

int _storyScore(AppListing listing) {
  var score = 0;
  if (listing.isFeatured) score += 12;
  if (listing.listingType == 'TASK') score += 4;
  score += listing.featuredPriority * 2;
  score += listing.applicationCount;
  score += _warmScore(listing);
  score += _wildScore(listing);
  return score;
}

int _warmScore(AppListing listing) {
  final text = '${listing.title} ${listing.description}'.toLowerCase();
  var score = 0;
  for (final keyword in const [
    '陪',
    '晚饭',
    '长辈',
    '治愈',
    '生日',
    '生活',
    '小计划',
    '听我',
    '一起',
  ]) {
    if (text.contains(keyword)) {
      score += 3;
    }
  }
  if (listing.listingType == 'TASK') {
    score += 2;
  }
  return score;
}

int _wildScore(AppListing listing) {
  final text = '${listing.title} ${listing.description}'.toLowerCase();
  var score = 0;
  for (final keyword in const [
    '电影',
    '故事感',
    '打卡',
    '角落',
    '突然',
    '离谱',
    '第一次',
    '冒险',
    '逛',
  ]) {
    if (text.contains(keyword)) {
      score += 3;
    }
  }
  if (listing.isUrgent) {
    score += 3;
  }
  return score;
}

bool _looksLikeVideoStory(AppListing? listing) {
  if (listing == null) {
    return false;
  }
  final text = '${listing.title} ${listing.description}'.toLowerCase();
  return text.contains('拍') ||
      text.contains('短视频') ||
      text.contains('记录') ||
      text.contains('打卡') ||
      text.contains('电影');
}

String _featuredStorySummary(AppListing listing) {
  final note = listing.opsNote?.trim();
  if (note != null && note.isNotEmpty) {
    return _compactStorySummary(
      note.replaceFirst('运营判断：', '').trim(),
      fallback: '这条任务已经被人工挑出来，说明它不只是能成交，也很容易长成一张有记忆点的故事卡。',
    );
  }
  return _compactStorySummary(
    listing.description,
    fallback: '这条任务已经被人工挑出来，说明它不只是能成交，也很容易长成一张有记忆点的故事卡。',
  );
}

String _warmStorySummary(AppListing listing) {
  return _compactStorySummary(
    listing.description,
    fallback: '这类任务没有很强的工具感，反而更像现实生活里一句认真发出的求助或邀请。',
  );
}

String _wildStorySummary(AppListing listing) {
  return _compactStorySummary(
    listing.description,
    fallback: '这类任务最适合做成“离谱但真”的栏目，因为它自带讨论度，也很有城市气味。',
  );
}

String _compactStorySummary(String value, {required String fallback}) {
  final compact = value.trim();
  if (compact.isEmpty) {
    return fallback;
  }
  return compact.length <= 56 ? compact : '${compact.substring(0, 56)}...';
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}

PageRouteBuilder<void> _playfulRoute(Widget page) {
  return PageRouteBuilder<void>(
    transitionDuration: const Duration(milliseconds: 360),
    reverseTransitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (context, animation, secondaryAnimation) =>
        FadeTransition(opacity: animation, child: page),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final offsetTween = Tween(
        begin: const Offset(0, 0.06),
        end: Offset.zero,
      ).chain(CurveTween(curve: Curves.easeOutCubic));
      return SlideTransition(
        position: animation.drive(offsetTween),
        child: child,
      );
    },
  );
}
