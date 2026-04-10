import 'package:flutter/material.dart';

import '../../../core/config/map_config.dart';
import '../../../core/session/app_scope.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/amap_geocoder.dart';
import '../../../core/utils/city_coordinates.dart';
import '../../listings/presentation/my_listings_page.dart';
import '../models/create_listing_input.dart';
import '../models/edit_listing_args.dart';

class PublishPage extends StatefulWidget {
  const PublishPage({
    super.key,
    this.initialDraft,
    this.initialListingType,
    this.initialTaskCategory,
  });

  final EditListingArgs? initialDraft;
  final PublishListingType? initialListingType;
  final PublishTaskCategory? initialTaskCategory;

  @override
  State<PublishPage> createState() => _PublishPageState();
}

class _PublishPageState extends State<PublishPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _budgetController = TextEditingController();
  final _offerController = TextEditingController();
  final _wantController = TextEditingController();
  final _locationController = TextEditingController();
  final _cityController = TextEditingController(text: 'shanghai');

  PublishListingType _listingType = PublishListingType.task;
  PublishTaskCategory _taskCategory = PublishTaskCategory.companionship;
  PublishServiceMode _serviceMode = PublishServiceMode.offline;
  PublishBudgetType _budgetType = PublishBudgetType.fixed;
  bool _isUrgent = false;
  bool _isSubmitting = false;
  String? _feedbackMessage;

  bool get _isEditing => widget.initialDraft != null;
  @override
  void initState() {
    super.initState();
    final draft = widget.initialDraft;
    if (draft != null) {
      final initial = draft.input;
      _listingType = initial.listingType;
      _serviceMode = initial.serviceMode;
      _budgetType = initial.budgetType ?? PublishBudgetType.fixed;
      _isUrgent = initial.isUrgent;
      _titleController.text = initial.title;
      _descriptionController.text = initial.description;
      _cityController.text = initial.cityCode;
      _budgetController.text = initial.budgetAmount?.toString() ?? '';
      _offerController.text = initial.exchangeOfferText ?? '';
      _wantController.text = initial.exchangeWantText ?? '';
      _locationController.text = initial.locationText ?? '';
    } else if (widget.initialListingType != null) {
      _listingType = widget.initialListingType!;
      if (_listingType == PublishListingType.exchange) {
        _budgetType = PublishBudgetType.freeExchange;
      }
    }
    if (widget.initialTaskCategory != null) {
      _taskCategory = widget.initialTaskCategory!;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _budgetController.dispose();
    _offerController.dispose();
    _wantController.dispose();
    _locationController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!;
    final isTask = _listingType == PublishListingType.task;
    final isExchange = _listingType == PublishListingType.exchange;
    final taskBudgetType = _budgetType == PublishBudgetType.freeExchange
        ? PublishBudgetType.fixed
        : _budgetType;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '修改这件事' : '贴一件事到任务墙'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeOutCubic,
              child: Container(
                key: ValueKey('hero-$isTask'),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  gradient: LinearGradient(
                    colors: isTask
                        ? const [Color(0xFFF97316), Color(0xFFFFA14E)]
                        : const [Color(0xFF06B6D4), Color(0xFF5DD6E8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      right: 8,
                      top: -10,
                      child: Text(
                        isTask ? 'TASK' : 'SWAP',
                        style: theme.textTheme.headlineLarge?.copyWith(
                          fontSize: 72,
                          color: Colors.white.withValues(alpha: 0.14),
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            _isEditing ? 'EDIT MODE' : 'CITY TASK WALL',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          isTask
                              ? '把想托付的事\n写得让人愿意接住。'
                              : '把交换写得\n让人一眼想聊。',
                          style: theme.textTheme.headlineLarge?.copyWith(
                            color: Colors.white,
                            fontSize: 40,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          isTask
                              ? '把一件生活里的小事写清楚，它才会被一个真正愿意回应的人看到。'
                              : '讲清楚你能提供什么、你想换什么，交换成功率会高很多。',
                          style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 18),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _IdeaChip(
                              label: isTask
                                  ? '先写清场景'
                                  : '说清互换价值',
                            ),
                            _IdeaChip(label: '让人快速代入'),
                            _IdeaChip(label: '像在认真托付'),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            if (isTask) ...[
              _SectionCard(
                title: '先说这是一件什么样的事',
                subtitle: '先选任务类型，再去写内容，整条发布会更像一件真实发生的城市小事。',
                tint: palette.primarySoft,
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: PublishTaskCategory.values
                      .map(
                        (category) => _TaskCategoryChip(
                          label: _taskCategoryLabel(category),
                          selected: _taskCategory == category,
                          onTap: () {
                            setState(() {
                              _taskCategory = category;
                            });
                          },
                        ),
                      )
                      .toList(growable: false),
                ),
              ),
              const SizedBox(height: 18),
            ],
            Row(
              children: [
                Expanded(
                  child: _ModeCard(
                    title: '任务悬赏',
                    subtitle: '找人解决一个具体问题',
                    icon: Icons.bolt_rounded,
                    active: isTask,
                    tint: palette.secondarySoft,
                    onTap: () {
                      setState(() {
                        _listingType = PublishListingType.task;
                        if (_budgetType == PublishBudgetType.freeExchange) {
                          _budgetType = PublishBudgetType.fixed;
                        }
                        _feedbackMessage = null;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ModeCard(
                    title: '技能交换',
                    subtitle: '拿我的技能换你的技能',
                    icon: Icons.swap_horiz_rounded,
                    active: isExchange,
                    tint: palette.tertiarySoft,
                    onTap: () {
                      setState(() {
                        _listingType = PublishListingType.exchange;
                        _budgetType = PublishBudgetType.freeExchange;
                        _feedbackMessage = null;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _SectionCard(
              title: '一句话抓住人',
              subtitle: '别像发兼职，把这件事写得像真实生活里的一次认真托付。',
              tint: palette.primarySoft,
              child: Column(
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: '标题',
                      hintText: '比如：陪我去看展，并帮我拍几张有氛围的照片',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '请填写标题';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: '描述',
                      hintText: '写清楚你为什么想做这件事、希望对方怎么帮你、完成后想得到什么感觉。',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '请填写描述';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _SectionCard(
              title: '它会发生在哪',
              subtitle: '城市、方式和地点，会决定谁更容易看到并接住这件事。',
              tint: palette.tertiarySoft,
              child: Column(
                children: [
                  TextFormField(
                    controller: _cityController,
                    decoration: const InputDecoration(
                      labelText: '城市代码',
                      hintText: '比如：shanghai',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '请填写城市代码';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<PublishServiceMode>(
                    initialValue: _serviceMode,
                    decoration: const InputDecoration(labelText: '服务方式'),
                    items: const [
                      DropdownMenuItem(
                        value: PublishServiceMode.online,
                        child: Text('线上'),
                      ),
                      DropdownMenuItem(
                        value: PublishServiceMode.offline,
                        child: Text('线下'),
                      ),
                      DropdownMenuItem(
                        value: PublishServiceMode.both,
                        child: Text('都可以'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() {
                        _serviceMode = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _locationController,
                    decoration: const InputDecoration(
                      labelText: '地点说明',
                      hintText: '比如：徐汇附近，或线上飞书语音',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: isTask
                  ? _SectionCard(
                      key: const ValueKey('task'),
                      title: '给一点现实信息',
                      subtitle: '预算和时间感写得越清楚，越容易让人判断自己能不能接住。',
                      tint: palette.secondarySoft,
                      child: Column(
                        children: [
                          DropdownButtonFormField<PublishBudgetType>(
                            initialValue: taskBudgetType,
                            decoration: const InputDecoration(labelText: '预算方式'),
                            items: const [
                              DropdownMenuItem(
                                value: PublishBudgetType.fixed,
                                child: Text('固定预算'),
                              ),
                              DropdownMenuItem(
                                value: PublishBudgetType.negotiable,
                                child: Text('可协商'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value == null) {
                                return;
                              }
                              setState(() {
                                _budgetType = value;
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _budgetController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: '预算金额',
                              hintText: '比如：199',
                            ),
                            onChanged: (_) {
                              setState(() {});
                            },
                          ),
                        ],
                      ),
                    )
                  : _SectionCard(
                      key: const ValueKey('exchange'),
                      title: '交换内容',
                      subtitle: '把你的可交换价值写得更像一个有吸引力的提案。',
                      tint: palette.primarySoft,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _offerController,
                            decoration: const InputDecoration(
                              labelText: '我能提供什么',
                              hintText: '比如：摄影修图、活动跟拍、海报排版',
                            ),
                            validator: (value) {
                              if (!isTask && (value == null || value.trim().isEmpty)) {
                                return '请填写你能提供的内容';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _wantController,
                            decoration: const InputDecoration(
                              labelText: '我想交换什么',
                              hintText: '比如：简历优化、运营建议、健身陪练',
                            ),
                            validator: (value) {
                              if (!isTask && (value == null || value.trim().isEmpty)) {
                                return '请填写你想交换的内容';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 14),
            Card(
              child: SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                value: _isUrgent,
                title: const Text('加急发布'),
                subtitle: Text(
                  isTask
                      ? '适合今晚就想开始的事'
                      : '适合想尽快完成撮合的交换',
                ),
                onChanged: (value) {
                  setState(() {
                    _isUrgent = value;
                  });
                },
              ),
            ),
            if (_feedbackMessage != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: _feedbackMessage!.startsWith('提交失败')
                      ? const Color(0xFFFFE2E2)
                      : const Color(0xFFE4F9EC),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      _feedbackMessage!.startsWith('提交失败')
                          ? Icons.error_outline_rounded
                          : Icons.check_circle_outline_rounded,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _feedbackMessage!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: FilledButton.icon(
          onPressed: _isSubmitting ? null : () => _submit(context),
          icon: Icon(_isEditing ? Icons.save_outlined : Icons.rocket_launch_outlined),
          label: Text(
            _isSubmitting ? '提交中...' : (_isEditing ? '保存这件事' : '贴上任务墙'),
          ),
        ),
      ),
    );
  }

  Future<void> _submit(BuildContext context) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final controller = AppScope.of(context);
    setState(() {
      _isSubmitting = true;
      _feedbackMessage = null;
    });

    try {
      final cityCode = _cityController.text.trim();
      final defaultCoordinates = resolveCityCoordinates(cityCode);
      final cityLabel = resolveCityLabel(cityCode);
      final locationText = _locationController.text.trim();
      final geocodedLocation = locationText.isEmpty
          ? null
          : await geocodeWithAmap(
              apiKey: aMapWebApiKey,
              cityLabel: cityLabel,
              locationText: locationText,
            );
      final input = CreateListingInput(
        listingType: _listingType,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        serviceMode: _serviceMode,
        cityCode: cityCode,
        longitude: geocodedLocation?.longitude ?? defaultCoordinates.longitude,
        latitude: geocodedLocation?.latitude ?? defaultCoordinates.latitude,
        categoryCode: _listingType == PublishListingType.task
            ? _taskCategoryCategoryCode(_taskCategory)
            : null,
        taskCategory:
            _listingType == PublishListingType.task ? _taskCategory : null,
        budgetType: _listingType == PublishListingType.task
            ? _budgetType
            : PublishBudgetType.freeExchange,
        budgetAmount: _listingType == PublishListingType.task
            ? double.tryParse(_budgetController.text.trim())
            : null,
        exchangeOfferText: _listingType == PublishListingType.exchange
            ? _offerController.text.trim()
            : null,
        exchangeWantText: _listingType == PublishListingType.exchange
            ? _wantController.text.trim()
            : null,
        locationText: locationText.isEmpty ? null : locationText,
        isUrgent: _isUrgent,
      );

      if (_isEditing) {
        await controller.updateListing(
          listingId: widget.initialDraft!.listingId,
          input: input,
        );
      } else {
        await controller.createListing(input);
      }

      if (_isEditing) {
        setState(() {
          _feedbackMessage = '修改已保存。';
          _isSubmitting = false;
        });

        if (context.mounted) {
          Navigator.of(context).pop(true);
        }
      } else {
        if (!context.mounted) {
          return;
        }

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const MyListingsPage(
              initialFilter: MyListingsFilter.pendingReview,
              noticeMessage: '这件事已经贴上任务墙，当前会先进入待审核状态。',
            ),
          ),
        );
      }
    } catch (error) {
      setState(() {
        _feedbackMessage = '提交失败：$error';
        _isSubmitting = false;
      });
    }
  }
}


class _TaskCategoryChip extends StatelessWidget {
  const _TaskCategoryChip({
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

String _taskCategoryLabel(PublishTaskCategory category) {
  switch (category) {
    case PublishTaskCategory.companionship:
      return '倾听陪伴';
    case PublishTaskCategory.together:
      return '一起去做';
    case PublishTaskCategory.lifestyle:
      return '生活帮忙';
    case PublishTaskCategory.kindness:
      return '公益善意';
    case PublishTaskCategory.skill:
      return '技能支持';
  }
}

String _taskCategoryCategoryCode(PublishTaskCategory category) {
  switch (category) {
    case PublishTaskCategory.companionship:
      return 'companionship';
    case PublishTaskCategory.together:
      return 'together';
    case PublishTaskCategory.lifestyle:
      return 'lifestyle';
    case PublishTaskCategory.kindness:
      return 'kindness';
    case PublishTaskCategory.skill:
      return 'skill';
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.active,
    required this.tint,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool active;
  final Color tint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: active ? Theme.of(context).colorScheme.primary : Colors.transparent,
          width: 2,
        ),
      ),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              gradient: active
                  ? LinearGradient(
                      colors: [Colors.white, tint],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: tint,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon),
                ),
                const SizedBox(height: 18),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 6),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.tint,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Color tint;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            colors: [Colors.white, tint.withValues(alpha: 0.9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 18),
            child,
          ],
        ),
      ),
    );
  }
}

class _IdeaChip extends StatelessWidget {
  const _IdeaChip({required this.label});

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
