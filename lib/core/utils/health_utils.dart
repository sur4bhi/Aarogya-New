import 'dart:math';
import '../constants.dart';

class HealthUtils {
  // BMI Calculation and Categories
  static double calculateBMI(double weightKg, double heightCm) {
    final heightM = heightCm / 100;
    return weightKg / (heightM * heightM);
  }
  
  static String getBMICategory(double bmi) {
    if (bmi < 18.5) {
      return 'Underweight';
    } else if (bmi < 25) {
      return 'Normal weight';
    } else if (bmi < 30) {
      return 'Overweight';
    } else {
      return 'Obese';
    }
  }
  
  static String getBMIAdvice(double bmi) {
    if (bmi < 18.5) {
      return 'Consider gaining weight through a balanced diet and exercise.';
    } else if (bmi < 25) {
      return 'Maintain your current weight with a healthy lifestyle.';
    } else if (bmi < 30) {
      return 'Consider losing weight through diet and exercise.';
    } else {
      return 'Consult a healthcare provider for weight management advice.';
    }
  }
  
  // Blood Pressure Analysis
  static String getBloodPressureCategory(double systolic, double diastolic) {
    if (systolic < 90 || diastolic < 60) {
      return 'Low Blood Pressure';
    } else if (systolic < 120 && diastolic < 80) {
      return 'Normal';
    } else if (systolic < 130 && diastolic < 80) {
      return 'Elevated';
    } else if (systolic < 140 || diastolic < 90) {
      return 'High Blood Pressure Stage 1';
    } else if (systolic < 180 || diastolic < 120) {
      return 'High Blood Pressure Stage 2';
    } else {
      return 'Hypertensive Crisis';
    }
  }
  
  static String getBloodPressureAdvice(double systolic, double diastolic) {
    final category = getBloodPressureCategory(systolic, diastolic);
    
    switch (category) {
      case 'Low Blood Pressure':
        return 'Monitor regularly and consult a doctor if symptoms persist.';
      case 'Normal':
        return 'Maintain a healthy lifestyle to keep blood pressure normal.';
      case 'Elevated':
        return 'Adopt heart-healthy habits to prevent high blood pressure.';
      case 'High Blood Pressure Stage 1':
        return 'Lifestyle changes and regular monitoring recommended.';
      case 'High Blood Pressure Stage 2':
        return 'Consult a healthcare provider for treatment options.';
      case 'Hypertensive Crisis':
        return 'Seek immediate medical attention!';
      default:
        return 'Monitor regularly and maintain a healthy lifestyle.';
    }
  }
  
  static bool isBloodPressureCritical(double systolic, double diastolic) {
    return systolic >= 180 || diastolic >= 120;
  }
  
  // Heart Rate Analysis
  static String getHeartRateCategory(double heartRate, int age) {
    final maxHeartRate = 220 - age;
    final restingHeartRate = heartRate;
    
    if (restingHeartRate < 60) {
      return 'Below Normal';
    } else if (restingHeartRate <= 100) {
      return 'Normal';
    } else {
      return 'Above Normal';
    }
  }
  
  static String getHeartRateAdvice(double heartRate, int age) {
    final category = getHeartRateCategory(heartRate, age);
    
    switch (category) {
      case 'Below Normal':
        return 'Consult a doctor if you experience symptoms like dizziness or fatigue.';
      case 'Normal':
        return 'Your heart rate is within the normal range.';
      case 'Above Normal':
        return 'Consider reducing caffeine and stress. Consult a doctor if persistent.';
      default:
        return 'Monitor regularly and maintain a healthy lifestyle.';
    }
  }
  
  static bool isHeartRateCritical(double heartRate) {
    return heartRate < 40 || heartRate > 120;
  }
  
  // Temperature Analysis
  static String getTemperatureCategory(double temperatureF) {
    if (temperatureF < 97.0) {
      return 'Below Normal';
    } else if (temperatureF <= 99.5) {
      return 'Normal';
    } else if (temperatureF <= 100.4) {
      return 'Low Grade Fever';
    } else if (temperatureF <= 102.2) {
      return 'Moderate Fever';
    } else {
      return 'High Fever';
    }
  }
  
  static String getTemperatureAdvice(double temperatureF) {
    final category = getTemperatureCategory(temperatureF);
    
    switch (category) {
      case 'Below Normal':
        return 'Monitor for symptoms. Consult a doctor if you feel unwell.';
      case 'Normal':
        return 'Your body temperature is normal.';
      case 'Low Grade Fever':
        return 'Rest, stay hydrated, and monitor symptoms.';
      case 'Moderate Fever':
        return 'Take fever reducers and consult a healthcare provider.';
      case 'High Fever':
        return 'Seek immediate medical attention!';
      default:
        return 'Monitor regularly and stay hydrated.';
    }
  }
  
