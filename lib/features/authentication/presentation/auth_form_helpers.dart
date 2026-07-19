String normalizeEmail(String value) => value.trim().toLowerCase();

String? validateEmailAddress(String? value) {
  final email = normalizeEmail(value ?? '');
  if (email.isEmpty) return 'Enter your email address';
  if (email.contains(RegExp(r'\s'))) return 'Email cannot contain spaces';

  final parts = email.split('@');
  if (parts.length != 2) return 'Enter a valid email address';

  final local = parts[0];
  final domain = parts[1];
  if (local.length < 2 || local.startsWith('.') || local.endsWith('.')) {
    return 'Enter a valid email address';
  }
  if (domain.isEmpty ||
      domain.startsWith('.') ||
      domain.endsWith('.') ||
      !domain.contains('.')) {
    return 'Enter a valid email address';
  }

  final domainLabels = domain.split('.');
  if (domainLabels.any((label) => label.isEmpty)) {
    return 'Enter a valid email address';
  }
  if (domainLabels.last.length < 2) return 'Enter a valid email address';

  final emailPattern = RegExp(
    r"^[a-z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?(?:\.[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?)+$",
  );
  if (!emailPattern.hasMatch(email)) return 'Enter a valid email address';

  if ((domain == 'gmail.com' || domain == 'googlemail.com') &&
      local.replaceAll('.', '').length < 6) {
    return 'Use your full Gmail address';
  }

  return null;
}

String authErrorMessage(Object error) {
  final text = error.toString();
  if (text.contains('email_address_invalid')) {
    return 'This email address was rejected. Use a real inbox, for example your full Gmail address.';
  }
  if (text.contains('User already registered')) {
    return 'An account already exists for this email. Please sign in instead.';
  }
  return text
      .replaceAll('AuthApiException(message: ', '')
      .replaceAll('Exception: ', '')
      .replaceAll(RegExp(r', statusCode: \d+.*\)$'), '')
      .trim();
}
