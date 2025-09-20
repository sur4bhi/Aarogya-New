import '../constants.dart';

class Validators {
  // Email validation
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    
    return null;
  }
  
  // Password validation
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < AppConstants.minPasswordLength) {
      return 'Password must be at least ${AppConstants.minPasswordLength} characters long';
    }
    
    // Check for at least one uppercase letter
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter';
    }
    
    // Check for at least one lowercase letter
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password must contain at least one lowercase letter';
    }
    
    // Check for at least one digit
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least one number';
    }
    
    return null;
  }
  
  // Confirm password validation
  static String? validateConfirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    
    if (value != password) {
      return 'Passwords do not match';
    }
    
    return null;
  }
  
  // Name validation
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    
    if (value.length > AppConstants.maxNameLength) {
      return 'Name cannot exceed ${AppConstants.maxNameLength} characters';
    }
    
    // Check for valid characters (letters, spaces, hyphens, apostrophes)
    if (!RegExp(r"^[a-zA-Z\s\-']+$").hasMatch(value)) {
      return 'Name can only contain letters, spaces, hyphens, and apostrophes';
    }
    
    return null;
  }
  
  // Phone number validation
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    
    // Remove all non-digit characters
    final digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');
    
    // Check for Indian phone number format (10 digits)
    if (digitsOnly.length != 10) {
      return 'Please enter a valid 10-digit phone number';
    }
    
    // Check if it starts with valid digits (6-9)
    if (!RegExp(r'^[6-9]').hasMatch(digitsOnly)) {
      return 'Phone number must start with 6, 7, 8, or 9';
    }
    
    return null;
  }
  
  // Age validation
  static String? validateAge(String? value) {
    if (value == null || value.isEmpty) {
      return 'Age is required';
    }
    
    final age = int.tryParse(value);
    if (age == null) {
      return 'Please enter a valid age';
    }
    
    if (age < 0 || age > 150) {
      return 'Please enter a valid age between 0 and 150';
    }
    
    return null;
  }
  
  // Weight validation (in kg)
  static String? validateWeight(String? value) {
    if (value == null || value.isEmpty) {
      return 'Weight is required';
    }
    
    final weight = double.tryParse(value);
    if (weight == null) {
      return 'Please enter a valid weight';
    }
    
    if (weight < 1 || weight > 500) {
      return 'Please enter a valid weight between 1 and 500 kg';
    }
    
    return null;
  }
  
  // Height validation (in cm)
  static String? validateHeight(String? value) {
    if (value == null || value.isEmpty) {
      return 'Height is required';
    }
    
    final height = double.tryParse(value);
    if (height == null) {
      return 'Please enter a valid height';
    }
    
    if (height < 30 || height > 300) {
      return 'Please enter a valid height between 30 and 300 cm';
    }
    
    return null;
  }
  
  // Blood pressure validation
  static String? validateBloodPressure(String? systolic, String? diastolic) {
    if (systolic == null || systolic.isEmpty) {
      return 'Systolic pressure is required';
    }
    
    if (diastolic == null || diastolic.isEmpty) {
      return 'Diastolic pressure is required';
    }
    
    final sys = double.tryParse(systolic);
    final dia = double.tryParse(diastolic);
    
    if (sys == null || dia == null) {
      return 'Please enter valid blood pressure values';
    }
    
    if (sys < 70 || sys > 250) {
      return 'Systolic pressure should be between 70 and 250 mmHg';
    }
    
    if (dia < 40 || dia > 150) {
      return 'Diastolic pressure should be between 40 and 150 mmHg';
    }
    
    if (sys <= dia) {
      return 'Systolic pressure should be higher than diastolic pressure';
    }
    
    return null;
  }
  
  // Heart rate validation
  static String? validateHeartRate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Heart rate is required';
    }
    
    final heartRate = double.tryParse(value);
    if (heartRate == null) {
      return 'Please enter a valid heart rate';
    }
    
    if (heartRate < 30 || heartRate > 220) {
      return 'Heart rate should be between 30 and 220 bpm';
    }
    
    return null;
  }
  
  // Temperature validation (in Fahrenheit)
  static String? validateTemperature(String? value) {
    if (value == null || value.isEmpty) {
      return 'Temperature is required';
    }
    
    final temperature = double.tryParse(value);
    if (temperature == null) {
      return 'Please enter a valid temperature';
    }
    
    if (temperature < 90 || temperature > 110) {
      return 'Temperature should be between 90°F and 110°F';
    }
    
    return null;
  }
  
  // Oxygen saturation validation
  static String? validateOxygenSaturation(String? value) {
    if (value == null || value.isEmpty) {
      return 'Oxygen saturation is required';
    }
    
    final oxygenSat = double.tryParse(value);
    if (oxygenSat == null) {
      return 'Please enter a valid oxygen saturation';
    }
    
    if (oxygenSat < 70 || oxygenSat > 100) {
      return 'Oxygen saturation should be between 70% and 100%';
    }
    
    return null;
  }
  
  // Blood glucose validation (in mg/dL)
  static String? validateBloodGlucose(String? value) {
    if (value == null || value.isEmpty) {
      return 'Blood glucose is required';
    }
    
    final glucose = double.tryParse(value);
    if (glucose == null) {
      return 'Please enter a valid blood glucose value';
    }
    
    if (glucose < 20 || glucose > 600) {
      return 'Blood glucose should be between 20 and 600 mg/dL';
    }
    
    return null;
  }
  
  // Message validation
  static String? validateMessage(String? value) {
    if (value == null || value.isEmpty) {
      return 'Message cannot be empty';
    }
    
    if (value.length > AppConstants.maxMessageLength) {
      return 'Message cannot exceed ${AppConstants.maxMessageLength} characters';
    }
    
    return null;
  }
  
  // Generic required field validation
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }
  
  // Numeric validation
  static String? validateNumeric(String? value, String fieldName, {double? min, double? max}) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    
    final number = double.tryParse(value);
    if (number == null) {
      return 'Please enter a valid number for $fieldName';
    }
    
    if (min != null && number < min) {
      return '$fieldName must be at least $min';
    }
    
    if (max != null && number > max) {
      return '$fieldName must not exceed $max';
    }
    
    return null;
  }
}