  static bool isTemperatureCritical(double temperatureF) {
    return temperatureF < 95.0 || temperatureF > 103.0;
  }
  
  // Convert Celsius to Fahrenheit
  static double celsiusToFahrenheit(double celsius) {
    return (celsius * 9 / 5) + 32;
  }
  
  // Convert Fahrenheit to Celsius
  static double fahrenheitToCelsius(double fahrenheit) {
    return (fahrenheit - 32) * 5 / 9;
  }
  
  // Oxygen Saturation Analysis
  static String getOxygenSaturationCategory(double oxygenSat) {
    if (oxygenSat >= 95) {
      return 'Normal';
    } else if (oxygenSat >= 90) {
      return 'Mild Hypoxemia';
    } else if (oxygenSat >= 85) {
      return 'Moderate Hypoxemia';
    } else {
      return 'Severe Hypoxemia';
    }
  }
  
  static String getOxygenSaturationAdvice(double oxygenSat) {
    final category = getOxygenSaturationCategory(oxygenSat);
    
    switch (category) {
      case 'Normal':
        return 'Your oxygen saturation is normal.';
      case 'Mild Hypoxemia':
        return 'Monitor closely and consult a healthcare provider.';
      case 'Moderate Hypoxemia':
        return 'Seek medical attention promptly.';
      case 'Severe Hypoxemia':
        return 'Seek immediate emergency medical care!';
      default:
        return 'Monitor regularly and consult a healthcare provider.';
    }
  }
  
  static bool isOxygenSaturationCritical(double oxygenSat) {
    return oxygenSat < 90;
  }
  
  // Blood Glucose Analysis
  static String getBloodGlucoseCategory(double glucoseMgDl, String testType) {
    switch (testType.toLowerCase()) {
      case 'fasting':
        if (glucoseMgDl < 70) {
          return 'Low';
        } else if (glucoseMgDl <= 99) {
          return 'Normal';
        } else if (glucoseMgDl <= 125) {
          return 'Prediabetes';
        } else {
          return 'Diabetes';
        }
      case 'random':
        if (glucoseMgDl < 70) {
          return 'Low';
        } else if (glucoseMgDl < 140) {
          return 'Normal';
        } else if (glucoseMgDl <= 199) {
          return 'Prediabetes';
        } else {
          return 'Diabetes';
        }
      case 'postprandial':
        if (glucoseMgDl < 70) {
          return 'Low';
        } else if (glucoseMgDl < 140) {
          return 'Normal';
        } else if (glucoseMgDl <= 199) {
          return 'Prediabetes';
        } else {
          return 'Diabetes';
        }
      default:
        return 'Unknown';
    }
  }
  
  static String getBloodGlucoseAdvice(double glucoseMgDl, String testType) {
    final category = getBloodGlucoseCategory(glucoseMgDl, testType);
    
    switch (category) {
      case 'Low':
        return 'Consume fast-acting carbohydrates and monitor closely.';
      case 'Normal':
        return 'Your blood glucose level is normal.';
      case 'Prediabetes':
        return 'Lifestyle changes can help prevent diabetes. Consult a healthcare provider.';
      case 'Diabetes':
        return 'Consult a healthcare provider for diabetes management.';
      default:
        return 'Monitor regularly and maintain a healthy lifestyle.';
    }
  }
  
  static bool isBloodGlucoseCritical(double glucoseMgDl) {
    return glucoseMgDl < 50 || glucoseMgDl > 400;
  }
  
