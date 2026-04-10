import 'package:flutter/material.dart';

import '../../../core/models/app_listing.dart';
import '../../listings/presentation/listing_detail_page.dart';

class StoryFeedPage extends StatefulWidget {
  const StoryFeedPage({
    super.key,
    required this.stories,
    required this.listings,
  });

  final List<StoryFeedItem> stories;
  final List<AppListing> listings;

  @override
  State<StoryFeedPage> createState() => _StoryFeedPageState();
}

enum _StoryCategory { all, interesting, warm, wild, completed }

class _StoryFeedPageState extends State<StoryFeedPage> {
  _StoryCategory _category = _StoryCategory.all;

  @override
  Widget build(BuildContext context) {
    final stories = widget.stories.where((item) {
      switch (_category) {
        case _StoryCategory.all:
          return true;
        case _StoryCategory.interesting:
          return item.category == StoryCategory.interesting;
        case _StoryCategory.warm:
          return item.category == StoryCategory.warm;
        case _StoryCategory.wild:
          return item.category == StoryCategory.wild;
        case _StoryCategory.completed:
          return item.category == StoryCategory.completed;
      }
    }).toList(growable: false);

    final cityTopics = _buildCityTopics(widget.listings);
    final hosts = _buildHosts(widget.listings);
    final officialEvents = _buildOfficialEvents(widget.listings, cityTopics);

    return Scaffold(
      appBar: AppBar(title: const Text('逛逛')),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFBF5), Color(0xFFF8F5FF), Color(0xFFF6FBFF)],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFFEC4899), Color(0xFFF97316)],
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
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'CITY STORIES',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                          ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '把那些最像电影开场、最温柔、也最值得被讲出来的小事，慢慢留在这座城市里。',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          height: 1.08,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '你可以从一件小事开始逛，再顺着城市、发起人和官方发起，看到这座城正在发生什么。',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.92),
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _FilterChip(
                    label: '全部',
                    selected: _category == _StoryCategory.all,
                    onTap: () => setState(() => _category = _StoryCategory.all),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: '像电影一样',
                    selected: _category == _StoryCategory.interesting,
                    onTap: () => setState(() => _category = _StoryCategory.interesting),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: '温柔托付',
                    selected: _category == _StoryCategory.warm,
                    onTap: () => setState(() => _category = _StoryCategory.warm),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: '离谱但真',
                    selected: _category == _StoryCategory.wild,
                    onTap: () => setState(() => _category = _StoryCategory.wild),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: '已经做成',
                    selected: _category == _StoryCategory.completed,
                    onTap: () => setState(() => _category = _StoryCategory.completed),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ...stories.map(
              (story) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _StoryFeedCard(
                  story: story,
                  listings: widget.listings,
                ),
              ),
            ),
            const SizedBox(height: 10),
            _SectionTitle(
              title: '从哪座城市开始逛',
              subtitle: '每个城市都该有自己的气味、故事和适合先看的那几件小事。',
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 190,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: cityTopics.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) => _CityTopicCard(
                  topic: cityTopics[index],
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => _CityTopicDetailPage(
                          topic: cityTopics[index],
                          listings: widget.listings,
                          stories: widget.stories,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 22),
            _SectionTitle(
              title: '先跟这些人逛',
              subtitle: '他们更会发起有画面感的小事，也更像这座城里愿意认真托付和认真帮忙的人。',
            ),
            const SizedBox(height: 12),
            ...hosts.map(
              (host) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _HostCard(
                  host: host,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => _HostDetailPage(
                          host: host,
                          listings: widget.listings,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 10),
            _SectionTitle(
              title: '本周官方发起',
              subtitle: '先把能真正带动城市气氛的发起放进来，让官方不只是公告，而是内容的一部分。',
            ),
            const SizedBox(height: 12),
            ...officialEvents.map(
              (event) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _OfficialEventCard(
                  event: event,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => _OfficialEventDetailPage(
                          event: event,
                          listings: widget.listings,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 6),
        Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
      ],
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
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF111827) : Colors.white,
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

class _StoryFeedCard extends StatelessWidget {
  const _StoryFeedCard({
    required this.story,
    required this.listings,
  });

  final StoryFeedItem story;
  final List<AppListing> listings;

  @override
  Widget build(BuildContext context) {
    final linkedListing = story.listingId == null
        ? null
        : listings.where((item) => item.id == story.listingId).firstOrNull;

    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => _StoryDetailPage(
              story: story,
              listing: linkedListing,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
              color: Color(0x121E1B4B),
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
                    color: story.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    story.label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: story.color,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                const Spacer(),
                Text(story.city, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 14),
            Text(story.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            Text(story.summary, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...story.tags.map((tag) => _TagPill(label: tag)),
                if (linkedListing != null) const _TagPill(label: '可回到任务详情'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CityTopicCard extends StatelessWidget {
  const _CityTopicCard({
    required this.topic,
    required this.onTap,
  });

  final _CityTopic topic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Ink(
        width: 250,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            colors: [topic.color, topic.color.withValues(alpha: 0.82)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              topic.cityLabel,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                  ),
            ),
            const SizedBox(height: 10),
            Text(
              topic.summary,
              maxLines: 3,
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
                _WhiteStat(label: '${topic.listingCount} 条任务'),
                _WhiteStat(label: '${topic.storyCount} 张故事卡'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HostCard extends StatelessWidget {
  const _HostCard({
    required this.host,
    required this.onTap,
  });

  final _HostProfile host;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(26),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          boxShadow: const [
            BoxShadow(
              color: Color(0x121E1B4B),
              blurRadius: 18,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: host.color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(Icons.workspace_premium_rounded, color: host.color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(host.name, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    '${host.cityLabel} · ${host.roleLabel}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Text(host.bio, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('信用 ${host.creditScore}', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 6),
                Text('${host.listingCount} 条发布', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OfficialEventCard extends StatelessWidget {
  const _OfficialEventCard({
    required this.event,
    required this.onTap,
  });

  final _OfficialEvent event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(26),
      child: Ink(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE9D5FF)),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: event.color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.celebration_rounded, color: event.color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(
                    '${event.cityLabel} · ${event.dateLabel}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Text(event.summary, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoryDetailPage extends StatelessWidget {
  const _StoryDetailPage({
    required this.story,
    required this.listing,
  });

  final StoryFeedItem story;
  final AppListing? listing;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('这件小事的故事')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: LinearGradient(
                colors: [
                  story.color,
                  story.color.withValues(alpha: 0.82),
                  const Color(0xFF111827),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  story.label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  story.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                      ),
                ),
                const SizedBox(height: 10),
                Text(
                  story.city,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.88),
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('故事正文', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  Text(story.body, style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: story.tags
                .map((tag) => _TagPill(label: tag))
                .toList(growable: false),
          ),
        ],
      ),
      bottomNavigationBar: listing == null
          ? null
          : SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ListingDetailPage(listing: listing!),
                    ),
                  );
                },
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('回到对应任务'),
              ),
            ),
    );
  }
}

class _CityTopicDetailPage extends StatelessWidget {
  const _CityTopicDetailPage({
    required this.topic,
    required this.listings,
    required this.stories,
  });

  final _CityTopic topic;
  final List<AppListing> listings;
  final List<StoryFeedItem> stories;

  @override
  Widget build(BuildContext context) {
    final cityListings = listings
        .where((item) => _cityLabel(item.cityCode) == topic.cityLabel)
        .toList(growable: false);
    final cityStories = stories
        .where((item) => item.city == topic.cityLabel)
        .toList(growable: false);

    return Scaffold(
      appBar: AppBar(title: Text('${topic.cityLabel} 专题')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          _TopicHero(
            title: '${topic.cityLabel} 城市专题',
            subtitle: topic.summary,
            color: topic.color,
          ),
          const SizedBox(height: 16),
          _SectionTitle(
            title: '这座城市正在发生',
            subtitle: '优先看同城更有故事感和讨论度的任务。',
          ),
          const SizedBox(height: 12),
          ...cityListings.take(5).map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _LinkedListingCard(listing: item),
            ),
          ),
          if (cityStories.isNotEmpty) ...[
            const SizedBox(height: 12),
            _SectionTitle(
              title: '同城故事卡',
              subtitle: '把任务和完成合作沉淀成这座城市自己的内容面貌。',
            ),
            const SizedBox(height: 12),
            ...cityStories.take(3).map(
              (story) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(story.label, style: Theme.of(context).textTheme.bodySmall),
                        const SizedBox(height: 8),
                        Text(story.title, style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text(story.summary, style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HostDetailPage extends StatelessWidget {
  const _HostDetailPage({
    required this.host,
    required this.listings,
  });

  final _HostProfile host;
  final List<AppListing> listings;

  @override
  Widget build(BuildContext context) {
    final hostListings = listings
        .where((item) => item.publisherName == host.name)
        .toList(growable: false);

    return Scaffold(
      appBar: AppBar(title: const Text('和这个人继续逛')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          _TopicHero(
            title: host.name,
            subtitle: '${host.cityLabel} · ${host.roleLabel}\n${host.bio}',
            color: host.color,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _TagPill(label: '信用 ${host.creditScore}'),
              _TagPill(label: '${host.listingCount} 条发布'),
              _TagPill(label: host.cityLabel),
            ],
          ),
          const SizedBox(height: 16),
          _SectionTitle(
            title: '他最近发起的小事',
            subtitle: '先看看这个人最近在这座城市里，更愿意认真发起什么样的任务。',
          ),
          const SizedBox(height: 12),
          ...hostListings.take(5).map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _LinkedListingCard(listing: item),
            ),
          ),
        ],
      ),
    );
  }
}

class _OfficialEventDetailPage extends StatelessWidget {
  const _OfficialEventDetailPage({
    required this.event,
    required this.listings,
  });

  final _OfficialEvent event;
  final List<AppListing> listings;

  @override
  Widget build(BuildContext context) {
    final cityListings = listings
        .where((item) => _cityLabel(item.cityCode) == event.cityLabel)
        .take(5)
        .toList(growable: false);

    return Scaffold(
      appBar: AppBar(title: const Text('官方发起')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          _TopicHero(
            title: event.title,
            subtitle: '${event.cityLabel} · ${event.dateLabel}\n${event.summary}',
            color: event.color,
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('活动说明', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 10),
                  Text(
                    '这类官方发起不只是公告，更像给一座城定一个气氛。它可以把任务、故事和线下节奏轻轻串起来，让人知道这周值得从哪里开始逛。',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _SectionTitle(
            title: '活动相关任务',
            subtitle: '先从这座城市里气质最接近的几件小事开始，看活动怎么和真实任务连起来。',
          ),
          const SizedBox(height: 12),
          ...cityListings.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _LinkedListingCard(listing: item),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopicHero extends StatelessWidget {
  const _TopicHero({
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.8), const Color(0xFF111827)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.92),
                  height: 1.4,
                ),
          ),
        ],
      ),
    );
  }
}

class _LinkedListingCard extends StatelessWidget {
  const _LinkedListingCard({required this.listing});

  final AppListing listing;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ListingDetailPage(listing: listing),
          ),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x121E1B4B),
              blurRadius: 16,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    listing.locationText ?? _cityLabel(listing.cityCode),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (listing.budgetAmount != null)
                  Text(
                    '¥${listing.budgetAmount!.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                const SizedBox(height: 6),
                Text(
                  '${listing.applicationCount} 申请',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WhiteStat extends StatelessWidget {
  const _WhiteStat({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white,
            ),
      ),
    );
  }
}

class _TagPill extends StatelessWidget {
  const _TagPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7FB),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}

enum StoryCategory { interesting, warm, wild, completed }

class StoryFeedItem {
  const StoryFeedItem({
    required this.label,
    required this.title,
    required this.summary,
    required this.body,
    required this.city,
    required this.tags,
    required this.color,
    required this.category,
    this.listingId,
  });

  final String label;
  final String title;
  final String summary;
  final String body;
  final String city;
  final List<String> tags;
  final Color color;
  final StoryCategory category;
  final String? listingId;
}

class _CityTopic {
  const _CityTopic({
    required this.cityLabel,
    required this.summary,
    required this.listingCount,
    required this.storyCount,
    required this.color,
  });

  final String cityLabel;
  final String summary;
  final int listingCount;
  final int storyCount;
  final Color color;
}

class _HostProfile {
  const _HostProfile({
    required this.name,
    required this.cityLabel,
    required this.roleLabel,
    required this.bio,
    required this.creditScore,
    required this.listingCount,
    required this.color,
  });

  final String name;
  final String cityLabel;
  final String roleLabel;
  final String bio;
  final int creditScore;
  final int listingCount;
  final Color color;
}

class _OfficialEvent {
  const _OfficialEvent({
    required this.title,
    required this.cityLabel,
    required this.dateLabel,
    required this.summary,
    required this.color,
  });

  final String title;
  final String cityLabel;
  final String dateLabel;
  final String summary;
  final Color color;
}

List<_CityTopic> _buildCityTopics(List<AppListing> listings) {
  final buckets = <String, List<AppListing>>{};
  for (final item in listings) {
    final city = _cityLabel(item.cityCode);
    buckets.putIfAbsent(city, () => []).add(item);
  }
  const colors = [
    Color(0xFF7C3AED),
    Color(0xFFEC4899),
    Color(0xFFF97316),
    Color(0xFF0EA5E9),
  ];
  final entries = buckets.entries.toList(growable: false)
    ..sort((a, b) => b.value.length.compareTo(a.value.length));
  return entries.take(4).toList().asMap().entries.map((entry) {
    final city = entry.value.key;
    final items = entry.value.value;
    final featured = items.where((item) => item.isFeatured).length;
    return _CityTopic(
      cityLabel: city,
      summary: '$city 现在有 ${items.length} 条任务在流动，其中 ${featured == 0 ? '已有稳定内容节奏' : '$featured 条正在被重点运营'}，很适合长成一张城市专题页。',
      listingCount: items.length,
      storyCount: items.take(3).length,
      color: colors[entry.key % colors.length],
    );
  }).toList(growable: false);
}

List<_HostProfile> _buildHosts(List<AppListing> listings) {
  final grouped = <String, List<AppListing>>{};
  for (final item in listings) {
    grouped.putIfAbsent(item.publisherName, () => []).add(item);
  }
  const colors = [
    Color(0xFF7C3AED),
    Color(0xFF0EA5E9),
    Color(0xFFF97316),
    Color(0xFFEC4899),
  ];
  final entries = grouped.entries.toList(growable: false)
    ..sort((a, b) {
      final aScore = a.value.fold<int>(
        0,
        (sum, item) => sum + (item.publisherCreditScore ?? 0) + item.applicationCount,
      );
      final bScore = b.value.fold<int>(
        0,
        (sum, item) => sum + (item.publisherCreditScore ?? 0) + item.applicationCount,
      );
      return bScore.compareTo(aScore);
    });
  return entries.take(4).toList().asMap().entries.map((entry) {
    final items = entry.value.value;
    final sample = items.first;
    return _HostProfile(
      name: entry.value.key,
      cityLabel: _cityLabel(sample.cityCode),
      roleLabel: sample.isFeatured ? '城市主理人候选' : '内容主理人候选',
      bio: '更懂 ${_cityLabel(sample.cityCode)} 这座城市里什么样的任务值得被先看到、先拍下来、先讲出来。',
      creditScore: sample.publisherCreditScore ?? 100,
      listingCount: items.length,
      color: colors[entry.key % colors.length],
    );
  }).toList(growable: false);
}

List<_OfficialEvent> _buildOfficialEvents(
  List<AppListing> listings,
  List<_CityTopic> topics,
) {
  const colors = [
    Color(0xFF7C3AED),
    Color(0xFF0EA5E9),
    Color(0xFFF97316),
  ];
  return topics.take(3).toList().asMap().entries.map((entry) {
    final topic = entry.value;
    final matching = listings.where((item) => _cityLabel(item.cityCode) == topic.cityLabel);
    final taskCount = matching.length;
    return _OfficialEvent(
      title: '${topic.cityLabel} 城市灵感周',
      cityLabel: topic.cityLabel,
      dateLabel: '本周六 15:00',
      summary: '围绕 ${topic.cityLabel} 当前更有故事感的 $taskCount 条任务，做一场“看任务、拍故事、找灵感”的官方内容活动。',
      color: colors[entry.key % colors.length],
    );
  }).toList(growable: false);
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
