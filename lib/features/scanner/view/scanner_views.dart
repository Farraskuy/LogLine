import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_route_paths.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/camera_text_extraction_service.dart';
import '../../../shared/widgets/logline_button.dart';
import '../../../shared/widgets/logline_scaffold.dart';

class ScannerView extends StatefulWidget {
  const ScannerView({super.key});

  @override
  State<ScannerView> createState() => _ScannerViewState();
}

class _ScannerViewState extends State<ScannerView> {
  final CameraTextExtractionService _extractionService =
      CameraTextExtractionService();

  CameraController? _controller;
  Future<void>? _cameraFuture;
  CameraTextExtractionResult? _result;
  String? _lastCapturePath;
  String? _errorMessage;
  bool _extracting = false;
  bool _realtimeEnabled = false;

  @override
  void initState() {
    super.initState();
    _cameraFuture = _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final controller = await _extractionService.initializeCamera();
      if (mounted) setState(() => _controller = controller);
    } catch (error) {
      if (mounted) setState(() => _errorMessage = error.toString());
    }
  }

  Future<void> _captureAndExtract() async {
    final controller = _controller;
    if (controller == null ||
        !controller.value.isInitialized ||
        controller.value.isStreamingImages ||
        _extracting) {
      return;
    }
    setState(() {
      _extracting = true;
      _errorMessage = null;
    });
    try {
      final file = await controller.takePicture();
      final result = await _extractionService.extractTextFromImagePath(
        file.path,
      );
      if (!mounted) return;
      setState(() {
        _lastCapturePath = file.path;
        _result = result;
      });
    } catch (error) {
      if (mounted) setState(() => _errorMessage = error.toString());
    } finally {
      if (mounted) setState(() => _extracting = false);
    }
  }

  Future<void> _toggleRealtime() async {
    if (_realtimeEnabled) {
      await _extractionService.stopRealtimeTextDetection();
      if (mounted) setState(() => _realtimeEnabled = false);
      return;
    }

    setState(() {
      _errorMessage = null;
      _realtimeEnabled = true;
    });
    try {
      await _extractionService.startRealtimeTextDetection(
        onText: (result) {
          if (!mounted) return;
          setState(() => _result = result);
        },
        onError: (error) {
          if (!mounted) return;
          setState(() => _errorMessage = error.toString());
        },
      );
    } catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = error.toString();
          _realtimeEnabled = false;
        });
      }
    }
  }

  void _createNoteFromOcr() {
    final markdown = _result?.toMarkdown();
    if (markdown == null || markdown.isEmpty) return;
    context.go(AppRoutePaths.addNote, extra: markdown);
  }

  @override
  void dispose() {
    _extractionService.dispose();
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
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Kamera OCR',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              // _LiveBadge(active: _realtimeEnabled),
            ],
          ),
          const SizedBox(height: 24),
          FutureBuilder<void>(
            future: _cameraFuture,
            builder: (context, snapshot) {
              if (_errorMessage != null && _controller == null) {
                return _CameraPlaceholder(message: _errorMessage!);
              }
              final controller = _controller;
              if (snapshot.connectionState == ConnectionState.waiting ||
                  controller == null ||
                  !controller.value.isInitialized) {
                return const _CameraLoading();
              }
              return _CameraPreviewFrame(controller: controller);
            },
          ),
          const SizedBox(height: 24),
          _OcrPanel(
            extracting: _extracting,
            realtimeEnabled: _realtimeEnabled,
            result: _result,
            lastCapturePath: _lastCapturePath,
            errorMessage: _errorMessage,
            onCapture: _captureAndExtract,
            onToggleRealtime: _toggleRealtime,
            onCreateNote: _createNoteFromOcr,
          ),
        ],
      ),
    );
  }
}

class OcrResultView extends StatelessWidget {
  const OcrResultView({super.key});

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
            'OCR offline aktif',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          const Text(
            'Gunakan halaman kamera untuk mengambil gambar. Pipeline akan mencoba YOLO text detection lalu ML Kit OCR secara offline. Realtime OCR memakai ML Kit dari stream kamera.',
            style: TextStyle(color: AppColors.muted, height: 1.45),
          ),
          const SizedBox(height: 28),
          LogLineButton(
            label: 'Buka kamera',
            onPressed: () => context.go(AppRoutePaths.scanner),
          ),
        ],
      ),
    );
  }
}

