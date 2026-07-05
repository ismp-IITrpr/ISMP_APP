import 'package:flutter/material.dart';
import '../widgets/main_layout.dart';
import 'rep_access.dart';
import '../widgets/rep_main_layout.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/Theme images/login_bg.png',
            fit: BoxFit.cover,
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.20,
            left: 50,
            right: 50,
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Institute Student',
                    style: TextStyle(
                      fontSize: 26,
                      color: Color(0xFFE6E6FA),
                      fontWeight: FontWeight.bold

                    ),
                  ),
                  const Text(
                    'Mentorship Program',
                    style: TextStyle(
                      fontSize: 26,
                      color: Color(0xFFE6E6FA),
                      fontWeight: FontWeight.bold
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'IIT Ropar',
                    style: TextStyle(
                      fontSize: 40,
                      color: Color(0xFFE6E6FA),
                      fontWeight: FontWeight.bold
                    ),
                  ),
                ]
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.33,
            left: 0,
            right: 0,
            child: ShaderMask(
              shaderCallback: (Rect bounds) {
                return const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black,
                    Colors.black,
                    Colors.transparent
                  ],
                  stops: [0.0, 0.3, 0.6, 1.0],
                ).createShader(bounds);
              },
              blendMode: BlendMode.dstIn,
              child: Image.asset(
                'assets/Theme images/college.png',
                fit: BoxFit.fitWidth,
              ),
            ),
          ),
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.24,
            left: 30,
            right: 30,
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: () {
                    String mockRollNo = "24CS1001";
                    final isRep = isCurrentUserRep(mockRollNo);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => isRep
                            ? const RepMainLayout()
                            : const MainLayout(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/Theme images/G.png',
                        height: 24,
                        width: 24,
                      ),
                      const SizedBox(width: 20),
                      const Text(
                        'Continue with Google',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Only for IIT Ropar Freshers',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}