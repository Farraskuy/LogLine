import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_route_paths.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/auth_service.dart';
import '../../../services/sync_queue_service.dart';
import '../../../shared/widgets/logline_scaffold.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final AuthService _authService = AuthService();
  final SyncQueueService _syncQueueService = SyncQueueService();
  late Future<Map<String, dynamic>?> _userFuture;

  @override
  void initState() {
    super.initState();
    _userFuture = _authService.currentUser();
  }

  Future<void> _signOut() async {
    await _authService.signOut();
    if (mounted) context.go(AppRoutePaths.login);
  }

  @override
  Widget build(BuildContext context) {
    final pendingSync = _syncQueueService.pendingItems().length;
    return LogLineScaffold(
      title: 'Profile',
      currentIndex: 2,
      child: FutureBuilder<Map<String, dynamic>?>(
        future: _userFuture,
        builder: (context, snapshot) {
          final user = snapshot.data;
          final name = user?['name'] as String? ?? 'Pengguna LogLine';
          final email = user?['email'] as String? ?? 'Belum login';
          final initials = name
              .split(' ')
              .where((part) => part.isNotEmpty)
              .take(2)
              .map((part) => part[0].toUpperCase())
              .join();

          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 140),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: AppColors.primarySoft,
                  child: Text(
                    initials.isEmpty ? 'LL' : initials,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(email, style: const TextStyle(color: AppColors.muted)),
                const SizedBox(height: 28),
                ListTile(
                  leading: const Icon(Icons.cloud_sync_outlined),
                  title: const Text('Sync status'),
                  subtitle: Text('$pendingSync item menunggu sinkronisasi'),
                ),
                const ListTile(
                  leading: Icon(Icons.security_outlined),
                  title: Text('Local auth'),
                  subtitle: Text('Session tersimpan di secure storage'),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _signOut,
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Keluar'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
