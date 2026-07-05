library rep_access;

const bool _debugForceRep = true;

bool isCurrentUserRep(String rollNo) {
  return _debugForceRep;
}

String? getRepClubName(String email) {
  if (email.isEmpty) return 'Robotics';
  final prefix = email.split('@').first.toLowerCase();
  final rollRegex = RegExp(r'^\d{4}[a-zA-Z]{3}\d{4}$');
  if (rollRegex.hasMatch(prefix)) {
    return 'Robotics';
  }
  if (prefix.contains('robotics')) return 'Robotics';
  if (prefix.contains('web')) return 'Web Dev';
  if (prefix.contains('music')) return 'Music';
  if (prefix.contains('dance')) return 'Dance';
  if (prefix.isEmpty) return 'Robotics';
  return prefix[0].toUpperCase() + prefix.substring(1);
}