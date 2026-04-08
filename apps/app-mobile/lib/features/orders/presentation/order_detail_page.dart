import 'package:flutter/material.dart';

import '../../../core/models/app_order.dart';
import '../../../core/models/app_order_detail.dart';
import '../../../core/models/app_review.dart';
import '../../../core/session/app_scope.dart';
import '../../../core/utils/pricing_helper.dart';

class OrderDetailPage extends StatefulWidget {
  const OrderDetailPage({super.key, required this.order});

  final AppOrder order;

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  AppOrderDetail? _detail;
  List<AppReview> _reviews = const [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      _load();
    });
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final controller = AppScope.of(context);
      final results = await Future.wait([
        controller.getOrderDetail(widget.order.id),
        controller.getOrderReviews(widget.order.id),
      ]);
      final detail = results[0] as AppOrderDetail;
      final reviews = results[1] as List<AppReview>;
      if (!mounted) {
        return;
      }

      setState(() {
        _detail = detail;
        _reviews = reviews;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = _detail;

    return Scaffold(
      appBar: AppBar(
        title: const Text('订单详情'),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF7F4FF), Color(0xFFF4FAFF), Color(0xFFFFFCF8)],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? _MessageState(
                    icon: Icons.error_outline_rounded,
                    tone: const Color(0xFFFFE2E2),
                    title: '加载失败',
                    description: _errorMessage!,
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                    children: [
                      _OrderHero(
                        order: widget.order,
                        roleHint: _roleHint(context, widget.order),
                        isSubmitting: _isSubmitting,
                        onRefund: _canRefund(widget.order.orderStatus)
                            ? () => _requestRefund(context)
                            : null,
                      ),
                      const SizedBox(height: 16),
                      _StageBoard(order: widget.order),
                      const SizedBox(height: 16),
                      _RevenueBreakdownCard(order: widget.order),
                      const SizedBox(height: 16),
                      _ReviewSection(
                        order: widget.order,
                        reviews: _reviews,
                        isSubmitting: _isSubmitting,
                        onCreateReview: _canReview(widget.order, _reviews)
                            ? () => _createReview(context)
                            : null,
                      ),
                      const SizedBox(height: 16),
                      _TimelineSection(events: detail?.events ?? const []),
                    ],
                  ),
      ),
    );
  }

  Future<void> _requestRefund(BuildContext context) async {
    final reasonController = TextEditingController(text: 'schedule_change');
    final descriptionController = TextEditingController();

    final payload = await showDialog<(String, String?)>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('申请退款'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: reasonController,
                  decoration: const InputDecoration(labelText: '原因代码'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: '说明（可选）'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop((
                  reasonController.text.trim().isEmpty
                      ? 'schedule_change'
                      : reasonController.text.trim(),
                  descriptionController.text.trim().isEmpty
                      ? null
                      : descriptionController.text.trim(),
                ));
              },
              child: const Text('提交'),
            ),
          ],
        );
      },
    );

    reasonController.dispose();
    descriptionController.dispose();

    if (payload == null || !context.mounted) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await AppScope.of(context).requestRefund(
        orderId: widget.order.id,
        reasonCode: payload.$1,
        description: payload.$2,
      );
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('退款申请已提交。')),
      );
      await _load();
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('退款失败：$error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _createReview(BuildContext context) async {
    final payload = await showDialog<_ReviewInput>(
      context: context,
      builder: (_) => const _ReviewDialog(),
    );

    if (payload == null || !context.mounted) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await AppScope.of(context).createOrderReview(
        orderId: widget.order.id,
        score: payload.score,
        content: payload.content,
      );
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('评价已提交，信任分会逐步沉淀。')),
      );
      await _load();
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('评价失败：$error')),
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

class _RevenueBreakdownCard extends StatelessWidget {
  const _RevenueBreakdownCard({required this.order});

  final AppOrder order;

  @override
  Widget build(BuildContext context) {
    final pricing = PricingHelper.estimate(baseAmount: order.amountTotal);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x101E1B4B),
            blurRadius: 24,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('交易拆解', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            '先按种子阶段 5% 平台服务费估算，方便你判断这笔单对平台和执行者各自意味着什么。',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          _BreakdownRow(label: '订单金额', value: '¥${pricing.baseAmount.toStringAsFixed(0)}'),
          _BreakdownRow(
            label: '平台服务费',
            value: '¥${pricing.serviceFee.toStringAsFixed(0)}',
          ),
          _BreakdownRow(
            label: '执行者预计到手',
            value: '¥${pricing.hunterPayout.toStringAsFixed(0)}',
          ),
        ],
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
          Text(value, style: Theme.of(context).textTheme.titleSmall),
        ],
      ),
    );
  }
}

