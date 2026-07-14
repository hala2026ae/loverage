import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Loverage Profile Validation Rules Test', () {
    test('DOB under 18 years check validation', () {
      final dobUnderage = DateTime.now().subtract(const Duration(days: 365 * 17));
      final dobOverage = DateTime.now().subtract(const Duration(days: 365 * 19));
      
      final ageUnderage = DateTime.now().difference(dobUnderage).inDays ~/ 365;
      final ageOverage = DateTime.now().difference(dobOverage).inDays ~/ 365;

      expect(ageUnderage >= 18, isFalse);
      expect(ageOverage >= 18, isTrue);
    });

    test('Name formatting validations', () {
      final validName = 'Sarah Jane';
      final invalidNameWithNumbers = 'Sarah123';
      final invalidNameWithLink = 'sarah.com';
      
      final nameRegex = RegExp(r"^[a-zA-Z\s'-]{2,40}$");

      expect(nameRegex.hasMatch(validName), isTrue);
      expect(nameRegex.hasMatch(invalidNameWithNumbers), isFalse);
      expect(nameRegex.hasMatch(invalidNameWithLink), isFalse);
    });

    test('Bio links and contact details validations', () {
      final validBio = 'Family-oriented developer seeking compatibility and marriage.';
      final bioWithPhone = 'Call me at +201012345678 to chat.';
      final bioWithLink = 'Check my profile website at http://mysite.com';

      final phoneRegex = RegExp(r'\b\d{8,15}\b');
      final linkRegex = RegExp(r'(https?:\/\/)?(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)');

      // Valid bio should not contain phone numbers or links
      expect(phoneRegex.hasMatch(validBio), isFalse);
      expect(linkRegex.hasMatch(validBio), isFalse);

      // Invalid bios should be flagged
      expect(phoneRegex.hasMatch(bioWithPhone), isTrue);
      expect(linkRegex.hasMatch(bioWithLink), isTrue);
    });
  });
}
