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

    return Scaffold(
      appBar: AppBar(title: const Text('逛逛故事墙')),
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
                      'City stories',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                          ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '把值得被拍下来、被讲出来、被记住的任务，慢慢沉淀成这座城市自己的故事墙。',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          height: 1.08,
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
                    label: '有趣任务',
                    selected: _category == _StoryCategory.interesting,
                    onTap: () => setState(() => _category = _StoryCategory.interesting),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: '温柔任务',
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
                    label: '合作完成',
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
      appBar: AppBar(title: const Text('故事详情')),
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
            children: story.tags.map((tag) => _TagPill(label: tag)).toList(growable: false),
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