class _OrderHero extends StatelessWidget {
  const _OrderHero({
    required this.order,
    required this.roleHint,
    required this.isSubmitting,
    required this.onRefund,
  });

  final AppOrder order;
  final String roleHint;
  final bool isSubmitting;
  final VoidCallback? onRefund;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          colors: [
            _statusAccent(order.orderStatus),
            const Color(0xFF4F46E5),
            const Color(0xFF0EA5E9),
          ],
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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HeroChip(label: _statusLabel(order.orderStatus)),
              _HeroChip(label: _orderTypeLabel(order.orderType)),
              _HeroChip(label: '¥${order.amountTotal.toStringAsFixed(0)}'),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            order.listingTitle,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              height: 1.08,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            roleHint,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.86),
            ),
          ),
          if (onRefund != null) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: isSubmitting ? null : onRefund,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.35)),
                backgroundColor: Colors.white.withValues(alpha: 0.10),
              ),
              icon: const Icon(Icons.undo_rounded),
              label: Text(isSubmitting ? '提交中...' : '申请退款'),
            ),
          ],
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.label});

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

class _StageBoard extends StatelessWidget {
  const _StageBoard({required this.order});

  final AppOrder order;

  @override
  Widget build(BuildContext context) {
    final currentIndex = _stageIndex(order.orderStatus);
    final stages = const [
      ('付款', Icons.wallet_rounded),
      ('接单', Icons.handshake_rounded),
      ('执行', Icons.bolt_rounded),
      ('完成', Icons.verified_rounded),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x101E1B4B),
            blurRadius: 24,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('当前进度', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 14),
          Row(
            children: List.generate(stages.length, (index) {
              final isDone = index <= currentIndex;
              final accent = isDone ? _statusAccent(order.orderStatus) : const Color(0xFFD8DDF7);

              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: isDone ? accent : const Color(0xFFF1F3FF),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              stages[index].$2,
                              color: isDone ? Colors.white : const Color(0xFF7A7C90),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            stages[index].$1,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: isDone
                                      ? Theme.of(context).colorScheme.onSurface
                                      : const Color(0xFF7A7C90),
                                ),
                          ),
                        ],
                      ),
                    ),
                    if (index != stages.length - 1)
                      Container(
                        width: 20,
                        height: 2,
                        margin: const EdgeInsets.only(bottom: 24),
                        color: index < currentIndex ? accent : const Color(0xFFD8DDF7),
                      ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _ReviewSection extends StatelessWidget {
  const _ReviewSection({
    required this.order,
    required this.reviews,
    required this.isSubmitting,
    required this.onCreateReview,
  });

  final AppOrder order;
  final List<AppReview> reviews;
  final bool isSubmitting;
  final VoidCallback? onCreateReview;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x101E1B4B),
            blurRadius: 24,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('合作评价', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 6),
                    Text(
                      reviews.isEmpty ? '这笔订单还没有评价。' : '已经有 ${reviews.length} 条评价沉淀到信任体系里。',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              if (onCreateReview != null)
                FilledButton.icon(
                  onPressed: isSubmitting ? null : onCreateReview,
                  icon: const Icon(Icons.rate_review_outlined),
                  label: Text(isSubmitting ? '提交中...' : '去评价'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (reviews.isEmpty)
            const _MiniEmpty(text: '订单完成后，双方都可以留下评价。')
          else
            ...reviews.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ReviewCard(review: item),
              ),
            ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});

  final AppReview review;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F7FF),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ...List.generate(
                5,
                (index) => Icon(
                  index < review.score ? Icons.star_rounded : Icons.star_border_rounded,
                  color: const Color(0xFFF59E0B),
                  size: 18,
                ),
              ),
              const Spacer(),
              Text(
                review.createdAt == null ? '-' : _formatDate(review.createdAt!),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          if ((review.content ?? '').isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(review.content!, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}

class _MiniEmpty extends StatelessWidget {
  const _MiniEmpty({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F7FF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}

class _TimelineSection extends StatelessWidget {
  const _TimelineSection({required this.events});

  final List<AppOrderEvent> events;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x101E1B4B),
            blurRadius: 24,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('流转记录', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            '每一步动作都会留痕，方便你判断当前合作走到了哪里。',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 18),
          if (events.isEmpty)
            Text('还没有更多事件记录。', style: Theme.of(context).textTheme.bodyMedium)
          else
            ...List.generate(events.length, (index) {
              final event = events[index];
              final isLast = index == events.length - 1;
              final accent = _eventAccent(event.eventType);

              return Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        if (!isLast)
                          Container(
                            width: 2,
                            height: 56,
                            color: accent.withValues(alpha: 0.22),
                          ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _eventLabel(event.eventType),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            if (event.operatorRole?.isNotEmpty == true) ...[
                              const SizedBox(height: 4),
                              Text(
                                '操作角色：${event.operatorRole}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                            if (event.createdAt != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                _formatDate(event.createdAt!),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.tone,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final Color tone;
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
                  color: tone,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(icon, size: 34),
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

bool _canRefund(String status) {
  return status != 'COMPLETED' &&
      status != 'REFUND_REQUESTED' &&
      status != 'REFUNDED' &&
      status != 'CANCELLED';
}

String _roleHint(BuildContext context, AppOrder order) {
  final userId = AppScope.of(context).userId;
  final isBuyer = userId == order.buyerId;

  switch (order.orderStatus) {
    case 'PENDING_PAYMENT':
      return isBuyer ? '当前轮到你付款，付款后订单会进入待接单。' : '等待买方完成付款。';
    case 'PENDING_ACCEPT':
      return isBuyer ? '你已完成付款，等待对方接单。' : '当前轮到你接单。';
    case 'IN_PROGRESS':
      return isBuyer ? '对方正在处理中，等待交付。' : '你可以开始执行并在完成后标记交付。';
    case 'PENDING_CONFIRMATION':
      return isBuyer ? '对方已交付，轮到你确认完成。' : '你已交付，等待买方确认完成。';
    case 'COMPLETED':
      return '这笔订单已经完成。';
    default:
      return '订单正在流转中。';
  }
}

String _eventLabel(String eventType) {
  switch (eventType) {
    case 'CREATED':
      return '订单已创建';
    case 'PAID':
      return '买方已支付';
    case 'ACCEPTED':
      return '服务方已接单';
    case 'DELIVERED':
      return '服务方已交付';
    case 'CONFIRMED':
      return '买方已确认完成';
    default:
      return eventType;
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
      return '交换订单';
    default:
      return '任务订单';
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

bool _canReview(AppOrder order, List<AppReview> reviews) {
  return order.orderStatus == 'COMPLETED' && reviews.length < 2;
}

String _formatDate(DateTime value) {
  return '${value.month}/${value.day} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}

class _ReviewInput {
  const _ReviewInput({
    required this.score,
    this.content,
  });

  final int score;
  final String? content;
}

class _ReviewDialog extends StatefulWidget {
  const _ReviewDialog();

  @override
  State<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<_ReviewDialog> {
  final _contentController = TextEditingController();
  int _score = 5;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('提交评价'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              children: List.generate(
                5,
                (index) => ChoiceChip(
                  label: Text('${index + 1} 星'),
                  selected: _score == index + 1,
                  onSelected: (_) {
                    setState(() {
                      _score = index + 1;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contentController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: '评价内容（可选）',
                hintText: '写几句你的合作感受。',
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
              _ReviewInput(
                score: _score,
                content: _contentController.text.trim().isEmpty
                    ? null
                    : _contentController.text.trim(),
              ),
            );
          },
          child: const Text('提交评价'),
        ),
      ],
    );
  }
}

Color _eventAccent(String eventType) {
  switch (eventType) {
    case 'PAID':
      return const Color(0xFF4F46E5);
    case 'ACCEPTED':
      return const Color(0xFF7C3AED);
    case 'DELIVERED':
      return const Color(0xFF0EA5E9);
    case 'CONFIRMED':
      return const Color(0xFF16A34A);
    default:
      return const Color(0xFFF97316);
  }
}

int _stageIndex(String status) {
  switch (status) {
    case 'PENDING_PAYMENT':
      return 0;
    case 'PENDING_ACCEPT':
      return 1;
    case 'IN_PROGRESS':
      return 2;
    case 'PENDING_CONFIRMATION':
    case 'COMPLETED':
      return 3;
    default:
      return 0;
  }
}
