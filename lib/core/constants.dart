import 'package:flutter/material.dart';

// App Constants
class AppConstants {
  static const String appName = 'Aarogya Sahayak';
  static const String appVersion = '1.0.0';
  
  // API Endpoints
  static const String baseUrl = 'https://api.aarogyasahayak.com';
  static const String firebaseUrl = 'https://aarogya-sahayak-default-rtdb.firebaseio.com';
  
  // Storage Keys
  static const String userTokenKey = 'user_token';
  static const String userDataKey = 'user_data';
  static const String languageKey = 'selected_language';
  static const String themeKey = 'theme_mode';
  
  // Validation Constants
  static const int minPasswordLength = 6;
  static const int maxNameLength = 50;
  static const int maxMessageLength = 500;
  
  // Health Constants
  static const double normalBPSystolic = 120.0;
  static const double normalBPDiastolic = 80.0;
  static const double normalHeartRate = 72.0;
  static const double normalTemperature = 98.6;
  static const double normalOxygenSaturation = 98.0;
  
  // Time Constants
  static const int reminderSnoozeMinutes = 15;
  static const int syncIntervalMinutes = 30;
  static const int sessionTimeoutMinutes = 60;
}

// App Colors
class AppColors {
  // Brand & Accents (Lavender gradient)
  static const Color primary = Color(0xFF7C4DFF); // accent_start
  static const Color primaryAlt = Color(0xFFA58CFF); // accent_end
  static const Color secondary = Color(0xFF7C4DFF);
  static const Color secondaryLight = Color(0xFFA58CFF);
  static const Color secondaryDark = Color(0xFF5B2EFF);

  // Status
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFFF0000); // emergency
  static const Color info = Color(0xFF2196F3);

  // Surfaces
  static const Color background = Color(0xFFF7F5FF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF000000);
  static const Color onBackground = Color(0xFF000000);

  // Text
  static const Color textPrimary = Color(0xFF000000);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);

  // Lines
  static const Color divider = Color(0xFFE0E0E0);
  static const Color border = Color(0xFFE0E0E0);

  // Health Status Colors
  static const Color healthGood = Color(0xFF4CAF50);
  static const Color healthWarning = Color(0xFFFFC107);
  static const Color healthCritical = Color(0xFFFF0000);
}

class AppGradients {
  static const LinearGradient primary = LinearGradient(
    colors: [AppColors.primary, AppColors.primaryAlt],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}

// App Strings
class AppStrings {
  // Common
  static const String loading = 'Loading...';
  static const String error = 'Error';
  static const String success = 'Success';
  static const String cancel = 'Cancel';
  static const String ok = 'OK';
  static const String save = 'Save';
  static const String delete = 'Delete';
  static const String edit = 'Edit';
  static const String add = 'Add';
  static const String update = 'Update';
  static const String retry = 'Retry';
  static const String noData = 'No data available';
  static const String offline = 'You are offline';
  static const String online = 'Connected';
  
  // Authentication
  static const String login = 'Login';
  static const String register = 'Register';
  static const String logout = 'Logout';
  static const String forgotPassword = 'Forgot Password?';
  static const String resetPassword = 'Reset Password';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String confirmPassword = 'Confirm Password';
  static const String name = 'Name';
  static const String phoneNumber = 'Phone Number';
  
  // Health
  static const String vitals = 'Vitals';
  static const String bloodPressure = 'Blood Pressure';
  static const String heartRate = 'Heart Rate';
  static const String temperature = 'Temperature';
  static const String oxygenSaturation = 'Oxygen Saturation';
  static const String weight = 'Weight';
  static const String height = 'Height';
  static const String bmi = 'BMI';
  static const String glucose = 'Blood Glucose';
  
  // Navigation
  static const String dashboard = 'Dashboard';
  static const String profile = 'Profile';
  static const String settings = 'Settings';
  static const String chat = 'Chat';
  static const String reminders = 'Reminders';
  static const String reports = 'Reports';
  static const String trends = 'Trends';
  static const String healthFeed = 'Health Feed';
  
  // ASHA
  static const String ashaWorker = 'ASHA Worker';
  static const String connectAsha = 'Connect with ASHA';
  static const String patients = 'Patients';
  static const String alerts = 'Alerts';
}

// App Dimensions
class AppDimensions {
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;
  
  static const double marginSmall = 8.0;
  static const double marginMedium = 16.0;
  static const double marginLarge = 24.0;
  static const double marginXLarge = 32.0;
  
  // Corner radius spec
  static const double borderRadius = 12.0; // small
  static const double borderRadiusLarge = 16.0; // medium
  static const double borderRadiusXLarge = 24.0;
  
  // Elevation spec
  static const double elevationNone = 0.0;
  static const double elevationSmall = 2.0;
  static const double elevationMedium = 4.0;
  static const double elevationLarge = 8.0;
  
  static const double iconSizeSmall = 16.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 32.0;
  static const double iconSizeXLarge = 48.0;
  
  static const double buttonHeight = 48.0;
  static const double inputHeight = 56.0;
  static const double appBarHeight = 56.0;
}

// Text Styles
class AppTextStyles {
  static const TextStyle headline1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle headline2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle headline3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle bodyText1 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle bodyText2 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );
  
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textHint,
  );
  
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.surface,
  );
}
