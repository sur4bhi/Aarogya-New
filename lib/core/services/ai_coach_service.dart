import 'dart:math';

class AiCoachService {
  // Very simple rule-based logic to work offline. Replace with on-device ML later.
  static Future<List<String>> analyze({
    required List<String> symptoms,
    required Map<String, dynamic> contextVitals,
  }) async {
    final lower = symptoms.map((s) => s.toLowerCase()).toList();
    final advice = <String>[];

    if (lower.contains('chest pain') || lower.contains('severe chest pain')) {
      advice.add('Severe chest pain can be an emergency. Prepare SOS and seek immediate help.');
    }
    if (lower.contains('dizziness') && (contextVitals['bloodGlucose'] ?? 0) < 70) {
      advice.add('Dizziness with low blood sugar: take fast-acting carbs (15g), recheck in 15 minutes.');
    }
    if (lower.contains('headache') && (contextVitals['bp_sys'] ?? 0) > 160) {
      advice.add('Headache with high BP: rest, avoid salt, monitor BP. Consider medical attention if persistent.');
    }
    if (advice.isEmpty) {
      advice.add('Monitor symptoms, rest, hydrate, and track your vitals. If symptoms worsen, use SOS.');
    }

    // De-duplicate suggestions
    return advice.toSet().toList();
  }
}
