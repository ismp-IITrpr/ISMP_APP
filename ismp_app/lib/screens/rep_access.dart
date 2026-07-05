library rep_access;

const bool _debugForceRep = true;
const String _debugRepClub = 'Robotics';

bool isCurrentUserRep(String rollNo) {
  return _debugForceRep;
}

String? getRepClubName(String email) {
  if (!_debugForceRep) return null;
  return _debugRepClub;
}