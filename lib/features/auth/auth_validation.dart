/// Client-side rules aligned with `mira-vpn-backend` auth validation.
bool isValidEmailFormat(String email) {
  final t = email.trim();
  if (t.isEmpty) return false;
  return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(t);
}

String? validateEmailField(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Email is required';
  }
  if (!isValidEmailFormat(value)) {
    return 'Enter a valid email';
  }
  return null;
}

String? validatePasswordField(String? value) {
  if (value == null || value.isEmpty) {
    return 'Password is required';
  }
  if (value.length < 8) {
    return 'Password must be at least 8 characters';
  }
  return null;
}
