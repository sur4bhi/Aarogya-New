import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/vitals_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/vitals_provider.dart';
import '../../l10n/app_localizations.dart';

class HemoglobinEstimateScreen extends StatefulWidget {
  const HemoglobinEstimateScreen({super.key});

  @override
  State<HemoglobinEstimateScreen> createState() => _HemoglobinEstimateScreenState();
}

class _HemoglobinEstimateScreenState extends State<HemoglobinEstimateScreen> {
  CameraController? _controller;
  bool _initializing = true;
  bool _measuring = false;
  double? _hb;
  final TextEditingController _manualCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cams = await availableCameras();
      if (cams.isEmpty) throw Exception('No camera');
      final back = cams.first;
      final c = CameraController(back, ResolutionPreset.low, enableAudio: false);
      await c.initialize();
      await c.setFlashMode(FlashMode.torch);
      setState(() {
        _controller = c;
        _initializing = false;
      });
    } catch (_) {
      setState(() => _initializing = false);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _manualCtrl.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    if (_controller == null) return;
    setState(() => _measuring = true);
    // Placeholder: In future, run a proper model. For now, show guidance and fallback to manual.
    await Future.delayed(const Duration(seconds: 5));
    setState(() {
      _measuring = false;
      _hb = null; // Keep null to encourage manual entry for now
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not estimate non-invasively on this device. Please enter manually.')),
      );
    }
  }

  Future<void> _save(double value) async {
    final auth = context.read<AuthProvider>();
    final userId = auth.userId ?? 'local_user';
    final now = DateTime.now();
    final record = VitalsModel(
      id: 'hb_${now.millisecondsSinceEpoch}',
      userId: userId,
      timestamp: now,
      type: VitalType.other,
      values: {'hemoglobin': value},
      notes: 'Manual Hb entry',
      isManualEntry: true,
      isSynced: false,
      createdAt: now,
      updatedAt: now,
    );
    await context.read<VitalsProvider>().addVitalsRecord(record);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hemoglobin saved')));
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text('${l10n.appName} - Hb')),
      body: _initializing
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AspectRatio(
                    aspectRatio: 3 / 4,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: (_controller != null && _controller!.value.isInitialized)
                          ? CameraPreview(_controller!)
                          : const ColoredBox(color: Colors.black12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Experimental feature: Non-invasive hemoglobin estimation is not validated on all devices. Try the camera or enter manually below.',
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _measuring ? null : _start,
                          icon: const Icon(Icons.play_arrow),
                          label: Text(_measuring ? 'Measuring...' : 'Try Camera'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _manualCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Enter Hemoglobin (g/dL)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () {
                      final v = double.tryParse(_manualCtrl.text.trim());
                      if (v == null || v <= 0 || v > 25) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid value (0-25)')));
                        return;
                      }
                      _save(v);
                    },
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Save'),
                  ),
                ],
              ),
            ),
    );
  }
}