  // Overall Health Score Calculation
  static double calculateHealthScore({
    required double bmi,
    required double systolic,
    required double diastolic,
    required double heartRate,
    required double temperature,
    required double oxygenSat,
    required int age,
  }) {
    double score = 100.0;
    
    // BMI score (0-25 points)
    final bmiCategory = getBMICategory(bmi);
    switch (bmiCategory) {
      case 'Normal weight':
        score += 0; // No deduction
        break;
      case 'Underweight':
      case 'Overweight':
        score -= 10;
        break;
      case 'Obese':
        score -= 25;
        break;
    }
    
    // Blood pressure score (0-30 points)
    if (isBloodPressureCritical(systolic, diastolic)) {
      score -= 30;
    } else {
      final bpCategory = getBloodPressureCategory(systolic, diastolic);
      switch (bpCategory) {
        case 'Normal':
          score += 0;
          break;
        case 'Elevated':
          score -= 10;
          break;
        case 'High Blood Pressure Stage 1':
          score -= 20;
          break;
        case 'High Blood Pressure Stage 2':
          score -= 25;
          break;
        default:
          score -= 15;
      }
    }
    
    // Heart rate score (0-20 points)
    if (isHeartRateCritical(heartRate)) {
      score -= 20;
    } else {
      final hrCategory = getHeartRateCategory(heartRate, age);
      if (hrCategory != 'Normal') {
        score -= 10;
      }
    }
    
    // Temperature score (0-15 points)
    if (isTemperatureCritical(temperature)) {
      score -= 15;
    } else {
      final tempCategory = getTemperatureCategory(temperature);
      switch (tempCategory) {
        case 'Normal':
          score += 0;
          break;
        case 'Low Grade Fever':
          score -= 5;
          break;
        case 'Moderate Fever':
          score -= 10;
          break;
        default:
          score -= 8;
      }
    }
    
    // Oxygen saturation score (0-10 points)
    if (isOxygenSaturationCritical(oxygenSat)) {
      score -= 10;
    } else if (oxygenSat < 95) {
      score -= 5;
    }
    
    return max(0, min(100, score));
  }
  
  static String getHealthScoreCategory(double score) {
    if (score >= 90) {
      return 'Excellent';
    } else if (score >= 80) {
      return 'Good';
    } else if (score >= 70) {
      return 'Fair';
    } else if (score >= 60) {
      return 'Poor';
    } else {
      return 'Critical';
    }
  }
  
  // Risk Assessment
  static String assessOverallRisk({
    required double bmi,
    required double systolic,
    required double diastolic,
    required double heartRate,
    required double temperature,
    required double oxygenSat,
    required int age,
  }) {
    int riskFactors = 0;
    
    if (isBloodPressureCritical(systolic, diastolic)) riskFactors += 3;
    if (isHeartRateCritical(heartRate)) riskFactors += 2;
    if (isTemperatureCritical(temperature)) riskFactors += 2;
    if (isOxygenSaturationCritical(oxygenSat)) riskFactors += 3;
    if (bmi >= 30 || bmi < 18.5) riskFactors += 1;
    
    if (riskFactors >= 5) {
      return 'High Risk - Seek immediate medical attention';
    } else if (riskFactors >= 3) {
      return 'Moderate Risk - Consult healthcare provider soon';
    } else if (riskFactors >= 1) {
      return 'Low Risk - Monitor and maintain healthy habits';
    } else {
      return 'Low Risk - Continue healthy lifestyle';
    }
  }
  
  // Generate health recommendations
  static List<String> generateHealthRecommendations({
    required double bmi,
    required double systolic,
    required double diastolic,
    required double heartRate,
    required double temperature,
    required double oxygenSat,
    required int age,
  }) {
    final recommendations = <String>[];
    
    // BMI recommendations
    final bmiCategory = getBMICategory(bmi);
    if (bmiCategory != 'Normal weight') {
      recommendations.add(getBMIAdvice(bmi));
    }
    
    // Blood pressure recommendations
    final bpCategory = getBloodPressureCategory(systolic, diastolic);
    if (bpCategory != 'Normal') {
      recommendations.add(getBloodPressureAdvice(systolic, diastolic));
    }
    
    // Heart rate recommendations
    final hrCategory = getHeartRateCategory(heartRate, age);
    if (hrCategory != 'Normal') {
      recommendations.add(getHeartRateAdvice(heartRate, age));
    }
    
    // Temperature recommendations
    final tempCategory = getTemperatureCategory(temperature);
    if (tempCategory != 'Normal') {
      recommendations.add(getTemperatureAdvice(temperature));
    }
    
    // Oxygen saturation recommendations
    final oxygenCategory = getOxygenSaturationCategory(oxygenSat);
    if (oxygenCategory != 'Normal') {
      recommendations.add(getOxygenSaturationAdvice(oxygenSat));
    }
    
    // General recommendations
    recommendations.addAll([
      'Maintain a balanced diet rich in fruits and vegetables',
      'Exercise regularly for at least 30 minutes a day',
      'Stay hydrated by drinking plenty of water',
      'Get adequate sleep (7-9 hours per night)',
      'Manage stress through relaxation techniques',
      'Avoid smoking and limit alcohol consumption',
      'Regular health check-ups are important',
    ]);
    
    return recommendations;
  }
}
