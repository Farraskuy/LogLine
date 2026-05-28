import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/router/app_route_paths.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/logline_button.dart';
import '../../../shared/widgets/logline_scaffold.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  CameraController? _controller;
  Future<void>? _cameraFuture;
  String? _lastCapturePath;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _cameraFuture = _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final permission = await Permission.camera.request();
      if (!permission.isGranted) {
        setState(() => _errorMessage = 'Izin kamera belum diberikan.');
        return;
      }
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(
          () => _errorMessage = 'Kamera tidak ditemukan di perangkat ini.',
        );
        return;
      }
      final backCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _controller = controller);
    } catch (error) {
      if (mounted) setState(() => _errorMessage = error.toString());
    }
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    final file = await controller.takePicture();
    if (mounted) setState(() => _lastCapturePath = file.path);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LogLineScaffold(
      currentIndex: 1,
      backgroundColor: AppColors.camera,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 140),
        children: [
          const Row(
            children: [
              Expanded(
                child: Text(
                  'Kamera',
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
          FutureBuilder<void>(
            future: _cameraFuture,
            builder: (context, snapshot) {
              if (_errorMessage != null) {
                return _CameraPlaceholder(message: _errorMessage!);
              }
              final controller = _controller;
              if (snapshot.connectionState == ConnectionState.waiting ||
                  controller == null ||
                  !controller.value.isInitialized) {
                return const _CameraLoading();
              }
              return ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: AspectRatio(
                  aspectRatio: controller.value.aspectRatio,
                  child: CameraPreview(controller),
                ),
              );
            },
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
                  'Ambil gambar',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
                const Text(
                  'OCR belum dijalankan. Kamera hanya mengambil gambar terlebih dahulu.',
                  style: TextStyle(color: AppColors.muted),
                ),
                if (_lastCapturePath != null) ...[
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text('Foto tersimpan sementara:\n$_lastCapturePath'),
                  ),
                ],
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: LogLineButton(
                        label: 'Ambil foto',
                        variant: LogLineButtonVariant.success,
                        icon: Icons.camera_alt_outlined,
                        onPressed: _capture,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: LogLineButton(
                        label: 'Tambah Note',
                        variant: LogLineButtonVariant.secondary,
                        onPressed: () => context.go(AppRoutePaths.addNote),
                      ),
                    ),
                  ],
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
          onPressed: () => context.go(AppRoutePaths.addNote),
          child: const Text('Tambah'),
        ),
      ],
      currentIndex: 1,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 140),
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
            'OCR belum aktif',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          const Text(
            'Halaman ini disiapkan untuk integrasi OCR berikutnya. Untuk sekarang gunakan kamera untuk mengambil gambar lalu buat note manual.',
            style: TextStyle(color: AppColors.muted, height: 1.45),
          ),
          const SizedBox(height: 28),
          LogLineButton(
            label: 'Buat note baru',
            onPressed: () => context.go(AppRoutePaths.addNote),
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
        'Camera',
        style: TextStyle(color: Color(0xFF5EEAD4), fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _CameraLoading extends StatelessWidget {
  const _CameraLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 430,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: const CircularProgressIndicator(color: Colors.white),
    );
  }
}

class _CameraPlaceholder extends StatelessWidget {
  const _CameraPlaceholder({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 430,
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.no_photography_outlined,
            color: Colors.white,
            size: 54,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
