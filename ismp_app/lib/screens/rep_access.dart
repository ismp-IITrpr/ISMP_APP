/// Rep-detection helper.
///
/// TODO (logic owner / Gorish): replace `isCurrentUserRep` with the real
/// check against the actual list/table of rep roll-numbers once that data
/// source is ready (e.g. a Firestore collection, a hardcoded Set<String>,
/// or an API flag on the user object). Everywhere else in the app just
/// calls this one function — no manual "am I a rep" toggle anywhere in UI.
library rep_access;

// TODO: REMOVE once real logic is wired — lets anyone preview the Rep UI.
const bool _debugForceRep = false;

/// Returns true if [rollNo] belongs to a club rep.
bool isCurrentUserRep(String rollNo) {
  // TODO (logic owner): e.g.
  //   return repRollNumbers.contains(rollNo);
  // or fetch from wherever the rep list / user role actually lives.
  return _debugForceRep;
}