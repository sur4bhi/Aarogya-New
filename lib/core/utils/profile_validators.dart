class ProfileValidators {
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    if (value.trim().length < 2) return 'Too short';
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    final v = value.replaceAll(RegExp(r'\s+'), '');
    if (!RegExp(r'^\d{10}$').hasMatch(v)) return 'Enter valid 10-digit phone';
    return null;
  }

  static String? validatePincode(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    if (!RegExp(r'^\d{6}$').hasMatch(value)) return 'Enter valid 6-digit PIN';
    return null;
  }

  static String? validateHeight(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    final num? h = num.tryParse(value);
    if (h == null || h <= 0 || h > 300) return 'Enter valid height (cm)';
    return null;
  }

  static String? validateWeight(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    final num? w = num.tryParse(value);
    if (w == null || w <= 0 || w > 400) return 'Enter valid weight (kg)';
    return null;
  }

  static String? validateAge(DateTime? dob) {
    if (dob == null) return 'Required';
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    if (age < 16 || age > 120) return 'Age must be between 16 and 120';
    return null;
  }

  static bool isValidBloodGroup(String? group) {
    const groups = {'A+','A-','B+','B-','AB+','AB-','O+','O-','Unknown'};
    return groups.contains(group);
  }
}
