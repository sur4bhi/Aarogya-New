import 'dart:async';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../../models/vitals_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/vitals_provider.dart';
import '../../l10n/app_localizations.dart';

class HeartRateMeasureScreen extends StatefulWidget {
  const HeartRateMeasureScreen({super.key});

  @override
  State<HeartRateMeasureScreen> createState() => _HeartRateMeasureScreenState();
}

class _HeartRateMeasureScreenState extends State<HeartRateMeasureScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  bool _initializing = true;
  bool _measuring = false;
  int _seconds = 0;
  int? _bpm;
  Timer? _timer;
  List<double> _intensity = [];
  List<int> _timestamps = [];
  String _qualityLabel = '—';
  Color _qualityColor = Colors.grey;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      // Ensure camera permission is granted
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        setState(() { _initializing = false; });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Camera permission denied')), 
          );
        }
        return;
      }

      final cams = await availableCameras();
      CameraDescription? back;
      for (final c in cams) {
        if (c.lensDirection == CameraLensDirection.back) { back = c; break; }
      }
      back ??= cams.isNotEmpty ? cams.first : null;
      if (back == null) {
        setState(() { _initializing = false; });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No camera available')));
        return;
      }
      final controller = CameraController(
        back,
        ResolutionPreset.low,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      await controller.initialize();
      await controller.setFlashMode(FlashMode.torch);
      setState(() {
        _controller = controller;
        _initializing = false;
      });
    } catch (e) {
      setState(() { _initializing = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Camera init failed: $e')));
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    // Try to turn off torch before disposing
    if (_controller != null && _controller!.value.isInitialized) {
      _controller!.setFlashMode(FlashMode.off).catchError((_) {});
    }
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _stop();
    }
  }

  Future<void> _start() async {
    if (_controller == null || _measuring) return;
    _intensity.clear();
    _timestamps.clear();
    setState(() { _measuring = true; _seconds = 0; _bpm = null; });

    await _controller!.setFlashMode(FlashMode.torch);
    await _controller!.startImageStream(_onImage);

    _timer = Timer.periodic(const Duration(seconds: 1), (t) async {
      setState(() => _seconds++);
      _updateQuality();
      if (_seconds >= 15) { // 15-second sample
        await _stop();
        _analyzeAndShow();
      }
    });
  }

  Future<void> _stop() async {
    _timer?.cancel();
    _timer = null;
    try {
      if (_controller?.value.isStreamingImages == true) {
        await _controller?.stopImageStream();
      }
      // Ensure torch is turned off when stopping
      if (_controller != null && _controller!.value.isInitialized) {
        await _controller!.setFlashMode(FlashMode.off);
      }
    } catch (_) {}
    if (mounted) setState(() { _measuring = false; });
  }

  void _onImage(CameraImage image) {
    try {
      // Use the Y plane as a proxy for intensity
      final bytes = image.planes[0].bytes;
      double sum = 0;
      for (int i = 0; i < bytes.length; i += 50) { // sample every 50th pixel to reduce CPU
        sum += bytes[i];
      }
      final avg = sum / (bytes.length / 50);
      _intensity.add(avg);
      _timestamps.add(DateTime.now().millisecondsSinceEpoch);
      // Keep buffer manageable
      if (_intensity.length > 2000) {
        _intensity = _intensity.sublist(_intensity.length - 2000);
        _timestamps = _timestamps.sublist(_timestamps.length - 2000);
      }
    } catch (_) {}
  }

  void _analyzeAndShow() {
    if (_intensity.length < 50) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Insufficient data. Try again.')));
      return;
    }
    // Bandpass-like filtering: short moving average (LPF), trend removal (HPF via long moving average), then normalize
    final lpf = _movingAverage(_intensity, 5);
    final trend = _movingAverage(_intensity, 30);
    final hp = <double>[];
    for (int i = 0; i < lpf.length; i++) {
      final t = i < trend.length ? trend[i] : trend.last;
      hp.add(lpf[i] - t);
    }
    // Normalize
    final minV = hp.reduce(min);
    final maxV = hp.reduce(max);
    final range = (maxV - minV).abs();
    final norm = hp.map((v) => range > 0 ? (v - minV) / range : 0.5).toList();

    // Adaptive peak detection: local maxima above mean+0.5*std with 300ms refractory
    final mean = norm.reduce((a, b) => a + b) / norm.length;
    double variance = 0;
    for (final v in norm) { variance += (v - mean) * (v - mean); }
    final std = sqrt(variance / norm.length);
    final threshold = mean + 0.5 * std;

    int peaks = 0;
    int lastPeakTs = 0;
    for (int i = 1; i < norm.length - 1; i++) {
      final isPeak = norm[i] > norm[i - 1] && norm[i] >= norm[i + 1] && norm[i] > threshold;
      if (isPeak) {
        final ts = _timestamps[min(i, _timestamps.length - 1)];
        if (ts - lastPeakTs > 300) {
          peaks++;
          lastPeakTs = ts;
        }
      }
    }

    final durationMs = (_timestamps.isNotEmpty)
        ? (_timestamps.last - _timestamps.first).clamp(1, 1 << 31)
        : 1;
    final durationSec = durationMs / 1000.0;
    final bpm = (peaks * (60.0 / durationSec)).round();

    setState(() { _bpm = (bpm >= 30 && bpm <= 220) ? bpm : null; });
    if (_bpm == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not detect stable pulse. Try again.')));
    }
  }

  List<double> _movingAverage(List<double> data, int window) {
    if (data.isEmpty) return data;
    final out = List<double>.filled(data.length, 0);
    double sum = 0;
    for (int i = 0; i < data.length; i++) {
      sum += data[i];
      if (i >= window) sum -= data[i - window];
      final count = min(i + 1, window);
      out[i] = sum / count;
    }
    return out;
  }

  void _updateQuality() {
    // Compute a simple signal quality metric over the last ~2 seconds
    if (_timestamps.length < 30) return;
    final int windowSamples = min(200, _intensity.length);
    final data = _intensity.sublist(_intensity.length - windowSamples);
    final lpf = _movingAverage(data, 5);
    final trend = _movingAverage(data, 30);
    final hp = <double>[];
    for (int i = 0; i < lpf.length; i++) {
      final t = i < trend.length ? trend[i] : trend.last;
      hp.add(lpf[i] - t);
    }
    final minV = hp.reduce(min);
    final maxV = hp.reduce(max);
    final range = (maxV - minV).abs();
    double mean = 0;
    for (final v in hp) { mean += v; }
    mean /= hp.length;
    double variance = 0;
    for (final v in hp) { variance += (v - mean) * (v - mean); }
    final std = sqrt(max(variance / hp.length, 0));

    // Heuristic quality rules
    String label;
    Color color;
    if (range < 2 || std < 0.5) {
      label = 'Poor';
      color = Colors.red;
    } else if (range < 6 || std < 1.2) {
      label = 'OK';
      color = Colors.orange;
    } else {
      label = 'Good';
      color = Colors.green;
    }
    setState(() {
      _qualityLabel = label;
      _qualityColor = color;
    });
  }

  Future<void> _save() async {
    if (_bpm == null) return;
    final auth = context.read<AuthProvider>();
    final userId = auth.userId ?? 'local_user';
    final now = DateTime.now();
    final record = VitalsModel(
      id: 'hr_${now.millisecondsSinceEpoch}',
      userId: userId,
      timestamp: now,
      type: VitalType.heartRate,
      values: {'heartRate': _bpm!.toDouble()},
      notes: 'PPG camera measurement',
      isManualEntry: false,
      isSynced: false,
      createdAt: now,
      updatedAt: now,
    );
    await context.read<VitalsProvider>().addVitalsRecord(record);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Heart rate saved')));
    Navigator.pop(context, _bpm);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.measureHeartRate)),
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
                  Text(
                    AppLocalizations.of(context)!.measureHeartRate + ': ' +
                        'Cover the back camera completely with your fingertip and keep still. The flash will turn on. Measurement takes ~15 seconds.',
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Chip(
                        label: Text('${AppLocalizations.of(context)!.quality}: ' + _qualityLabel),
                        backgroundColor: _qualityColor.withOpacity(0.12),
                        side: BorderSide(color: _qualityColor.withOpacity(0.6)),
                        avatar: CircleAvatar(backgroundColor: _qualityColor, radius: 6),
                      ),
                      const SizedBox(width: 8),
                      if (_qualityLabel == 'Poor')
                        const Expanded(
                          child: Text(
                            'Adjust finger to fully cover lens and flash; apply gentle pressure; keep still.',
                            style: TextStyle(color: Colors.black54),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _measuring ? null : _start,
                          icon: const Icon(Icons.play_arrow),
                          label: Text(_measuring ? 'Measuring...' : 'Start'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _measuring ? _stop : null,
                          icon: const Icon(Icons.stop),
                          label: Text(_measuring ? 'Stop' : 'Stop'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_measuring) LinearProgressIndicator(value: _seconds / 15),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      _bpm == null ? '-- bpm' : '$_bpm bpm',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: (_bpm != null && _qualityLabel != 'Poor') ? _save : null,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Save to Vitals'),
                  ),
                  if (_bpm != null && _qualityLabel == 'Poor')
                    const Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Signal quality is poor. Adjust your finger and try measuring again before saving.',
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
