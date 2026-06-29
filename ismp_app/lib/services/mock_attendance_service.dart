class MockAttendanceService {
  // A singleton for easy access everywhere
  static final MockAttendanceService _instance = MockAttendanceService._internal();
  factory MockAttendanceService() => _instance;
  MockAttendanceService._internal();

  // Maps an event ID to the time the FIRST person scanned in.
  // In a real app, this would be in Firebase under the Event document.
  final Map<String, DateTime> eventStartTimes = {};

  // Maps an event ID to a set of student IDs who are marked present.
  final Map<String, Set<String>> presentStudents = {};

  // Returns true if marked successfully, false if time window closed
  bool markAttendance(String eventId, String studentId) {
    final now = DateTime.now();

    // 1. Is this the very first scan for this event?
    if (!eventStartTimes.containsKey(eventId)) {
      // Start the 2-minute timer for this event
      eventStartTimes[eventId] = now;
      
      // Initialize the set and add the student
      presentStudents[eventId] = {studentId};
      return true; // Successfully marked!
    }

    // 2. Not the first scan. Check if we are within the 2-minute window.
    final startTime = eventStartTimes[eventId]!;
    final diff = now.difference(startTime);

    if (diff.inMinutes <= 2) {
      // Within window! Mark present.
      presentStudents.putIfAbsent(eventId, () => {}).add(studentId);
      return true;
    } else {
      // Window has closed!
      return false;
    }
  }

  // Check if a specific student is present for a specific event
  bool isPresent(String eventId, String studentId) {
    if (!presentStudents.containsKey(eventId)) return false;
    return presentStudents[eventId]!.contains(studentId);
  }
}
