import 'package:flutter/material.dart';

import '../../../core/models/app_order.dart';
import '../../../core/session/app_scope.dart';
import '../../../core/theme/app_theme.dart';
import 'order_detail_page.dart';

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final orders = controller.myOrders;
    final userId = controller.userId;
    final buyerOrders = orders.where((item) => item.buyerId == userId).length;
    final sellerOrders = orders.where((item) => item.sellerId == userId).length;
    final activeOrders = orders.where((item) => item.orderStatus != 'COMPLETED').length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('合作记录'),
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
            colors: [Color(0xFFF7F4FF), Color(0xFFF3FBFF), Color(0xFFFFFCF7)],
          ),
        ),
        child: orders.isEmpty
            ? const _EmptyOrdersState()
            : _OrdersContent(
                orders: orders,
                buyerCount: buyerOrders,
                sellerCount: sellerOrders,
                activeCount: activeOrders,
              ),
      ),
    );
  }
}

class _OrdersContent extends StatefulWidget {
  const _OrdersContent({
    required this.orders,
    required this.buyerCount,
    required this.sellerCount,
    required this.activeCount,
  });

  final List<AppOrder> orders;
  final int buyerCount;
  final int sellerCount;
  final int activeCount;

  @override
  State<_OrdersContent> createState() => _OrdersContentState();
}

enum _OrderFilter { all, buyer, seller, active, done }

class _OrdersContentState extends State<_OrdersContent> {
  _OrderFilter _filter = _OrderFilter.all;
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = widget.orders.where((item) {
      final userId = AppScope.of(context).userId;
      switch (_filter) {
        case _OrderFilter.all:
          return true;
        case _OrderFilter.buyer:
          return item.buyerId == userId;
        case _OrderFilter.seller:
          return item.sellerId == userId;
        case _OrderFilter.active:
          return item.orderStatus != 'COMPLETED';
        case _OrderFilter.done:
          return item.orderStatus == 'COMPLETED';
      }
    }).where((item) {
      if (_search.isEmpty) {
        return true;
      }

      final query = _search.toLowerCase();
      return item.listingTitle.toLowerCase().contains(query) ||
          _statusLabel(item.orderStatus).toLowerCase().contains(query) ||
          _orderTypeLabel(item.orderType).toLowerCase().contains(query);
    }).toList(growable: false);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        _OrdersHero(
          totalCount: widget.orders.length,
          buyerCount: widget.buyerCount,
          sellerCount: widget.sellerCount,
          activeCount: widget.activeCount,
        ),
        const SizedBox(height: 16),
        Text('从哪一侧看这件事', style: theme.textTheme.titleMedium),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _FilterPill(
              label: '全部 ${widget.orders.length}',
              selected: _filter == _OrderFilter.all,
              onTap: () => setState(() => _filter = _OrderFilter.all),
            ),
            _FilterPill(
              label: '发起方 ${widget.buyerCount}',
              selected: _filter == _OrderFilter.buyer,
              onTap: () => setState(() => _filter = _OrderFilter.buyer),
            ),
            _FilterPill(
              label: '回应方 ${widget.sellerCount}',
              selected: _filter == _OrderFilter.seller,
              onTap: () => setState(() => _filter = _OrderFilter.seller),
            ),
            _FilterPill(
              label: '进行中 ${widget.activeCount}',
              selected: _filter == _OrderFilter.active,
              onTap: () => setState(() => _filter = _OrderFilter.active),
            ),
            _FilterPill(
              label: '已完成',
              selected: _filter == _OrderFilter.done,
              onTap: () => setState(() => _filter = _OrderFilter.done),
            ),
          ],
        ),
        const SizedBox(height: 14),
        TextField(
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search_rounded),
            hintText: '搜索合作标题 / 状态',
          ),
          onChanged: (value) {
            setState(() {
              _search = value.trim();
            });
          },
        ),
        const SizedBox(height: 18),
        ...filtered.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _OrderCard(item: item),
          ),
        ),
      ],
    );
  }
}

class _OrdersHero extends StatelessWidget {
  const _OrdersHero({
    required this.totalCount,
    required this.buyerCount,
    required this.sellerCount,
    required this.activeCount,
  });

  final int totalCount;
  final int buyerCount;
  final int sellerCount;
  final int activeCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          colors: [Color(0xFF1D4ED8), Color(0xFF4F46E5), Color(0xFF7C3AED)],
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'COOPERATION LOG',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.white),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '已经接住的事，都在这里继续往下做。',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              height: 1.08,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '不管你是发起的一方，还是回应的一方，都能在这里看到一件事是怎么慢慢被做成的。',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.86),
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _StatTile(label: '总合作', value: '$totalCount', color: Colors.white),
              _StatTile(label: '发起方', value: '$buyerCount', color: const Color(0xFFFFE27A)),
              _StatTile(label: '回应方', value: '$sellerCount', color: const Color(0xFFD9FDE5)),
              _StatTile(label: '进行中', value: '$activeCount', color: const Color(0xFFDDF4FF)),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 2),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
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
          color: selected ? Theme.of(context).colorScheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? Theme.of(context).colorScheme.primary : palette.primarySoft,
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

