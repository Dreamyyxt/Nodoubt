import 'package:flutter/material.dart';

import '../../../core/models/app_listing.dart';
import '../../../core/models/received_application.dart';
import '../../../core/session/app_scope.dart';
import '../../../core/theme/app_theme.dart';

class ReceivedApplicationsPage extends StatefulWidget {
  const ReceivedApplicationsPage({super.key, required this.listing});

  final AppListing listing;

  @override
  State<ReceivedApplicationsPage> createState() => _ReceivedApplicationsPageState();
}

class _ReceivedApplicationsPageState extends State<ReceivedApplicationsPage> {
  bool _isLoading = true;
  String? _errorMessage;
  List<ReceivedApplication> _items = const [];
  String _search = '';
  String _statusFilter = 'ALL';

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
      final items = await AppScope.of(context).getListingApplications(widget.listing.id);
      if (!mounted) {
        return;
      }

      setState(() {
        _items = items;
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
    final palette = Theme.of(context).extension<AppPalette>()!;
    final filteredItems = _items.where((item) {
      final statusMatch = _statusFilter == 'ALL' || item.status == _statusFilter;
      if (!statusMatch) {
        return false;
      }
      if (_search.isEmpty) {
        return true;
      }

      final query = _search.toLowerCase();
      return item.applicantName.toLowerCase().contains(query) ||
          item.message.toLowerCase().contains(query) ||
          _statusLabel(item.status).toLowerCase().contains(query);
    }).toList(growable: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('收到的申请'),
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
            colors: [Color(0xFFF5F4FF), Color(0xFFF4FBFF), Color(0xFFFFFCF8)],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? _MessageState(
                    icon: Icons.wifi_tethering_error_rounded,
                    tone: const Color(0xFFFFE2E2),
                    title: '加载失败',
                    description: _errorMessage!,
                  )
                : _items.isEmpty
                    ? _MessageState(
                        icon: Icons.mark_email_unread_outlined,
                        tone: palette.tertiarySoft,
                        title: '暂时还没人敲门',
                        description: '这条发布还没有收到申请，先让它在首页多曝光一会儿。',
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                        children: [
                          _ListingHero(listing: widget.listing, count: _items.length),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              _TopFilterChip(
                                label: '全部 ${_items.length}',
                                selected: _statusFilter == 'ALL',
                                onTap: () => setState(() => _statusFilter = 'ALL'),
                              ),
                              _TopFilterChip(
                                label: '待处理',
                                selected: _statusFilter == 'PENDING',
                                onTap: () => setState(() => _statusFilter = 'PENDING'),
                              ),
                              _TopFilterChip(
                                label: '已接受',
                                selected: _statusFilter == 'ACCEPTED',
                                onTap: () => setState(() => _statusFilter = 'ACCEPTED'),
                              ),
                              _TopFilterChip(
                                label: '已拒绝',
                                selected: _statusFilter == 'REJECTED',
                                onTap: () => setState(() => _statusFilter = 'REJECTED'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.search_rounded),
                              hintText: '搜索申请人 / 留言 / 状态',
                            ),
                            onChanged: (value) {
                              setState(() {
                                _search = value.trim();
                              });
                            },
                          ),
                          const SizedBox(height: 18),
                          ...filteredItems.map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _ReceivedApplicationCard(
                                item: item,
                                listing: widget.listing,
                                onChanged: _load,
                              ),
                            ),
                          ),
                        ],
                      ),
      ),
    );
  }
}

