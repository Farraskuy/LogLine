import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import 'logline_button.dart';

class CollaboratorInvite {
  const CollaboratorInvite({required this.identity, required this.role});

  final String identity;
  final String role;
}

class CollaboratorConfirmSheet extends StatefulWidget {
  const CollaboratorConfirmSheet({super.key, this.initialValue = ''});

  final String initialValue;

  static Future<CollaboratorInvite?> show(
    BuildContext context, {
    String initialValue = '',
  }) {
    return showModalBottomSheet<CollaboratorInvite>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CollaboratorConfirmSheet(initialValue: initialValue),
    );
  }

  @override
  State<CollaboratorConfirmSheet> createState() =>
      _CollaboratorConfirmSheetState();
}

class _CollaboratorConfirmSheetState extends State<CollaboratorConfirmSheet> {
  late final TextEditingController _identityController;
  String _role = 'editor';

  @override
  void initState() {
    super.initState();
    _identityController = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _identityController.dispose();
    super.dispose();
  }

  void _submit() {
    final identity = _identityController.text.trim();
    if (identity.isEmpty) return;
    context.pop(CollaboratorInvite(identity: identity, role: _role));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 72,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Konfirmasi Kolaborator',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            const Text(
              'Masukkan email atau inisial anggota yang akan diberi akses note ini.',
              style: TextStyle(color: AppColors.muted, height: 1.4),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _identityController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.person_add_alt_1_outlined),
                hintText: 'nama@email.com atau DN',
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Role akses',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _RolePill(
                  label: 'Viewer',
                  active: _role == 'viewer',
                  onTap: () => setState(() => _role = 'viewer'),
                ),
                const SizedBox(width: 10),
                _RolePill(
                  label: 'Editor',
                  active: _role == 'editor',
                  onTap: () => setState(() => _role = 'editor'),
                ),
                const SizedBox(width: 10),
                _RolePill(
                  label: 'Owner',
                  active: _role == 'owner',
                  onTap: () => setState(() => _role = 'owner'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: LogLineButton(
                    label: 'Batal',
                    variant: LogLineButtonVariant.secondary,
                    onPressed: () => context.pop(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: LogLineButton(label: 'Undang', onPressed: _submit),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RolePill extends StatelessWidget {
  const _RolePill({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? AppColors.primarySoft : AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: active ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: active ? AppColors.primary : AppColors.muted,
            ),
          ),
        ),
      ),
    );
  }
}
