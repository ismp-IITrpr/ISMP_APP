import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/profile_data.dart'; // Make sure this path points to your models file!

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 1. Fetch Mentor by their Roll Number
  Future<MentorProfile?> getMentor(String mentorRollNo) async {
    try {
      DocumentSnapshot doc = await _db.collection('mentors').doc(mentorRollNo).get();
      if (doc.exists) {
        return MentorProfile.fromFirestore(doc);
      }
    } catch (e) {
      print("Error fetching mentor: $e");
    }
    return null; // Returns null if the mentor isn't found
  }

  // 2. Fetch User and automatically attach their Mentor
  Future<UserProfile?> getUserProfile(String userRollNo) async {
    try {
      DocumentSnapshot doc = await _db.collection('users').doc(userRollNo).get();

      if (doc.exists) {
        UserProfile user = UserProfile.fromFirestore(doc);

        // If this user has a mentor assigned, go fetch that mentor's data too!
        if (user.mentorRollNo != null) {
          user.mentor = await getMentor(user.mentorRollNo!);
        }

        return user;
      }
    } catch (e) {
      print("Error fetching user: $e");
    }
    return null;
  }
}