import 'package:flutter/material.dart';

import '../../../core/models/app_application.dart';
import '../../../core/models/app_order.dart';
import '../../../core/session/app_scope.dart';
import '../../listings/presentation/listing_detail_page.dart';
import '../../orders/presentation/order_detail_page.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  String _search = '';
  _ConversationLane _lane = _ConversationLane.all;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final conversations = _buildConversations(
      applications: controller.myApplications,
      orders: controller.myOrders,
      currentUserId: controller.userId,
    );
    final filtered = conversations.where((item) {
      if (_lane == _ConversationLane.orders && item.kind != _ConversationKind.order) {
        return false;
      }
      if (_lane == _ConversationLane.applications &&
          item.kind != _ConversationKind.application) {
        return false;
      }

      if (_search.isEmpty) {
        return true;
      }

      final query = _search.toLowerCase();
      return item.title.toLowerCase().contains(query) ||
          item.listingTitle.toLowerCase().contains(query) ||
          item.preview.toLowerCase().contains(query) ||
          item.cityLabel.toLowerCase().contains(query);
    }).toList(growable: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('回应'),
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
            colors: [Color(0xFFF8F5FF), Color(0xFFF6FBFF), Color(0xFFFFFBF4)],
          ),
        ),
        child: conversations.isEmpty
            ? const _EmptyMessagesState()
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                children: [
                  _MessagesHero(
                    totalCount: conversations.length,
                    orderCount: controller.myOrders.length,
                    applicationCount: controller.myApplications.length,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search_rounded),
                      hintText: '搜索回应对象 / 任务标题 / 城市',
                    ),
                    onChanged: (value) {
                      setState(() {
                        _search = value.trim();
                      });
                    },
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _LaneChip(
                        label: '全部',
                        selected: _lane == _ConversationLane.all,
                        onTap: () => setState(() => _lane = _ConversationLane.all),
                      ),
                      _LaneChip(
                        label: '合作推进',
                        selected: _lane == _ConversationLane.orders,
                        onTap: () => setState(() => _lane = _ConversationLane.orders),
                      ),
                      _LaneChip(
                        label: '回应往来',
                        selected: _lane == _ConversationLane.applications,
                        onTap: () =>
                            setState(() => _lane = _ConversationLane.applications),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  ...filtered.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _ConversationCard(item: item),
                    ),
                  ),
                  if (filtered.isEmpty) const _ConversationEmptyResult(),
                ],
              ),
      ),
    );
  }
}

class _MessagesHero extends StatelessWidget {
  const _MessagesHero({
    required this.totalCount,
    required this.orderCount,
    required this.applicationCount,
  });

  final int totalCount;
  final int orderCount;
  final int applicationCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          colors: [Color(0xFF155EEF), Color(0xFF7C3AED), Color(0xFFF97316)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22155EEF),
            blurRadius: 30,
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
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'RESPONSE WALL',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.white),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '把回应、建单、交付和确认，收进一条真正能追踪的合作记录。',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              height: 1.08,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '这里先承接你发出的回应、你收到的反馈，以及一件事一步步被做成的过程。',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.88),
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _HeroStat(label: '回应记录', value: '$totalCount'),
              _HeroStat(label: '合作推进', value: '$orderCount'),
              _HeroStat(label: '我的回应', value: '$applicationCount'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 108,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.17),
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

