import 'package:flutter/material.dart';

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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LogLine',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(child: Text('LogLine boilerplate is ready.')),
      ),
    );
  }
}
