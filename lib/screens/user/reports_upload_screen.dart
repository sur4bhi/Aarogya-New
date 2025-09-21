import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/reports_provider.dart';
import '../../core/services/camera_service.dart';
import '../../core/services/document_picker.dart';

class ReportsUploadScreen extends StatelessWidget {
  const ReportsUploadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.uploadReport ?? 'Upload Medical Report'),
      ),
      body: const _UploadBody(),
    );
  }
}

class _UploadBody extends StatefulWidget {
  const _UploadBody();

  @override
  State<_UploadBody> createState() => _UploadBodyState();
}

class _UploadBodyState extends State<_UploadBody> {
  bool _busy = false;

  Future<void> _handleUpload(List<String> paths, String reportType) async {
    if (paths.isEmpty) return;
    setState(() => _busy = true);
    final reports = context.read<ReportsProvider>();
    try {
      final id = await reports.uploadReport(paths, reportType);
      if (!mounted) return;
      await reports.processWithOCR(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Report processed successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final provider = context.watch<ReportsProvider>();

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _UploadCard(
                      icon: Icons.photo_camera_outlined,
                      title: l10n?.capturePhoto ?? 'Capture with Camera',
                      subtitle: 'Multi-page support',
                      onTap: () async {
                        final images = await CameraService.captureMultiplePages(context: context);
                        await _handleUpload(images, 'other');
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _UploadCard(
                      icon: Icons.photo_library_outlined,
                      title: l10n?.selectFromGallery ?? 'Select from Gallery',
                      subtitle: 'Single/Multiple images',
                      onTap: () async {
                        final images = await DocumentPicker.pickFromGalleryMulti();
                        await _handleUpload(images, 'other');
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _UploadCard(
                icon: Icons.picture_as_pdf_outlined,
                title: l10n?.choosePDF ?? 'Choose PDF File',
                subtitle: 'PDF will be converted to images',
                onTap: () async {
                  final paths = await DocumentPicker.pickMedicalDocuments();
                  await _handleUpload(paths, 'other');
                },
              ),
              const SizedBox(height: 24),
              Text('Recent Reports', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              SizedBox(
                height: 120,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: provider.recentReports.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final r = provider.recentReports[index];
                    return GestureDetector(
                      onTap: () {
                        // Future: open review screen
                      },
                      child: Container(
                        width: 220,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Theme.of(context).colorScheme.surface,
                          border: Border.all(color: Theme.of(context).dividerColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleSmall),
                            const SizedBox(height: 6),
                            Text(r.reportType, style: Theme.of(context).textTheme.bodySmall),
                            const Spacer(),
                            Text('${r.reportDate.toLocal()}'.split(' ').first, style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              _TipsCard(title: l10n?.scanningTips ?? 'Tips for better scanning'),
              const SizedBox(height: 80),
            ],
          ),
        ),
        if (_busy || provider.isProcessing) _ProgressOverlay(progress: provider.ocrProgress),
      ],
    );
  }
}

class _UploadCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  const _UploadCard({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).colorScheme.surface,
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 28),
            const SizedBox(height: 10),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
            ]
          ],
        ),
      ),
    );
  }
}

class _TipsCard extends StatelessWidget {
  final String title;
  const _TipsCard({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('Tips for better scanning', style: TextStyle(fontWeight: FontWeight.w600)),
          SizedBox(height: 8),
          Text('• Ensure good lighting and avoid shadows.'),
          Text('• Align the document within the frame.'),
          Text('• Keep the camera steady for a clear image.'),
        ],
      ),
    );
  }
}

class _ProgressOverlay extends StatelessWidget {
  final double progress;
  const _ProgressOverlay({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 12),
              Text('Processing report... ${(progress * 100).clamp(0, 100).toStringAsFixed(0)}%'),
            ],
          ),
        ),
      ),
    );
  }
}