class _LaneChip extends StatelessWidget {
  const _LaneChip({
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
          color: selected ? const Color(0xFF1D4ED8) : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? const Color(0xFF1D4ED8) : const Color(0xFFE6E9F4),
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

class _ConversationCard extends StatelessWidget {
  const _ConversationCard({required this.item});

  final _ConversationItem item;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => _ConversationDetailPage(item: item),
          ),
        );
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
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: item.kind == _ConversationKind.order
                      ? const [Color(0xFF0EA5E9), Color(0xFF155EEF)]
                      : const [Color(0xFFF97316), Color(0xFF7C3AED)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: Icon(
                item.kind == _ConversationKind.order
                    ? Icons.mark_chat_read_rounded
                    : Icons.forum_rounded,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: Theme.of(context).textTheme.titleLarge,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        item.timeLabel,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.listingTitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF475467),
                        ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    item.preview,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _MetaChip(
                        label: item.kind == _ConversationKind.order ? '合作推进' : '回应往来',
                      ),
                      _MetaChip(label: item.statusLabel),
                      if (item.cityLabel.isNotEmpty) _MetaChip(label: item.cityLabel),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationDetailPage extends StatefulWidget {
  const _ConversationDetailPage({required this.item});

  final _ConversationItem item;

  @override
  State<_ConversationDetailPage> createState() => _ConversationDetailPageState();
}

class _ConversationDetailPageState extends State<_ConversationDetailPage> {
  final TextEditingController _draftController = TextEditingController();
  final List<String> _draftMessages = [];

  @override
  void dispose() {
    _draftController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listing = widget.item.resolveListing(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item.title),
        actions: [
          if (widget.item.order != null)
            IconButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => OrderDetailPage(order: widget.item.order!),
                  ),
                );
              },
              icon: const Icon(Icons.receipt_long_rounded),
            ),
          if (listing != null)
            IconButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ListingDetailPage(listing: listing),
                  ),
                );
              },
              icon: const Icon(Icons.open_in_new_rounded),
            ),
        ],
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8F5FF), Color(0xFFF7FBFF), Color(0xFFFFFBF6)],
          ),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                gradient: const LinearGradient(
                  colors: [Color(0xFF111827), Color(0xFF1D4ED8), Color(0xFF06B6D4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.item.listingTitle,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.item.heroSubtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.88),
                        ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _InvertedChip(label: widget.item.statusLabel),
                      _InvertedChip(
                        label: widget.item.kind == _ConversationKind.order ? '合作记录' : '回应记录',
                      ),
                      if (widget.item.cityLabel.isNotEmpty)
                        _InvertedChip(label: widget.item.cityLabel),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0EAFF),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.tips_and_updates_rounded),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '这里先把关键留言、回应状态和合作推进节点收进一条可追踪记录里。',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...widget.item.messages.map(
                    (message) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: message.kind == _ChatMessageKind.system
                          ? _SystemCard(message: message)
                          : _ChatBubble(message: message),
                    ),
                  ),
                  ..._draftMessages.map(
                    (message) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ChatBubble(
                        message: _ChatMessage(
                          kind: _ChatMessageKind.outgoing,
                          content: message,
                          timestamp: DateTime.now(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _draftController,
                      minLines: 1,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: '先写一条临时会话草稿，后面会接真实即时消息…',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: () {
                      final text = _draftController.text.trim();
                      if (text.isEmpty) {
                        return;
                      }
                      setState(() {
                        _draftMessages.add(text);
                        _draftController.clear();
                      });
                    },
                    icon: const Icon(Icons.send_rounded),
                    label: const Text('发送'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});

  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isOutgoing = message.kind == _ChatMessageKind.outgoing;
    final background = isOutgoing ? const Color(0xFF155EEF) : Colors.white;
    final color = isOutgoing ? Colors.white : Theme.of(context).colorScheme.onSurface;

    return Align(
      alignment: isOutgoing ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 340),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x101E1B4B),
              blurRadius: 16,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: color),
            ),
            const SizedBox(height: 6),
            Text(
              _formatTime(message.timestamp),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isOutgoing ? Colors.white70 : null,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SystemCard extends StatelessWidget {
  const _SystemCard({required this.message});

  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F7FF),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFD9CFFE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, size: 18),
              const SizedBox(width: 8),
              Text('系统节点', style: Theme.of(context).textTheme.titleSmall),
              const Spacer(),
              Text(
                _formatTime(message.timestamp),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(message.content, style: Theme.of(context).textTheme.bodyMedium),
        ],
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

class _InvertedChip extends StatelessWidget {
  const _InvertedChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white),
      ),
    );
  }
}

