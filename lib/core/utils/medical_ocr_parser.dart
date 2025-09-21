import 'dart:math';

import '../../models/medical_ocr_models.dart';

class MedicalOCRParser {
  static RegExp bpPattern = RegExp(r'(\d{2,3})[\/-](\d{2,3})\s*(?:mmHg)?', caseSensitive: false);
  static RegExp sugarPattern = RegExp(r'(?:glucose|sugar)[^\n\r]*?(\d{2,3})\s*mg\s*/\s*d?l', caseSensitive: false);
  static RegExp cholesterolPattern = RegExp(r'cholesterol[^\n\r]*?(\d{2,3})\s*mg\s*/\s*d?l', caseSensitive: false);
  static RegExp hbPattern = RegExp(r'(?:hemoglobin|hb)[^\n\r]*?([0-9]+(?:\.[0-9]+)?)', caseSensitive: false);
  static RegExp weightPattern = RegExp(r'weight[^\n\r]*?([0-9]{2,3})\s*kg', caseSensitive: false);
  static RegExp heightPattern = RegExp(r'height[^\n\r]*?([0-9]{2,3})\s*cm', caseSensitive: false);

  static RegExp medicinePattern = RegExp(
    r'(?:Tab\.|Tablet|Cap\.|Capsule|Syp\.|Syrup|Inj\.|Injection)\s*([A-Za-z][A-Za-z\s\-]+?)\s*(\d+\s*(?:mg|mcg|ml))?\s*(?:-\s*)?((?:OD|BD|TID|QID|HS|STAT|SOS|1-0-1|1-1-1|0-1-0|0-0-1))?\s*(?:x\s*([0-9]+)\s*(?:days|d|weeks|w))?',
    caseSensitive: false,
  );

  static const Map<String, String> medicalTerms = {
    'hypertension': 'High Blood Pressure',
    'diabetes mellitus': 'Diabetes',
    'hyperlipidemia': 'High Cholesterol',
    'anemia': 'Anemia',
  };

  static MedicalOCRResult parseExtractedText(String text) {
    final vitals = extractVitals(text);
    final meds = findMedications(text);
    final conditions = _findConditions(text);
    final advice = _findAdvice(text);
    final nextVisit = _findNextVisit(text);

    // Confidence heuristic: proportion of detected key fields
    int found = 0;
    int total = 6;
    if (vitals['systolicBP'] != null && vitals['diastolicBP'] != null) found++;
    if (vitals['bloodSugar'] != null) found++;
    if (vitals['cholesterol'] != null) found++;
    if (meds.isNotEmpty) found++;
    if (conditions.isNotEmpty) found++;
    if (advice != null && advice!.isNotEmpty) found++;
    final confidence = max(0.3, found / total);

    return MedicalOCRResult(
      rawText: text,
      confidence: double.parse(confidence.toStringAsFixed(2)),
      systolicBP: vitals['systolicBP'],
      diastolicBP: vitals['diastolicBP'],
      bloodSugar: vitals['bloodSugar'],
      cholesterol: vitals['cholesterol'],
      hemoglobin: vitals['hemoglobin'],
      weight: vitals['weight'],
      height: vitals['height'],
      medications: meds,
      conditions: conditions,
      doctorAdvice: advice,
      nextVisitDate: nextVisit,
    );
  }

  static List<MedicationEntry> findMedications(String text) {
    final entries = <MedicationEntry>[];
    for (final m in medicinePattern.allMatches(text)) {
      final name = (m.group(1) ?? '').trim();
      final dosage = (m.group(2) ?? '').trim();
      final frequency = (m.group(3) ?? '').trim();
      final duration = (m.group(4) ?? '').trim();
      if (name.isNotEmpty) {
        entries.add(MedicationEntry(
          name: name,
          dosage: dosage,
          frequency: frequency,
          duration: duration,
        ));
      }
    }
    return entries;
  }

  static Map<String, double?> extractVitals(String text) {
    double? systolic;
    double? diastolic;
    final bp = bpPattern.firstMatch(text);
    if (bp != null) {
      systolic = double.tryParse(bp.group(1) ?? '');
      diastolic = double.tryParse(bp.group(2) ?? '');
    }

    final sugar = sugarPattern.firstMatch(text);
    final cholesterol = cholesterolPattern.firstMatch(text);
    final hb = hbPattern.firstMatch(text);
    final wt = weightPattern.firstMatch(text);
    final ht = heightPattern.firstMatch(text);

    return {
      'systolicBP': systolic,
      'diastolicBP': diastolic,
      'bloodSugar': sugar != null ? double.tryParse(sugar.group(1)!) : null,
      'cholesterol': cholesterol != null ? double.tryParse(cholesterol.group(1)!) : null,
      'hemoglobin': hb != null ? double.tryParse(hb.group(1)!) : null,
      'weight': wt != null ? double.tryParse(wt.group(1)!) : null,
      'height': ht != null ? double.tryParse(ht.group(1)!) : null,
    };
  }

  static List<String> _findConditions(String text) {
    final found = <String>{};
    medicalTerms.forEach((k, v) {
      if (text.toLowerCase().contains(k)) {
        found.add(v);
      }
    });
    return found.toList();
  }

  static String? _findAdvice(String text) {
    final pattern = RegExp(r'(?:advice|recommendation|plan)\s*[:\-]\s*([^\n\r]+)', caseSensitive: false);
    final m = pattern.firstMatch(text);
    return m?.group(1)?.trim();
  }

  static DateTime? _findNextVisit(String text) {
    final pattern = RegExp(r'(?:next visit|follow up)\s*[:\-]?\s*(\d{1,2}[\/-]\d{1,2}[\/-]\d{2,4})', caseSensitive: false);
    final m = pattern.firstMatch(text);
    if (m != null) {
      return DateTime.tryParse(m.group(1)!.replaceAll('/', '-'));
    }
    return null;
  }
}
