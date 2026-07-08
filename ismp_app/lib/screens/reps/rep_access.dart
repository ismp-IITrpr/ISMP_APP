import '../../services/firebase_service.dart';

bool isCurrentUserRep(String rollNo) {
  final email = FirebaseService.instance.currentUserEmail;
  return FirebaseService.instance.isClubRep(email);
}

String? getRepClubName(String email) {
  return FirebaseService.instance.getClubForEmail(email);
}