class _ConversationEmptyResult extends StatelessWidget {
  const _ConversationEmptyResult();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        children: [
          const Icon(Icons.search_off_rounded, size: 30),
          const SizedBox(height: 10),
          Text('没有找到匹配的会话', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            '换个关键词试试，或者切到别的会话类型看看。',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _EmptyMessagesState extends StatelessWidget {
  const _EmptyMessagesState();

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
                child: const Icon(Icons.chat_bubble_outline_rounded, size: 34),
              ),
              const SizedBox(height: 18),
              Text('还没有会话', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                '先去回应一件任务，或者推进一笔合作，这里就会开始形成真正的来回记录。',
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

enum _ConversationLane { all, orders, applications }

enum _ConversationKind { application, order }

enum _ChatMessageKind { outgoing, system }

class _ConversationItem {
  const _ConversationItem({
    required this.id,
    required this.kind,
    required this.title,
    required this.listingTitle,
    required this.preview,
    required this.statusLabel,
    required this.messages,
    this.application,
    this.order,
    this.cityLabel = '',
    this.timestamp,
  });

  final String id;
  final _ConversationKind kind;
  final String title;
  final String listingTitle;
  final String preview;
  final String statusLabel;
  final List<_ChatMessage> messages;
  final AppApplication? application;
  final AppOrder? order;
  final String cityLabel;
  final DateTime? timestamp;

  String get timeLabel => timestamp == null ? '--:--' : _formatTime(timestamp!);

  String get heroSubtitle {
    if (kind == _ConversationKind.order) {
      return '这条会话正在推进真实订单节点，后续会持续记录支付、接单、交付和确认。';
    }
    return '这条会话从一次回应开始，后续会持续记录反馈、接住结果和建单动作。';
  }

  dynamic resolveListing(BuildContext context) {
    final controller = AppScope.of(context);
    final listingId = application?.listingId ?? order?.listingId;
    if (listingId == null) {
      return null;
    }
    return [...controller.listings, ...controller.myListings]
        .where((item) => item.id == listingId)
        .firstOrNull;
  }
}

class _ChatMessage {
  const _ChatMessage({
    required this.kind,
    required this.content,
    required this.timestamp,
  });

  final _ChatMessageKind kind;
  final String content;
  final DateTime timestamp;
}

List<_ConversationItem> _buildConversations({
  required List<AppApplication> applications,
  required List<AppOrder> orders,
  required String? currentUserId,
}) {
  final items = <_ConversationItem>[
    ...applications.map((item) {
      final title = item.publisherName ?? '发布者';
      final createdAt = item.createdAt ?? DateTime.now();
      final messages = <_ChatMessage>[
        _ChatMessage(
          kind: _ChatMessageKind.system,
          content: '你向“${item.listingTitle}”发出了一次回应，系统会继续同步处理进度。',
          timestamp: createdAt,
        ),
        if (item.message.trim().isNotEmpty)
          _ChatMessage(
            kind: _ChatMessageKind.outgoing,
            content: item.message,
            timestamp: createdAt,
          ),
        if (item.quotedPrice != null)
          _ChatMessage(
            kind: _ChatMessageKind.system,
            content: '你给出的报价是 ¥${item.quotedPrice!.toStringAsFixed(0)}。',
            timestamp: createdAt,
          ),
        _ChatMessage(
          kind: _ChatMessageKind.system,
          content: _applicationSystemHint(item.status),
          timestamp: createdAt,
        ),
      ];

      return _ConversationItem(
        id: 'app-${item.id}',
        kind: _ConversationKind.application,
        title: title,
        listingTitle: item.listingTitle,
        preview: _applicationSystemHint(item.status),
        statusLabel: _applicationStatusLabel(item.status),
        messages: messages,
        application: item,
        cityLabel: _cityLabel(item.cityCode),
        timestamp: createdAt,
      );
    }),
    ...orders.map((item) {
      final counterpart = currentUserId == item.buyerId
          ? (item.sellerName ?? '服务方')
          : (item.buyerName ?? '需求方');
      final createdAt = item.createdAt ?? DateTime.now();
      final messages = <_ChatMessage>[
        _ChatMessage(
          kind: _ChatMessageKind.system,
          content: '订单已创建，合作进入“${_orderStatusLabel(item.orderStatus)}”阶段。',
          timestamp: createdAt,
        ),
        _ChatMessage(
          kind: _ChatMessageKind.system,
          content: '当前金额 ¥${item.amountTotal.toStringAsFixed(0)}，系统会继续同步支付、接单、交付和确认节点。',
          timestamp: createdAt,
        ),
        _ChatMessage(
          kind: _ChatMessageKind.system,
          content: _orderSystemHint(item.orderStatus, currentUserId == item.buyerId),
          timestamp: createdAt,
        ),
      ];

      return _ConversationItem(
        id: 'order-${item.id}',
        kind: _ConversationKind.order,
        title: counterpart,
        listingTitle: item.listingTitle,
        preview: '订单当前状态：${_orderStatusLabel(item.orderStatus)}',
        statusLabel: _orderStatusLabel(item.orderStatus),
        messages: messages,
        order: item,
        timestamp: createdAt,
      );
    }),
  ];

  items.sort((a, b) => (b.timestamp ?? DateTime(2000)).compareTo(a.timestamp ?? DateTime(2000)));
  return items;
}

String _applicationSystemHint(String status) {
  switch (status) {
    case 'PENDING':
      return '发布者还在查看这次回应，保持在线会更容易接上下一步。';
    case 'ACCEPTED':
      return '你的回应已经被接住，下一步通常会进入建单和推进协作。';
    case 'REJECTED':
      return '这次回应没有被接住，你可以继续挑下一条更合适的事。';
    case 'WITHDRAWN':
      return '这次回应已经撤回，之后如果合适还可以重新发起。';
    default:
      return '系统会继续同步这次回应的后续进展。';
  }
}

String _applicationStatusLabel(String status) {
  switch (status) {
    case 'PENDING':
      return '待回应';
    case 'ACCEPTED':
      return '已接住';
    case 'REJECTED':
      return '已谢绝';
    case 'WITHDRAWN':
      return '已撤回';
    default:
      return status;
  }
}

String _orderStatusLabel(String status) {
  switch (status) {
    case 'PENDING_PAYMENT':
      return '待支付';
    case 'PENDING_ACCEPT':
      return '待接单';
    case 'IN_PROGRESS':
      return '进行中';
    case 'PENDING_CONFIRMATION':
      return '待确认';
    case 'COMPLETED':
      return '已完成';
    case 'REFUND_REQUESTED':
      return '退款处理中';
    default:
      return status;
  }
}

String _orderSystemHint(String status, bool isBuyer) {
  switch (status) {
    case 'PENDING_PAYMENT':
      return isBuyer ? '你这边需要先完成开发支付，合作才能正式开始。' : '对方支付后，你就可以进入接单阶段。';
    case 'PENDING_ACCEPT':
      return isBuyer ? '服务方正在确认是否接单，系统会同步下一步。' : '现在轮到你确认接单，接单后订单会进入进行中。';
    case 'IN_PROGRESS':
      return isBuyer ? '合作已经开始，后面会进入交付和确认环节。' : '合作进行中，准备好后可以标记交付。';
    case 'PENDING_CONFIRMATION':
      return isBuyer ? '服务方已经标记交付，现在轮到你确认完成。' : '你已经交付，等待对方确认完成。';
    case 'COMPLETED':
      return '这笔合作已经完成，现在可以沉淀评价和信用记录。';
    case 'REFUND_REQUESTED':
      return '当前订单正在处理退款流程，建议保持沟通并等待处理结果。';
    default:
      return '系统会继续同步这笔订单的后续状态。';
  }
}

String _cityLabel(String? cityCode) {
  switch (cityCode) {
    case 'shanghai':
      return '上海';
    case 'beijing':
      return '北京';
    case 'hangzhou':
      return '杭州';
    case 'shenzhen':
      return '深圳';
    default:
      return cityCode == null || cityCode.isEmpty ? '' : cityCode;
  }
}

String _formatTime(DateTime value) {
  return '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}
