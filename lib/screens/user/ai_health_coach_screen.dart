import 'package:flutter/material.dart';
import '../../core/services/ai_coach_service.dart';

class AiHealthCoachScreen extends StatefulWidget {
  const AiHealthCoachScreen({super.key});

  @override
  State<AiHealthCoachScreen> createState() => _AiHealthCoachScreenState();
}

class _AiHealthCoachScreenState extends State<AiHealthCoachScreen> {
  final TextEditingController _symptomsCtrl = TextEditingController();
  List<String> _selectedSymptoms = [];
  String _duration = 'today';
  List<String> _advice = [];
  bool _busy = false;

  Future<void> _analyze() async {
    setState(() => _busy = true);
    try {
      final manual = _symptomsCtrl.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      final symptoms = {..._selectedSymptoms, ...manual}.toList();
      final advice = await AiCoachService.analyze(
        symptoms: symptoms,
        contextVitals: {'duration': _duration}, // TODO: inject latest vitals
      );
      if (!mounted) return;
      setState(() => _advice = advice);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _symptomsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Health Coach (Offline)')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Select common symptoms'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                'chest pain','headache','dizziness','sweating','shortness of breath','fever','cough','nausea'
              ].map((s) => FilterChip(
                label: Text(s),
                selected: _selectedSymptoms.contains(s),
                onSelected: (v) => setState(() {
                  if (v) { _selectedSymptoms.add(s); } else { _selectedSymptoms.remove(s); }
                }),
              )).toList(),
            ),
            const SizedBox(height: 12),
            const Text('Or describe additional symptoms'),
            const SizedBox(height: 8),
            TextField(
              controller: _symptomsCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'e.g., chest tightness, mild fever',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Duration:'),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _duration,
                  items: const [
                    DropdownMenuItem(value: 'today', child: Text('Today')),
                    DropdownMenuItem(value: 'since 3 days', child: Text('3 days')),
                    DropdownMenuItem(value: 'since 1 week', child: Text('1 week')),
                    DropdownMenuItem(value: 'since 1 month', child: Text('1 month')),
                  ],
                  onChanged: (v) => setState(() => _duration = v ?? 'today'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _busy ? null : _analyze,
              icon: const Icon(Icons.psychology_alt_outlined),
              label: Text(_busy ? 'Analyzing...' : 'Get Advice'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _advice.isEmpty
                  ? const Center(child: Text('No advice yet'))
                  : ListView.separated(
                      itemCount: _advice.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) => ListTile(
                        leading: const Icon(Icons.check_circle_outline, color: Colors.green),
                        title: Text(_advice[i]),
                      ),
                    ),
            )
          ],
        ),
      ),
    );
  }
}