class _OrderCard extends StatefulWidget {
  const _OrderCard({required this.item});

  final AppOrder item;

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final theme = Theme.of(context);
    final userId = controller.userId;
    final isBuyer = userId == widget.item.buyerId;
    final isSeller = userId == widget.item.sellerId;
    final accent = _statusAccent(widget.item.orderStatus);
    final actions = _buildActions(
      context: context,
      isBuyer: isBuyer,
      isSeller: isSeller,
    );

    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => OrderDetailPage(order: widget.item),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [accent.withValues(alpha: 0.12), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: accent.withValues(alpha: 0.2)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x101E1B4B),
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
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(
                      widget.item.listingType == 'EXCHANGE'
                          ? Icons.swap_horiz_rounded
                          : Icons.receipt_long_rounded,
                      color: accent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.item.listingTitle, style: theme.textTheme.titleLarge),
                        const SizedBox(height: 4),
                        Text(
                          '${_orderTypeLabel(widget.item.orderType)} · ¥${widget.item.amountTotal.toStringAsFixed(0)}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  _StatusBadge(status: widget.item.orderStatus),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MiniTag(label: isBuyer ? '我是发起方' : isSeller ? '我是回应方' : '参与中'),
                  _MiniTag(label: widget.item.listingType == 'EXCHANGE' ? '交换合作' : '任务合作'),
                ],
              ),
              if (actions.isNotEmpty) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: actions,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildActions({
    required BuildContext context,
    required bool isBuyer,
    required bool isSeller,
  }) {
    if (_isSubmitting) {
      return const [FilledButton(onPressed: null, child: Text('处理中...'))];
    }

    final status = widget.item.orderStatus;
    if (isBuyer && status == 'PENDING_PAYMENT') {
      return [
        FilledButton.icon(
          onPressed: () => _run(context, () => AppScope.of(context).payOrder(widget.item.id), '这次托付已经确认。'),
          icon: const Icon(Icons.wallet_rounded),
          label: const Text('确认托付'),
        ),
      ];
    }

    if (isSeller && status == 'PENDING_ACCEPT') {
      return [
        FilledButton.icon(
          onPressed: () => _run(context, () => AppScope.of(context).acceptOrder(widget.item.id), '这件事已经接住。'),
          icon: const Icon(Icons.handshake_rounded),
          label: const Text('接住这件事'),
        ),
      ];
    }

    if (isSeller && status == 'IN_PROGRESS') {
      return [
        FilledButton.icon(
          onPressed: () => _run(context, () => AppScope.of(context).deliverOrder(widget.item.id), '已经标记为做完了。'),
          icon: const Icon(Icons.done_all_rounded),
          label: const Text('标记已做完'),
        ),
      ];
    }

    if (isBuyer && status == 'PENDING_CONFIRMATION') {
      return [
        FilledButton.icon(
          onPressed: () => _run(context, () => AppScope.of(context).confirmOrder(widget.item.id), '这件事已经确认完成。'),
          icon: const Icon(Icons.verified_rounded),
          label: const Text('确认这件事完成'),
        ),
      ];
    }

    return const [];
  }

  Future<void> _run(
    BuildContext context,
    Future<void> Function() action,
    String successMessage,
  ) async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      await action();
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMessage)),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('操作失败：$error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final accent = _statusAccent(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _statusLabel(status),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: accent),
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  const _MiniTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}

class _EmptyOrdersState extends StatelessWidget {
  const _EmptyOrdersState();

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
                  color: const Color(0xFFE8EBFF),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.inventory_2_rounded, size: 34),
              ),
              const SizedBox(height: 18),
              Text('还没有订单', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                '先接住一条回应，再把第一件合作慢慢推进到完成。',
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

Color _statusAccent(String status) {
  switch (status) {
    case 'COMPLETED':
      return const Color(0xFF16A34A);
    case 'PENDING_CONFIRMATION':
      return const Color(0xFFF97316);
    case 'IN_PROGRESS':
      return const Color(0xFF0EA5E9);
    case 'PENDING_ACCEPT':
      return const Color(0xFF7C3AED);
    default:
      return const Color(0xFF4F46E5);
  }
}

String _statusLabel(String status) {
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
    default:
      return status;
  }
}

String _orderTypeLabel(String type) {
  switch (type) {
    case 'EXCHANGE':
      return '交换合作';
    default:
      return '任务合作';
  }
}
