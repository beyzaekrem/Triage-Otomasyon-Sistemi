class Validators {
  Validators._();

  /// Validates Turkish National ID (TC Kimlik No)
  /// Must be 11 digits and pass the checksum algorithm
  static String? validateTcKimlikNo(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'T.C. Kimlik No boş olamaz';
    }

    final trimmed = value.trim();

    // Must be exactly 11 digits
    if (trimmed.length != 11) {
      return 'T.C. Kimlik No 11 haneli olmalıdır';
    }

    // Must contain only digits
    if (!RegExp(r'^\d+$').hasMatch(trimmed)) {
      return 'T.C. Kimlik No sadece rakam içermelidir';
    }

    // Cannot start with 0
    if (trimmed[0] == '0') {
      return 'T.C. Kimlik No 0 ile başlayamaz';
    }

    // Basic checksum validation (simplified)
    final digits = trimmed.split('').map(int.parse).toList();
    
    // Sum of first 10 digits must be divisible by 10
    final sumFirst10 = digits.sublist(0, 10).fold<int>(0, (a, b) => a + b);
    if (sumFirst10 % 10 != digits[10]) {
      return 'Geçersiz T.C. Kimlik No';
    }

    // Additional validation: sum of odd positions (1st, 3rd, 5th, 7th, 9th)
    final sumOdd = digits[0] + digits[2] + digits[4] + digits[6] + digits[8];
    final sumEven = digits[1] + digits[3] + digits[5] + digits[7];
    
    if (((sumOdd * 7) - sumEven) % 10 != digits[9]) {
      return 'Geçersiz T.C. Kimlik No';
    }

    return null;
  }

  /// Validates full name
  static String? validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ad Soyad boş olamaz';
    }

    final trimmed = value.trim();

    if (trimmed.length < 2) {
      return 'Ad Soyad en az 2 karakter olmalıdır';
    }

    if (trimmed.length > 100) {
      return 'Ad Soyad çok uzun';
    }

    // Should contain at least one space (name and surname)
    if (!trimmed.contains(' ')) {
      return 'Lütfen ad ve soyadınızı giriniz';
    }

    // Should only contain letters, spaces, and Turkish characters
    if (!RegExp(r'^[a-zA-ZçğıöşüÇĞIİÖŞÜ\s]+$').hasMatch(trimmed)) {
      return 'Ad Soyad sadece harf içermelidir';
    }

    return null;
  }
}

