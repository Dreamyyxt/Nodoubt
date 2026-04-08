import 'package:flutter/material.dart';

import '../../../core/session/app_scope.dart';

class DevLoginPage extends StatefulWidget {
  const DevLoginPage({super.key});

  @override
  State<DevLoginPage> createState() => _DevLoginPageState();
}

class _DevLoginPageState extends State<DevLoginPage> {
  final TextEditingController _phoneController = TextEditingController(
    text: '13800000000',
  );
  final TextEditingController _codeController = TextEditingController(
    text: '123456',
  );

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF4EFE6), Color(0xFFE6E7DE), Color(0xFFD6E3D9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -110,
              left: -70,
              child: _GlowOrb(
                size: 240,
                color: const Color(0xFF0E5A46).withValues(alpha: 0.14),
              ),
            ),
            Positioned(
              right: -40,
              top: 150,
              child: _GlowOrb(
                size: 180,
                color: const Color(0xFFC66C3A).withValues(alpha: 0.16),
              ),
            ),
            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1120),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 900;
                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: isWide
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Flexible(
                                    fit: FlexFit.loose,
                                    child: _HeroPanel(theme: theme),
                                  ),
                                  const SizedBox(width: 24),
                                  SizedBox(
                                    width: 420,
                                    child: _LoginPanel(
                                      phoneController: _phoneController,
                                      codeController: _codeController,
                                      isLoading: controller.isBootstrapping,
                                      errorMessage: controller.errorMessage,
                                      baseUrl: controller.baseUrl,
                                      onPreset: _applyPreset,
                                      onLogin: () => controller.login(
                                        phone: _phoneController.text.trim(),
                                        code: _codeController.text.trim(),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                children: [
                                  _HeroPanel(theme: theme),
                                  const SizedBox(height: 20),
                                  _LoginPanel(
                                    phoneController: _phoneController,
                                    codeController: _codeController,
                                    isLoading: controller.isBootstrapping,
                                    errorMessage: controller.errorMessage,
                                    baseUrl: controller.baseUrl,
                                    onPreset: _applyPreset,
                                    onLogin: () => controller.login(
                                      phone: _phoneController.text.trim(),
                                      code: _codeController.text.trim(),
                                    ),
                                  ),
                                ],
                              ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _applyPreset(String phone, String code) {
    setState(() {
      _phoneController.text = phone;
      _codeController.text = code;
    });
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(36),
        gradient: const LinearGradient(
          colors: [Color(0xFF15392E), Color(0xFF0E5A46), Color(0xFF1A7D63)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2415392E),
            blurRadius: 40,
            offset: Offset(0, 24),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'TASK BOUNTY + SKILL SWAP',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            '把陌生人的合作，\n做得更像一场可靠的相遇。',
            style: theme.textTheme.headlineLarge?.copyWith(
              color: Colors.white,
              fontSize: 54,
              height: 0.96,
            ),
          ),
          const SizedBox(height: 18),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Text(
              '确任先把线上任务悬赏、技能交换和交易闭环跑通，再慢慢反哺线下的任务驿站和轻社交空间。',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: const Color(0xFFEAF4EF),
              ),
            ),
          ),
          const SizedBox(height: 30),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: const [
              _HeroStat(value: '01', label: '可信申请'),
              _HeroStat(value: '02', label: '快速撮合'),
              _HeroStat(value: '03', label: '订单闭环'),
            ],
          ),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SignalLine(
                  title: '任务悬赏',
                  description: '找设计、找陪练、找同城帮手，先把需求说清楚。',
                ),
                SizedBox(height: 14),
                _SignalLine(
                  title: '技能交换',
                  description: '摄影换简历，英语换健身，降低关系冷启动成本。',
                ),
                SizedBox(height: 14),
                _SignalLine(
                  title: '轻社交',
                  description: '从合作开始建立信任，而不是从尬聊开始。',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginPanel extends StatelessWidget {
  const _LoginPanel({
    required this.phoneController,
    required this.codeController,
    required this.isLoading,
    required this.errorMessage,
    required this.baseUrl,
    required this.onPreset,
    required this.onLogin,
  });

  final TextEditingController phoneController;
  final TextEditingController codeController;
  final bool isLoading;
  final String? errorMessage;
  final String baseUrl;
  final void Function(String phone, String code) onPreset;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(36),
        border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x16000000),
            blurRadius: 30,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('开发登录', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            '先进入一个可演示版本。我们已经把登录、申请、订单、退款这些主链路接起来了。',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _PresetChip(
                label: '默认用户',
                accent: const Color(0xFFE8F0EA),
                onTap: () => onPreset('13800000000', '123456'),
              ),
              _PresetChip(
                label: '发布者',
                accent: const Color(0xFFF1E5DD),
                onTap: () => onPreset('13900000001', '123456'),
              ),
              _PresetChip(
                label: '交换体验官',
                accent: const Color(0xFFE7ECF0),
                onTap: () => onPreset('13900000002', '123456'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: phoneController,
            decoration: const InputDecoration(
              labelText: '手机号',
              prefixIcon: Icon(Icons.phone_iphone_outlined),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: codeController,
            decoration: const InputDecoration(
              labelText: '验证码',
              prefixIcon: Icon(Icons.password_outlined),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: isLoading ? null : onLogin,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: Text(isLoading ? '正在进入...' : '进入确任'),
            ),
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFE5E2),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                errorMessage!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          ],
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F2EA),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('当前联调环境', style: theme.textTheme.bodySmall),
                const SizedBox(height: 8),
                Text(baseUrl, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.label,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: accent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(label),
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 146,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFFEAF4EF),
            ),
          ),
        ],
      ),
    );
  }
}

class _SignalLine extends StatelessWidget {
  const _SignalLine({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.only(top: 6),
          decoration: const BoxDecoration(
            color: Color(0xFFE6C36B),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFFDDEBE5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
