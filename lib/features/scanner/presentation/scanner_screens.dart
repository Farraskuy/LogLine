import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_route_paths.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/logline_button.dart';
import '../../../shared/widgets/logline_scaffold.dart';

class ScannerScreen extends StatelessWidget {
  const ScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LogLineScaffold(
      currentIndex: 2,
      backgroundColor: AppColors.camera,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Row(
            children: [
              Expanded(
                child: Text(
                  'Camera to Text',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _LiveBadge(),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            height: 430,
            padding: const EdgeInsets.all(34),
            decoration: BoxDecoration(
              color: const Color(0xFF111827),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                Positioned(
                  top: 44,
                  left: 36,
                  child: Text(
                    'INVOICE A-104',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                Positioned(
                  top: 100,
                  left: 36,
                  right: 36,
                  child: _Highlight(
                    label: 'Valve A-104  |  Tekanan 18 bar',
                    color: Color(0xFFFDE68A),
                  ),
                ),
                Positioned(
                  top: 156,
                  left: 36,
                  right: 70,
                  child: _Highlight(
                    label: 'No. dokumen: 8M-21',
                    color: Color(0xFFBAE6FD),
                  ),
                ),
                Positioned(
                  top: 212,
                  left: 36,
                  right: 40,
                  child: _Highlight(
                    label: 'Tanggal inspeksi: 16/05/2026',
                    color: Color(0xFFBBF7D0),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.cyanAccent, width: 3),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Teks terdeteksi',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
                const Text(
                  '3 blok teks siap dipilih',
                  style: TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Text(
                    'Valve A-104, tekanan 18 bar. No. dokumen 8M-21. Tanggal inspeksi 16/05/2026.',
                  ),
                ),
                const SizedBox(height: 18),
                LogLineButton(
                  label: 'Sisipkan ke Note',
                  variant: LogLineButtonVariant.success,
                  onPressed: () => context.go(AppRoutePaths.ocrResult),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class OcrResultScreen extends StatelessWidget {
  const OcrResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LogLineScaffold(
      title: 'Hasil OCR',
      showBack: true,
      actions: [
        TextButton(
          onPressed: () => context.go(AppRoutePaths.detailNote),
          child: const Text('Tambah'),
        ),
      ],
      currentIndex: 2,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Container(
            height: 156,
            decoration: BoxDecoration(
              color: AppColors.ink,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.document_scanner_rounded,
              color: Colors.white,
              size: 72,
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'Pilih tujuan',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () => context.go(AppRoutePaths.detailNote),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary),
              ),
              child: const Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Audit gudang mingguan',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                        Text(
                          'Sisipkan sebagai lampiran Markdown',
                          style: TextStyle(color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.check_circle, color: AppColors.primary),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: const Text(
              '```text\nValve A-104, tekanan 18 bar\nNo. dokumen 8M-21\nTanggal inspeksi 16/05/2026\n```',
            ),
          ),
          const SizedBox(height: 28),
          LogLineButton(
            label: 'Sisipkan sekarang',
            onPressed: () => context.go(AppRoutePaths.detailNote),
          ),
        ],
      ),
    );
  }
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF123B36),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Text(
        'Realtime OCR',
        style: TextStyle(color: Color(0xFF5EEAD4), fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _Highlight extends StatelessWidget {
  const _Highlight({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
    );
  }
}