class _TopFilterChip extends StatelessWidget {
  const _TopFilterChip({
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
          color: selected ? const Color(0xFF4F46E5) : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? const Color(0xFF4F46E5) : const Color(0xFFD9CFFE),
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

class _ListingHero extends StatelessWidget {
  const _ListingHero({required this.listing, required this.count});

  final AppListing listing;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: LinearGradient(
          colors: listing.listingType == 'EXCHANGE'
              ? const [Color(0xFF0EA5E9), Color(0xFF4F46E5)]
              : const [Color(0xFFFF8A4C), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A4F46E5),
            blurRadius: 28,
            offset: Offset(0, 16),
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
              _HeroPill(
                label: listing.listingType == 'EXCHANGE'
                    ? '交换模式'
                    : '任务模式',
              ),
              _HeroPill(label: '$count 条申请'),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            listing.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              height: 1.08,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '把更匹配的申请留在前排，快速决定谁最适合进入下一步合作。',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.86),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.label});

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

class _ReceivedApplicationCard extends StatefulWidget {
  const _ReceivedApplicationCard({
    required this.item,
    required this.listing,
    required this.onChanged,
  });

  final ReceivedApplication item;
  final AppListing listing;
  final Future<void> Function() onChanged;

  @override
  State<_ReceivedApplicationCard> createState() => _ReceivedApplicationCardState();
}

class _ReceivedApplicationCardState extends State<_ReceivedApplicationCard> {
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final theme = Theme.of(context);
    final accent = _statusAccent(item.status);

    return Container(
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
                    gradient: LinearGradient(
                      colors: [accent.withValues(alpha: 0.8), accent],
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    item.applicantName.characters.first.toUpperCase(),
                    style: theme.textTheme.titleMedium?.copyWith(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.applicantName, style: theme.textTheme.titleLarge),
                      const SizedBox(height: 4),
                      Text(
                        item.quotedPrice == null
                            ? '还没有给出明确报价'
                            : '报价 ¥${item.quotedPrice!.toStringAsFixed(0)}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                _StatusBadge(status: item.status),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                item.message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 14),
            _ActionArea(
              item: item,
              listing: widget.listing,
              isSubmitting: _isSubmitting,
              onAccept: () => _handle(context, accept: true),
              onReject: () => _handle(context, accept: false),
              onCreateOrder: () => _createOrder(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handle(BuildContext context, {required bool accept}) async {
    setState(() {
      _isSubmitting = true;
    });

    final controller = AppScope.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      if (accept) {
        await controller.acceptApplication(widget.item.id);
      } else {
        await controller.rejectApplication(widget.item.id);
      }

      if (!context.mounted) {
        return;
      }

      messenger.showSnackBar(
        SnackBar(
          content: Text(accept ? '申请已接受。下一步可以继续建单。' : '申请已拒绝。'),
        ),
      );
      await widget.onChanged();
      await controller.refreshAll();
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      messenger.showSnackBar(
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

  Future<void> _createOrder(BuildContext context) async {
    final amountController = TextEditingController(
      text: widget.item.quotedPrice?.toString() ??
          (widget.listing.listingType == 'EXCHANGE' ? '0' : ''),
    );
    final remarkController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final payload = await showDialog<(double, String?)>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('创建订单'),
          content: Form(
            key: formKey,
            child: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: '订单金额'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '请输入订单金额';
                      }

                      final parsed = double.tryParse(value.trim());
                      if (parsed == null || parsed < 0) {
                        return '请输入有效金额';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: remarkController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: '备注（可选）'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                if (!(formKey.currentState?.validate() ?? false)) {
                  return;
                }

                Navigator.of(dialogContext).pop((
                  double.parse(amountController.text.trim()),
                  remarkController.text.trim().isEmpty ? null : remarkController.text.trim(),
                ));
              },
              child: const Text('创建'),
            ),
          ],
        );
      },
    );

    amountController.dispose();
    remarkController.dispose();

    if (payload == null || !context.mounted) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final controller = AppScope.of(context);

    try {
      await controller.createOrder(
        listingId: widget.listing.id,
        applicationId: widget.item.id,
        amountTotal: payload.$1,
        remark: payload.$2,
      );
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('订单已创建。')),
      );
      await widget.onChanged();
      await controller.refreshAll();
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('创建订单失败：$error')),
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

class _ActionArea extends StatelessWidget {
  const _ActionArea({
    required this.item,
    required this.listing,
    required this.isSubmitting,
    required this.onAccept,
    required this.onReject,
    required this.onCreateOrder,
  });

  final ReceivedApplication item;
  final AppListing listing;
  final bool isSubmitting;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onCreateOrder;

  @override
  Widget build(BuildContext context) {
    if (_canHandle(item.status)) {
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          FilledButton.icon(
            onPressed: isSubmitting ? null : onAccept,
            icon: const Icon(Icons.favorite_rounded),
            label: Text(isSubmitting ? '处理中...' : '接受申请'),
          ),
          OutlinedButton.icon(
            onPressed: isSubmitting ? null : onReject,
            icon: const Icon(Icons.close_rounded),
            label: const Text('拒绝'),
          ),
        ],
      );
    }

    if (item.status == 'ACCEPTED' && !item.hasOrder) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFE8EBFF),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            const Icon(Icons.receipt_long_rounded),
            const SizedBox(width: 12),
            const Expanded(child: Text('已经匹配成功了，现在把它推进成正式订单。')),
            FilledButton.tonal(
              onPressed: isSubmitting ? null : onCreateOrder,
              child: Text(isSubmitting ? '处理中...' : '创建订单'),
            ),
          ],
        ),
      );
    }

    if (item.status == 'ACCEPTED' && item.hasOrder) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFE7F8ED),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF169B62)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.orderStatus == null ? '订单已创建' : '订单已创建 · ${item.orderStatus}',
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
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

bool _canHandle(String status) => status == 'PENDING';

String _statusLabel(String status) {
  switch (status) {
    case 'PENDING':
      return '待处理';
    case 'ACCEPTED':
      return '已接受';
    case 'REJECTED':
      return '已拒绝';
    default:
      return status;
  }
}

Color _statusAccent(String status) {
  switch (status) {
    case 'ACCEPTED':
      return const Color(0xFF169B62);
    case 'REJECTED':
      return const Color(0xFFDF4457);
    default:
      return const Color(0xFFF59E0B);
  }
}
