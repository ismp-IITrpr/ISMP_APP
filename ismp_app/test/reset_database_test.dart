import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart' hide FirebaseService;
import 'package:ismp_app/services/firebase_service.dart';
import 'package:ismp_app/firebase_options.dart';

void main() {
  test('Reset database', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Resetting Firebase data...');
    await FirebaseService.instance.resetTestingData();
    print('Reset complete.');
  });
}
