import 'package:flutter/material.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'services/app_bootstrap_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppBootstrapService().initialize();
  runApp(const LogLineApp());
}

class LogLineApp extends StatelessWidget {
  const LogLineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'LogLine',
      theme: AppTheme.light(),
      routerConfig: AppRouter.router,
    );
  }
}