class _CameraPreviewFrame extends StatelessWidget {
  const _CameraPreviewFrame({required this.controller});

  final CameraController controller;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final height = (size.width * 1.18).clamp(300.0, 460.0);
    final previewSize = controller.value.previewSize;
    final previewWidth = previewSize?.height ?? size.width;
    final previewHeight = previewSize?.width ?? height;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: height,
        width: double.infinity,
        color: const Color(0xFF111827),
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: previewWidth,
            height: previewHeight,
            child: CameraPreview(controller),
          ),
        ),
      ),
    );
  }
}

class _OcrPanel extends StatelessWidget {
  const _OcrPanel({
    required this.extracting,
    required this.realtimeEnabled,
    required this.result,
    required this.lastCapturePath,
    required this.errorMessage,
    required this.onCapture,
    required this.onToggleRealtime,
    required this.onCreateNote,
  });

  final bool extracting;
  final bool realtimeEnabled;
  final CameraTextExtractionResult? result;
  final String? lastCapturePath;
  final String? errorMessage;
  final VoidCallback onCapture;
  final VoidCallback onToggleRealtime;
  final VoidCallback onCreateNote;

  @override
  Widget build(BuildContext context) {
    final currentResult = result;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (errorMessage != null && lastCapturePath != null) ...[
            const SizedBox(height: 14),
            Text(errorMessage!, style: const TextStyle(color: AppColors.coral)),
          ],
          if (currentResult != null) ...[
            _PipelineStatus(result: currentResult),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxHeight: 180),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: SingleChildScrollView(
                child: Text(
                  currentResult.hasText
                      ? currentResult.text
                      : 'Belum ada teks terbaca dari gambar ini.',
                ),
              ),
            ),
          ] else if (lastCapturePath != null) ...[
            const SizedBox(height: 18),
            Text('Foto tersimpan sementara:\n$lastCapturePath'),
          ],
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              // SizedBox(
              //   width: double.infinity,
              //   child: LogLineButton(
              //     label: realtimeEnabled ? 'Stop realtime' : 'Realtime OCR',
              //     variant: realtimeEnabled
              //         ? LogLineButtonVariant.danger
              //         : LogLineButtonVariant.primary,
              //     icon: realtimeEnabled
              //         ? Icons.stop_circle_outlined
              //         : Icons.center_focus_strong_outlined,
              //     onPressed: extracting ? null : onToggleRealtime,
              //   ),
              // ),
              SizedBox(
                width: double.infinity,
                child: LogLineButton(
                  label: extracting ? 'Memproses...' : 'Ambil & OCR',
                  variant: LogLineButtonVariant.success,
                  icon: Icons.camera_alt_outlined,
                  onPressed: extracting || realtimeEnabled ? null : onCapture,
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: LogLineButton(
                  label: 'Jadikan Note',
                  variant: LogLineButtonVariant.secondary,
                  onPressed: currentResult?.hasText == true
                      ? onCreateNote
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PipelineStatus extends StatelessWidget {
  const _PipelineStatus({required this.result});

  final CameraTextExtractionResult result;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _StatusPill(
          label: result.isRealtime
              ? 'Realtime'
              : result.usedYolo
              ? 'YOLO aktif'
              : 'YOLO fallback',
          color: result.isRealtime
              ? AppColors.teal
              : result.usedYolo
              ? AppColors.primary
              : AppColors.coral,
        ),
        _StatusPill(label: 'ML Kit offline', color: AppColors.teal),
        _StatusPill(
          label: '${result.detectedRegions.length} region',
          color: AppColors.ink,
        ),
        _StatusPill(
          label: '${result.ocrBlocks.length} blok teks',
          color: AppColors.ink,
        ),
        SizedBox(
          width: double.infinity,
          child: Text(
            result.statusMessage,
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(90)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: active ? const Color(0xFF123B36) : const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        active ? 'Realtime' : 'Offline',
        style: const TextStyle(
          color: Color(0xFF5EEAD4),
          fontWeight: FontWeight.w800,
        ),
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
