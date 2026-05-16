import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/logline_scaffold.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LogLineScaffold(
      title: 'Profile',
      currentIndex: 3,
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 34,
              backgroundColor: AppColors.primarySoft,
              child: Text(
                'AF',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Ari Farhan',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            ),
            Text(
              'Offline-first mode aktif',
              style: TextStyle(color: AppColors.muted),
            ),
            SizedBox(height: 28),
            ListTile(
              leading: Icon(Icons.cloud_sync_outlined),
              title: Text('Sync status'),
              subtitle: Text('3 item pending sync'),
            ),
            ListTile(
              leading: Icon(Icons.security_outlined),
              title: Text('Local auth'),
              subtitle: Text('Biometric/PIN siap digunakan'),
            ),
          ],
        ),
      ),
    );
  }
}
