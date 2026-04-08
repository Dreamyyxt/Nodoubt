import 'package:flutter/material.dart';

import '../core/session/app_controller.dart';
import '../core/session/app_scope.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/presentation/dev_login_page.dart';
import '../features/shell/presentation/app_shell_page.dart';

class NoDoubtApp extends StatefulWidget {
  const NoDoubtApp({super.key});

  @override
  State<NoDoubtApp> createState() => _NoDoubtAppState();
}

class _NoDoubtAppState extends State<NoDoubtApp> {
  late final AppController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AppController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      controller: _controller,
      child: MaterialApp(
        title: '确任',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            if (_controller.isLoggedIn) {
              return const AppShellPage();
            }

            return const DevLoginPage();
          },
        ),
      ),
    );
  }
}
